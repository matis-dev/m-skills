#!/usr/bin/env bash
# m-skills — shared hook plumbing. Sourced, never executed.
#
# Hook scripts receive a JSON payload on stdin and answer on stdout. This file
# carries the three things all of them need: reading a field out of the payload,
# escaping a string back into JSON, and the emit helpers for each decision shape.
#
# Dependency note: the pack's "bash + coreutils only" contract holds for
# tests/run-tests.sh. Hook scripts relax it to jq-or-python3, because parsing a
# shell command out of JSON with sed is how a guard gets bypassed by a quoted
# newline. Every dev machine that runs Claude Code has one of the two.
#
# Engine missing splits by hook class, deliberately:
#   guards     → fail CLOSED (deny). An unverifiable guard that allows is the
#                A10 fail-open pattern code-review-architect flags.
#   advisories → fail OPEN (silent exit 0). A missed hint costs nothing.

M_SKILLS_JSON_ENGINE=""
if command -v jq >/dev/null 2>&1; then
  M_SKILLS_JSON_ENGINE="jq"
elif command -v python3 >/dev/null 2>&1; then
  M_SKILLS_JSON_ENGINE="python3"
fi

# Read the entire stdin payload. Call once; stdin is not rewindable.
hook_read_input() { cat; }

# json_field <payload> <dotted.path> — prints the string value, empty if absent.
json_field() {
  local payload="$1" path="$2"
  case "$M_SKILLS_JSON_ENGINE" in
    jq)
      printf '%s' "$payload" | jq -r --arg p "$path" '
        reduce ($p | split(".")[]) as $k (.; if type == "object" then .[$k] else null end)
        | if . == null then "" elif type == "string" then . else tojson end
      ' 2>/dev/null
      ;;
    python3)
      printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
for k in sys.argv[1].split("."):
    if not isinstance(d, dict):
        d = None
        break
    d = d.get(k)
print(d if isinstance(d, str) else ("" if d is None else json.dumps(d)))
' "$path" 2>/dev/null
      ;;
    *) return 1 ;;
  esac
}

# json_string <text> — the text as a JSON string literal, quotes included.
json_string() {
  case "$M_SKILLS_JSON_ENGINE" in
    jq)      printf '%s' "$1" | jq -Rs . 2>/dev/null ;;
    python3) printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null ;;
    *)       printf '"m-skills guard: cannot serialise reason"' ;;
  esac
}

# ── Emitters. Each exits; a hook makes exactly one decision. ─────────────────

emit_deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(json_string "$1")"
  exit 0
}

emit_ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":%s}}\n' \
    "$(json_string "$1")"
  exit 0
}

# PostToolUse feedback. The runtime feeds `reason` back to Claude and the turn
# continues — this is context injection, not a failure.
emit_block() {
  printf '{"decision":"block","reason":%s}\n' "$(json_string "$1")"
  exit 0
}

# emit_context <hookEventName> <text>
emit_context() {
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":%s}}\n' \
    "$1" "$(json_string "$2")"
  exit 0
}

# ── Shared conditions ────────────────────────────────────────────────────────

# The user's opt-out from the enforcement hooks, project or global. Same flag-file
# idiom as adhd-always-on.sh: presence is the whole signal, contents ignored.
m_skills_guards_disabled() {
  local project="${CLAUDE_PROJECT_DIR:-$PWD}"
  local config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  [ -f "$project/.claude/.m-skills-no-guards" ] && return 0
  [ -f "$config_dir/.m-skills-no-guards" ] && return 0
  return 1
}

# A guard with no JSON engine denies rather than waves the call through.
guard_require_json_engine() {
  [ -n "$M_SKILLS_JSON_ENGINE" ] && return 0
  emit_deny "m-skills guard: neither jq nor python3 is available, so this command could not be checked against the Guidelines §9/§10 guards. Guards fail closed by design. Install jq or python3, or opt out with: touch .claude/.m-skills-no-guards"
}

# An advisory with no JSON engine says nothing.
advisory_require_json_engine() {
  [ -n "$M_SKILLS_JSON_ENGINE" ] || exit 0
}

# File mtime as an epoch second. `date -r FILE` is GNU-only — on BSD/macOS -r takes
# epoch SECONDS, so a path argument errors, the fallback returns 0 for every file,
# and the cache key below silently degenerates to a constant that never invalidates.
m_skills_mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || date -r "$1" +%s 2>/dev/null || echo 0
}

# Cache key for the resolved gate table. The resolution reads PROJECT-PROFILE.md,
# quality-gates.conf, and the manifest, so the key folds in their mtimes: editing
# any of them invalidates the cache. Without this a stale table outlives the edit.
m_skills_gate_cache_key() {
  local root="$1" stamps=""
  local f
  for f in "$root/.claude/PROJECT-PROFILE.md" "$root/.claude/quality-gates.conf" \
           "$root/package.json" "$root/Makefile" "$root/pyproject.toml" \
           "$root/Cargo.toml" "$root/go.mod"; do
    [ -f "$f" ] && stamps="$stamps|$(m_skills_mtime "$f")"
  done
  printf '%s' "$root$stamps" | cksum | cut -d' ' -f1
}

# The session this hook invocation belongs to. Every hook payload carries session_id,
# which is the only identifier that is both stable across one session and distinct
# between two — $CLAUDE_SESSION_ID is not always exported into the hook environment.
#
# This matters more than it looks: the markers below are never cleaned up, so keying
# them on a constant made "once per session" mean "once per machine, forever". Two
# advisories stopped firing after their first use and nothing reported it.
#
# Last resort, when neither is available: the parent process's start time. Constant
# within one Claude Code process, different in the next — still wrong for concurrent
# sessions sharing a parent, but never a global constant.
m_skills_session_id() {
  local from_payload="${1:-}"
  [ -n "$from_payload" ] && { printf '%s' "$from_payload" | tr -c 'A-Za-z0-9._-' '_'; return; }
  [ -n "${CLAUDE_SESSION_ID:-}" ] && { printf '%s' "$CLAUDE_SESSION_ID" | tr -c 'A-Za-z0-9._-' '_'; return; }
  local boot
  boot="$(awk '{print $22}' "/proc/$PPID/stat" 2>/dev/null)" \
    || boot="$(ps -o lstart= -p "$PPID" 2>/dev/null)"
  printf 'pp%s' "$(printf '%s' "${boot:-0}$PPID" | cksum | cut -d' ' -f1)"
}

# A per-session marker directory, so an advisory can fire once rather than every
# time the same file is touched. Pass the payload's session_id; two concurrent
# sessions then never silence each other.
m_skills_state_dir() {
  local base="${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)"
  printf '%s/%s' "$base" "$(m_skills_session_id "${1:-}")"
}
