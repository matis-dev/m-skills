#!/usr/bin/env bash
# m-skills — PreToolUse guard for secret-bearing files.
#
# Enforces security-architect constraint 5: never write a real secret into a
# tracked file, and never read one into the conversation.
#
# READS and WRITES of real secret files are both denied. The env contract the pack
# lives in the example files — .env.example / .sample / .template / .dist — and
# those are never blocked in either direction.
#
# This is a tripwire, not a boundary. It sees the path a tool names: Read on .env,
# `cat .env`, `source .env`, `--env-file=.env`, `open('.env')`, `cat .e*`. A process
# that reaches the file without naming it (`grep -r KEY .`, a script that loads
# dotenv itself) passes. The boundary is sandbox.filesystem.denyRead — see README,
# Enforcement.
#
# Opt out with .claude/.m-skills-no-guards. Fails CLOSED.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# m-skills — shared hook plumbing. Sourced, never executed.
#
# Hook scripts receive a JSON payload on stdin and answer on stdout. This file
# carries the three things all of them need: reading a field out of the payload,
# escaping a string back into JSON, and the emit helpers for each decision shape.
#
# Dependency note: the pack's "bash + coreutils only" contract holds for
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

# ── Secret-bearing paths ─────────────────────────────────────────────────────

# The documented, secret-free contract files. They always pass.
M_SKILLS_EXAMPLE_RE='\.(example|sample|template|dist|defaults?)$|(^|/)\.?env\.(example|sample|template|dist)$'
# The env-file family — what the bootstrap reports.
M_SKILLS_ENV_RE='(^|/)\.env(\.[A-Za-z0-9_-]+)?$|(^|/)\.envrc$'
# Every secret-bearing path — what the guard denies.
M_SKILLS_GUARDED_RE="$M_SKILLS_ENV_RE"'|\.(pem|key|p12|pfx|jks|keystore)$|(^|/)id_(rsa|dsa|ecdsa|ed25519)$|(^|/)(credentials|service-account|serviceAccountKey|gha-creds.*)\.json$|(^|/)\.npmrc$|(^|/)\.pypirc$|(^|/)\.netrc$'

# m_skills_section <file> <n> — one numbered `### n.` section of a skill file, heading
# through to the next heading or rule. The preamble and the Antigravity rule both quote
# guidelines-meta this way; one extractor keeps the two quotations identical.
m_skills_section() {
  awk -v n="$2" '
    $0 ~ "^### " n "\\." { grabbing = 1 }
    grabbing && NR > start && (/^### /  && $0 !~ "^### " n "\\.") { exit }
    grabbing && /^## / { exit }
    grabbing && /^---$/ { exit }
    grabbing { print; start = NR }
  ' "$1"
}

# ── Shared conditions ────────────────────────────────────────────────────────

# The user's opt-out from the enforcement hooks, project or global. Same flag-file
m_skills_guards_disabled() {
  local project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
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

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

TOOL="$(json_field "$INPUT" "tool_name")"

EXAMPLE="$M_SKILLS_EXAMPLE_RE"
GUARDED_RE="$M_SKILLS_GUARDED_RE"

# File tools also get `docker.env`-style names. Shell words do not: there,
# `process.env` would match.
GUARDED_FILE_RE="$GUARDED_RE|(^|/)[^/]+\\.env\$"

# A shell word that is only an extension (`.key`, `.pem`) is a property path — jq's
# `.key`, JS's `obj.key` split at the dot — not a file with a name.
BARE_EXT='^\.(pem|key|p12|pfx|jks|keystore)$'

# is_secret <path> <regex>
is_secret() {
  printf '%s' "$1" | grep -Eq "$EXAMPLE" && return 1
  printf '%s' "$1" | grep -Eq "$2"
}

# glob_hits_secret <pattern> [shell] — whether a glob would match a secret file:
# `.env*`, `.e?v`, `*.pem`. A pattern with no literal character (`*`, `*.*`, `[a-z]*` —
# a bracket expression is a set, not literal text) names nothing. With `shell`, a dotfile only matches a pattern that starts with a dot,
# which is how bash expands it.
glob_hits_secret() {
  local glob="${1##*/}" name lit
  lit="$(printf '%s' "$glob" | sed 's/\[[^]]*\]//g')"
  case "$lit" in *[A-Za-z0-9]*) ;; *) return 1 ;; esac
  for name in .env .env.local .env.production .env.development .envrc \
              _.pem _.key _.p12 id_rsa id_ed25519 .npmrc .pypirc .netrc; do
    if [ "${2:-}" = shell ]; then
      case "$name" in .*) case "$glob" in .*) ;; *) continue ;; esac ;; esac
    fi
    # shellcheck disable=SC2053 # the right side is meant to be a pattern
    [[ $name == $glob ]] && return 0
  done
  return 1
}

# words <text> — one word per line, split on whitespace, quotes, and shell
# punctuation, so `--env-file=.env`, `HEAD:.env`, `open('.env')` and `$(<.env)`
# all surface `.env` as a word of its own.
words() { printf '%s' "$1" | tr -s "[:space:]\"'\`;|&<>(){}=,:@\$" '\n'; }

