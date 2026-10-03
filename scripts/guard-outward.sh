#!/usr/bin/env bash
# m-skills — PreToolUse handover gate for outward-facing actions.
#
# deployment-architect constraint 2 ("never fire an irreversible action") only
# binds while that skill is loaded — but `npm publish` can be typed in any
# session, including one that never touched the deployment pipeline. This makes
# the constraint hold everywhere.
#
# DENY, not ask. Deploying, publishing, migrating shared state, and publishing to
# a collaboration surface are the user's to run, exactly like a git write
# (guidelines-meta §9). The skill's job is to assemble a copy-paste runbook and
# hand it over; the reason text below says so, because a deny that only says "no"
# turns a design decision into an obstacle.
#
# Two families:
#   infra  — deploy, publish, migrate, mutate live infrastructure
#   gh     — writes to a shared GitHub surface (PRs, issues, releases, secrets)
#
# READ-ONLY gh stays open on purpose: `gh pr view|list|diff|checks`,
# `gh issue view|list`, `gh run view|list`. code-review-architect reviews a PR by
# fetching it with the platform CLI, and denying that would break the review path.
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

CMD="$(json_field "$INPUT" "tool_input.command")"
[ -z "$CMD" ] && exit 0

B='(^|[^[:alnum:]_./-])'

match() { printf '%s' "$CMD" | grep -Eq "$1"; }

WHAT=""; KIND=""

# ── gh writes — publish to a surface other people see ────────────────────────
# Subcommands are enumerated as WRITES only. Anything not listed (view, list,
# diff, checks, status) falls through and stays allowed.
if   match "${B}gh[[:space:]]+pr[[:space:]]+(create|merge|close|reopen|comment|edit|review|ready)([^[:alnum:]_-]|\$)";  then WHAT="open, merge, or comment on a pull request"; KIND=gh
elif match "${B}gh[[:space:]]+issue[[:space:]]+(create|close|reopen|comment|edit|transfer|delete|pin)([^[:alnum:]_-]|\$)"; then WHAT="create or change a GitHub issue"; KIND=gh
elif match "${B}gh[[:space:]]+release[[:space:]]+(create|edit|delete|upload)([^[:alnum:]_-]|\$)";                      then WHAT="create or change a GitHub release"; KIND=gh
elif match "${B}gh[[:space:]]+secret[[:space:]]+(delete|remove|se[t])([^[:alnum:]_-]|\$)";                               then WHAT="write a repository or environment secret"; KIND=gh
elif match "${B}gh[[:space:]]+(repo|gist)[[:space:]]+(create|delete|edit|rename|archive)([^[:alnum:]_-]|\$)";          then WHAT="create, delete, or reconfigure a repository"; KIND=gh
elif match "${B}gh[[:space:]]+workflow[[:space:]]+(run|enable|disable)([^[:alnum:]_-]|\$)";                            then WHAT="trigger or toggle a CI workflow"; KIND=gh
elif match "${B}gh[[:space:]]+api[[:space:]]+.*(-X|--method)[[:space:]]*(POST|PUT|PATCH|DELETE)";                      then WHAT="make a writing GitHub API call"; KIND=gh

# ── infrastructure — deploy, publish, migrate ────────────────────────────────
elif match "${B}(vercel|netlify|fly|railway|render|heroku)[[:space:]]+(deploy|up)([^[:alnum:]_-]|\$)";       then WHAT="deploy to a hosting platform"; KIND=infra
elif match "${B}(npm|pnpm|yarn|bun)[[:space:]]+publish([^[:alnum:]_-]|\$)";                                  then WHAT="publish a package to a registry"; KIND=infra
elif match "${B}kubectl[[:space:]]+(apply|delete|rollout|scale)([^[:alnum:]_-]|\$)";                         then WHAT="mutate a Kubernetes cluster"; KIND=infra
elif match "${B}(terraform|tofu)[[:space:]]+(apply|destroy)([^[:alnum:]_-]|\$)";                             then WHAT="apply infrastructure changes"; KIND=infra
elif match "${B}(prisma|drizzle-kit|alembic|knex|sequelize)[[:space:]]+.*(migrate|deploy|push|upgrade)";     then WHAT="run a migration against a database"; KIND=infra
elif match "${B}docker[[:space:]]+push([^[:alnum:]_-]|\$)";                                                  then WHAT="push a container image to a registry"; KIND=infra
elif match "${B}aws[[:space:]]+(s3[[:space:]]+(sync|rm|cp)|cloudfront[[:space:]]+create-invalidation|ecs[[:space:]]+update-service|lambda[[:space:]]+update-function-code)"; then WHAT="mutate live AWS infrastructure"; KIND=infra
elif match "${B}(firebase|wrangler|serverless|sls)[[:space:]]+(deploy|publish)([^[:alnum:]_-]|\$)";          then WHAT="deploy to a serverless platform"; KIND=infra
elif match "${B}(supabase|doctl|flyctl)[[:space:]]+.*(deploy|migration[[:space:]]+up)";                      then WHAT="deploy or migrate a hosted environment"; KIND=infra
fi

[ -z "$WHAT" ] && exit 0

OPTOUT_LINE="Opt out for this project with: touch .claude/.m-skills-no-guards"

if [ "$KIND" = "gh" ]; then
  emit_deny "Blocked by m-skills (Guidelines §9): this would ${WHAT} — a write to a surface other people see, and it notifies them. Like every git write, it is the user's to run. Print the exact command for them to paste, and say what it will publish. Read-only \`gh\` stays open: pr view/list/diff/checks, issue view/list, run view/list. ${OPTOUT_LINE}"
fi

emit_deny "Blocked by m-skills (deployment-architect constraint 2): this would ${WHAT} — an outward-facing action that is hard to undo, and it is the user's to fire, not yours. Hand over a runbook instead: the config and secrets they must set in the target, then one numbered, copy-paste step per command, each with what it does and how they know it worked — plus the rollback plan and its one-way doors (migrations, sent mail, charges, client-side caches) named before they start. Reversible work stays open: production builds, artifact inspection, config diffing, dry runs, health checks, reading logs. ${OPTOUT_LINE}"