# names_only <segment> — commands that name a secret path without printing what
# is inside it. Anything else that names one counts as a read.
names_only() {
  local -a w
  read -r -a w <<< "${1//[\"\']/}"
  local i=0 n=0 j src=""
  while [ "$i" -lt "${#w[@]}" ] && [[ ${w[$i]} == [A-Za-z_]*=* ]]; do i=$((i + 1)); done
  [ "$i" -lt "${#w[@]}" ] || return 1
  case "${w[$i]}" in
    ls|test|'['|'[['|stat|file) return 0 ;;
    git)
      [ $((i + 1)) -lt "${#w[@]}" ] || return 1
      case "${w[$((i + 1))]}" in
        check-ignore|ls-files) return 0 ;;
        log)
          # A commit list names the file; a patch prints it.
          for ((j = i + 2; j < ${#w[@]}; j++)); do
            case "${w[$j]}" in -p|--patch|-u|-U*|--unified*|-L*|--word-diff*|--full-diff|-c|--cc|-m) return 1 ;; esac
          done
          return 0
          ;;
      esac
      ;;
    cp)
      # Seeding .env from its template reads nothing secret.
      for ((j = i + 1; j < ${#w[@]}; j++)); do
        case "${w[$j]}" in -*) ;; *) n=$((n + 1)); [ "$n" -eq 1 ] && src="${w[$j]}" ;; esac
      done
      [ "$n" -eq 2 ] && printf '%s' "$src" | grep -Eq "$EXAMPLE" && return 0
      ;;
  esac
  return 1
}

deny_write() {
  emit_deny "Blocked by m-skills (security-architect constraint 5): writing to \`$1\` risks putting a real credential in a tracked file. Placeholders only — secrets belong in the environment, not in the repo. .env.example / .sample / .template stay writable; if this file is genuinely secret-free, rename it to an example variant — or opt out with: touch .claude/.m-skills-no-guards"
}

deny_read() {
  emit_deny "Blocked by m-skills (security-architect constraint 5): \`$1\` holds real credentials, and opening it puts them into this conversation. For variable NAMES, read the example file (.env.example / .sample / .template — always allowed) or grep the code for what it reads (process.env, os.environ, env::var). For a VALUE, or to add a line, hand it to the user. Naming the file without opening it (ls, test -f, git check-ignore) and cp .env.example .env stay allowed. If this path holds no secret, opt out with: touch .claude/.m-skills-no-guards"
}

case "$TOOL" in
  Write|Edit|NotebookEdit)
    # NotebookEdit sends notebook_path, not file_path. Reading only file_path made
    # this arm dead code — a guard the header claims and the case never ran.
    FILE="$(json_field "$INPUT" "tool_input.file_path")"
    [ -z "$FILE" ] && FILE="$(json_field "$INPUT" "tool_input.notebook_path")"
    [ -z "$FILE" ] && exit 0
    is_secret "$FILE" "$GUARDED_FILE_RE" && deny_write "$FILE"
    ;;
  Read)
    FILE="$(json_field "$INPUT" "tool_input.file_path")"
    [ -n "$FILE" ] && is_secret "$FILE" "$GUARDED_FILE_RE" && deny_read "$FILE"
    ;;
  Grep)
    # A search pointed at a secret file, or filtered down to one, reads it. A
    # directory-wide search is left to the runtime's own Read deny rules.
    P="$(json_field "$INPUT" "tool_input.path")"
    G="$(json_field "$INPUT" "tool_input.glob")"
    [ -n "$P" ] && is_secret "$P" "$GUARDED_FILE_RE" && deny_read "$P"
    [ -n "$G" ] && { is_secret "$G" "$GUARDED_FILE_RE" || glob_hits_secret "$G"; } && deny_read "$G"
    ;;
  Bash)
    CMD="$(json_field "$INPUT" "tool_input.command")"
    [ -z "$CMD" ] && exit 0
    # One pass over the whole command; almost every command ends here.
    HITS="$(words "$CMD" | grep -Ev "$EXAMPLE" | grep -Ev "$BARE_EXT" | grep -E "$GUARDED_RE")"
    while IFS= read -r w; do
      [ -n "$w" ] && glob_hits_secret "$w" shell && HITS="$HITS"$'\n'"$w"
    done <<< "$(words "$CMD" | grep -E '[][*?]')"
    HITS="$(printf '%s' "$HITS" | grep -v '^$')"
    [ -z "$HITS" ] && exit 0
    # Then per segment, so `ls .env && cat .env` is judged by its cat.
    SEGMENTS="$(printf '%s\n' "$CMD" | awk '{ gsub(/[;|&(){}`]/, "\n"); print }')"
    while IFS= read -r seg; do
      while IFS= read -r h; do
        [[ $seg == *"$h"* ]] || continue
        words "$seg" | grep -Fxq -- "$h" || continue
        names_only "$seg" || deny_read "$h"
      done <<< "$HITS"
    done <<< "$SEGMENTS"
    ;;
esac

exit 0
