#!/usr/bin/env bash
# m-skills — PreToolUse guard for Bash. Enforces guidelines-meta §9 and §10.
#
# These two rules are restated in eleven skill files and, before this hook, enforced
# nowhere: settings.template.json is a template the user must copy, and its prefix
# matching cannot see inside `&&` chains or `bash -c "…"` anyway. Prose only binds
# when the model has that file in context; this binds always.
#
# Three families, one process spawn:
#   §9  git mutation      → deny   (add/commit/push/branch/reset/--no-verify/…)
#   §10 golden updates    → deny   (static patterns + the PROJECT'S resolved command)
#   catastrophic fs ops   → deny   (rm -rf /, mkfs, dd of=/dev/…)
#
# The third family converts no existing instruction — it is additive scope, kept
# because it is four lines here and the failure mode is unrecoverable.
#
# Opt out with .claude/.m-skills-no-guards (project) or in $CLAUDE_CONFIG_DIR (global).
# Fails CLOSED: an unverifiable guard denies rather than waving the command through.

set -uo pipefail
m_skills_gate_table() (
  for v in LINT TYPECHECK TEST BUILD E2E VISUAL A11Y AUDIT VISUAL_REPORT UPDATE_CMD; do
    [[ "$(declare -p "$v" 2>/dev/null)" =~ ^declare\ -[a-zA-Z]*x ]] || unset "$v"
  done
# Quality Check — portable one-shot validation pipeline.
#
# Mirrors the Implementing Architect gate order:
#   lint → typecheck → test → build → e2e → visual → a11y → audit
#
# Resolution order for each gate:
#   1. .claude/PROJECT-PROFILE.md   (the authority — guidelines-meta §5 rule 1)
#   2. .claude/quality-gates.conf   (explicit override for anything the profile leaves blank)
#   3. auto-detection from the project's manifest (package.json / Makefile / pyproject.toml / Cargo.toml / go.mod)
#   4. skipped as n-a — a gate that does not exist is never invented
#
# §5 rule 1 says the profile "is the authority; use it verbatim". This script is what
# hook would hand Claude auto-detected commands under the profile's name.
#
# Snapshot policy: NEVER runs a golden/snapshot update command. Diffs are surfaced for manual review.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

CONF=".claude/quality-gates.conf"
PROFILE=".claude/PROJECT-PROFILE.md"
GATE_NAMES=(LINT TYPECHECK TEST BUILD E2E VISUAL A11Y AUDIT)
GATE_LABELS=("Lint" "Type-check" "Tests + Coverage" "Build" "E2E" "Visual regression" "Accessibility" "Dependency audit")

for k in "${GATE_NAMES[@]}"; do printf -v "$k" '%s' "${!k:-}"; done
VISUAL_REPORT="${VISUAL_REPORT:-}"
UPDATE_CMD="${UPDATE_CMD:-}"

# is the most explicit signal available, so it outranks the profile too. Everything
# not marked here is fair game for the profile to override.
ENV_PINNED=""
for k in "${GATE_NAMES[@]}" VISUAL_REPORT UPDATE_CMD; do
  [ -n "${!k}" ] && ENV_PINNED="$ENV_PINNED $k"
done
env_pinned() { case " $ENV_PINNED " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ── 1. Explicit config ────────────────────────────────────────────────────────
# The conf is DATA and is parsed, never sourced. Two reasons, both real:
#   · `--list` is called by the SessionStart bootstrap and by the PreToolUse guard,
#     so sourcing meant cloning a repo ran whatever its author put in this file.
#   · sourcing blindly assigns, which silently clobbered a value passed on the
#     invocation. Skipping pinned keys here keeps precedence as anyone would read it:
#     env > profile > conf > detection.
# Accepts NAME="v" / NAME='v' / NAME=v, leading indentation, # comments, and a trailing
# comment after a quoted value — every shape the template at the end of this file uses.
read_conf() {
  local line gate val
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in *=*) ;; *) continue ;; esac
    gate="${line%%=*}"; val="${line#*=}"
    gate="${gate%"${gate##*[![:space:]]}"}"
    case "$gate" in
      LINT|TYPECHECK|TEST|BUILD|E2E|VISUAL|A11Y|AUDIT|UPDATE_CMD|VISUAL_REPORT) ;;
      *) continue ;;
    esac
    env_pinned "$gate" && continue
    val="${val#"${val%%[![:space:]]*}"}"
    case "$val" in
      \"*)  val="${val#\"}";  val="${val%%\"*}" ;;
      \'*)  val="${val#\'}";  val="${val%%\'*}" ;;
      *)    val="${val%%[[:space:]]#*}" ;;
    esac
    val="${val%"${val##*[![:space:]]}"}"
    printf -v "$gate" '%s' "$val"
  done < "$1"
}

if [ -f "$CONF" ]; then
  read_conf "$CONF"
  SOURCE="$CONF"
else
  SOURCE="auto-detected"
fi

# ── 1b. The Project Profile outranks it (guidelines-meta §5 rule 1) ───────────
# Parses the §Commands table the profile template defines:
#   | `<lint>` | <the project's lint command> | notes |
# A cell that is empty, `n-a`, or still a `<placeholder>` is treated as unset and
# falls through to the conf / detection below — so a half-filled profile is safe,
# which is the normal state (§5 "progressive, not a questionnaire").
# Nothing is executed: awk emits NAME<TAB>VALUE and the loop assigns by an explicit case.
if [ -f "$PROFILE" ]; then
  PROFILE_SET=0
  while IFS="$(printf '\t')" read -r pkey pval; do
    [ -z "$pkey" ] && continue
    env_pinned "$pkey" && continue
    case "$pkey" in
      LINT|TYPECHECK|TEST|BUILD|E2E|VISUAL|A11Y|AUDIT|UPDATE_CMD|VISUAL_REPORT)
        printf -v "$pkey" '%s' "$pval"; PROFILE_SET=1 ;;
    esac
  done <<< "$(awk '
  function clean(c) {
    gsub(/^[ \t]+|[ \t]+$/, "", c); gsub(/`/, "", c)
    gsub(/^[ \t]+|[ \t]+$/, "", c); return c
  }
  # unusable: empty, n-a, or a leftover <placeholder>
  function unusable(v) { return (v == "" || v == "n-a" || v == "n/a" || v ~ /^</ || v ~ /…/) }
  /^[ \t]*\|/ {
    n = split($0, cell, "|")
    if (n < 3) next
    role = tolower(clean(cell[2])); cmd = clean(cell[3])
    gsub(/^</, "", role); gsub(/>$/, "", role)
    if (unusable(cmd)) next
    if (role == "lint")            print "LINT\t"      cmd
    else if (role ~ /^type-?check$/) print "TYPECHECK\t" cmd
    else if (role == "test")       print "TEST\t"      cmd
    else if (role == "build")      print "BUILD\t"     cmd
    else if (role == "e2e")        print "E2E\t"       cmd
    else if (role == "visual")     print "VISUAL\t"    cmd
    else if (role == "a11y")       print "A11Y\t"      cmd
    else if (role == "audit")      print "AUDIT\t"     cmd
    next
  }
  # **Golden / snapshot update command (USER-ONLY …):** `<the update command>`
  /[Gg]olden.*update command|snapshot-update command/ {
    if (match($0, /`[^`]+`[^`]*$/)) {
      v = substr($0, RSTART + 1, RLENGTH - 2); sub(/`.*$/, "", v)
      if (!unusable(v)) print "UPDATE_CMD\t" v
    }
    next
  }
  /[Rr]eport location for failed visual diffs/ {
    if (match($0, /`[^`]+`/)) {
      v = substr($0, RSTART + 1, RLENGTH - 2)
      if (!unusable(v)) print "VISUAL_REPORT\t" v
    }
    next
  }
' "$PROFILE")"
  if [ "$PROFILE_SET" -eq 1 ]; then
    if [ -f "$CONF" ]; then SOURCE="$PROFILE, then $CONF, then auto-detection"
    else SOURCE="$PROFILE, then auto-detection"; fi
  fi
fi

# ── 2. Auto-detection ─────────────────────────────────────────────────────────
detect_pm() {
  [ -f pnpm-lock.yaml ] && { echo pnpm; return; }
  [ -f yarn.lock ]      && { echo yarn; return; }
  [ -f bun.lockb ] || [ -f bun.lock ] && { echo bun; return; }
  echo npm
}

# read every script name once — SessionStart bootstrap calls --list, so keep spawns to one
PKG_SCRIPTS=""
if [ -f package.json ] && command -v node >/dev/null 2>&1; then
  PKG_SCRIPTS="$(node -e "const s=require('./package.json').scripts||{};console.log(Object.keys(s).join('\n'))" 2>/dev/null)"
fi

has_script() {
  printf '%s\n' "$PKG_SCRIPTS" | grep -qxF -- "$1"
}

# first matching script name wins
pick_script() {
  for name in "$@"; do
    if has_script "$name"; then echo "$name"; return 0; fi
  done
  return 1
}

has_make_target() {
  [ -f Makefile ] && grep -qE "^$1[[:space:]]*:" Makefile
}

if [ -f package.json ] && command -v node >/dev/null 2>&1; then
  PM="$(detect_pm)"
  RUN="$PM run"
  [ "$PM" = "npm" ] && RUN="npm run"
  set_gate() { # set_gate VAR script-name...
    local var="$1"; shift
    [ -n "${!var}" ] && return 0
    local s; s="$(pick_script "$@")" && printf -v "$var" '%s' "$RUN $s"
    return 0
  }
  set_gate LINT      lint
  set_gate TYPECHECK type-check typecheck tsc types
  set_gate TEST      test:ci test:coverage test
  set_gate BUILD     build
  set_gate E2E       e2e test:e2e
  set_gate VISUAL    e2e:visual test:visual
  set_gate A11Y      e2e:a11y test:a11y a11y
  if [ -z "$AUDIT" ]; then
    case "$PM" in
      npm)  AUDIT="npm audit --omit=dev" ;;
      pnpm) AUDIT="pnpm audit --prod" ;;
      yarn) AUDIT="yarn npm audit --environment production" ;;
      bun)  AUDIT="" ;;   # no audit subcommand — n-a
    esac
  fi
  [ -z "$UPDATE_CMD" ] && { u="$(pick_script e2e:update test:update update-snapshots)" && UPDATE_CMD="$RUN $u"; }
fi

# Each ecosystem below runs as its own pass, not as an `elif`. A repo is allowed to
# be more than one thing — a Python service with a package.json for frontend tooling,
# a Go binary with a Makefile — and first-manifest-wins left every other ecosystem's
# gates resolving to `n-a`. That is worse than a missing gate: §5 rule 3 then has the
# model STATE that the gate does not exist while `make test` sits in the repo.
# Every assignment is already conditional on the role still being empty, so the
# manifest order below is the precedence order.
if [ -f Makefile ]; then
  for i in "${!GATE_NAMES[@]}"; do
    k="${GATE_NAMES[$i]}"; t="$(echo "$k" | tr '[:upper:]' '[:lower:]')"
    [ -z "${!k}" ] && has_make_target "$t" && printf -v "$k" '%s' "make $t"
  done
fi

# Each gate is spelled in full, so the command reads exactly as it will run. uv runs
# against uv.lock as it is (--frozen) and never re-resolves it in the middle of a gate.
if [ -f pyproject.toml ]; then
  if command -v uv >/dev/null 2>&1; then
    [ -z "$LINT" ]      && LINT="uv run --frozen ruff check ."
    [ -z "$TYPECHECK" ] && TYPECHECK="uv run --frozen mypy ."
    [ -z "$TEST" ]      && TEST="uv run --frozen pytest"
  elif [ -f poetry.lock ]; then
    [ -z "$LINT" ]      && LINT="poetry run ruff check ."
    [ -z "$TYPECHECK" ] && TYPECHECK="poetry run mypy ."
    [ -z "$TEST" ]      && TEST="poetry run pytest"
  else
    [ -z "$LINT" ]      && LINT="ruff check ."
    [ -z "$TYPECHECK" ] && TYPECHECK="mypy ."
    [ -z "$TEST" ]      && TEST="pytest"
  fi
fi

if [ -f Cargo.toml ]; then
  [ -z "$LINT" ]  && LINT="cargo clippy -- -D warnings"
  [ -z "$TEST" ]  && TEST="cargo test"
  [ -z "$BUILD" ] && BUILD="cargo build --release"
  [ -z "$AUDIT" ] && AUDIT="cargo audit"
fi

if [ -f go.mod ]; then
  [ -z "$LINT" ]      && LINT="go vet ./..."
  [ -z "$TYPECHECK" ] && TYPECHECK="go build ./..."
  [ -z "$TEST" ]      && TEST="go test ./..."
fi

# ── --list: show resolution and exit ──────────────────────────────────────────
if [ "${1:-}" = "--list" ]; then
  echo "Gate resolution ($SOURCE):"
  for i in "${!GATE_NAMES[@]}"; do
    k="${GATE_NAMES[$i]}"
    printf '  %-18s %s\n' "${GATE_LABELS[$i]}" "${!k:-n-a}"
  done
  printf '  %-18s %s\n' "Update (user-only)" "${UPDATE_CMD:-n-a}"
  exit 0
fi
)

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

OPTOUT_LINE="Opt out for this project with: touch .claude/.m-skills-no-guards"

# ── §9 — git mutation ────────────────────────────────────────────────────────
# Tolerate interposed flags so `git -C /path commit` and `git --git-dir=x push`
# are caught, and scan the whole string so `&&`, `;`, and `bash -c "…"` are too.
# This is the class the prefix-matching deny list in settings.template.json misses.
GIT_PREFIX='(^|[^[:alnum:]_./-])git([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--[^[:space:]]+=[^[:space:]]+|--no-pager|--paginate|--bare|--literal-pathspecs))*[[:space:]]+'

# Always mutating. No read-only form exists.
GIT_HARD='(add|stage|commit|push|checkout|switch|reset|rebase|cherry-pick|revert|clean|am|mv|rm|merge|pull|fetch|gc|prune|filter-branch|update-ref|symbolic-ref|restore|bisect|apply|notes|replace)'

# Mutating only in some forms. Listing branches, tags, remotes, worktrees, and
# stashes is read-only and genuinely useful — denying it would send people to the
# opt-out, which defeats the guard entirely. Each pattern below matches only the
# writing form: a destructive flag, or a bare name where a name means "create".
GIT_SOFT='(branch[[:space:]]+(-[dDmMcC]([[:space:]]|$)|--(delete|move|copy|set-upstream-to|unset-upstream|edit-description)|[^-[:space:]])|tag[[:space:]]+(-[adsfD]([[:space:]]|$)|--(delete|force|annotate|sign)|[^-[:space:]])|remote[[:space:]]+(add|remove|rm|rename|set-url|set-head|prune)|worktree[[:space:]]+(add|remove|move|prune|lock)|submodule[[:space:]]+(add|update|init|deinit|sync|set-url)|stash([[:space:]]+(push|pop|apply|drop|clear|save|create|store)([[:space:]]|$)|[[:space:]]*$))'

GIT_DENIED=""
if printf '%s' "$CMD" | grep -Eq "${GIT_PREFIX}${GIT_HARD}([^[:alnum:]_-]|\$)"; then
  GIT_DENIED="$(printf '%s' "$CMD" | grep -Eo "${GIT_PREFIX}${GIT_HARD}([^[:alnum:]_-]|\$)" | grep -Eo "${GIT_HARD}" | head -1)"
elif printf '%s' "$CMD" | grep -Eq "${GIT_PREFIX}${GIT_SOFT}"; then
  GIT_DENIED="$(printf '%s' "$CMD" | grep -Eo "${GIT_PREFIX}${GIT_SOFT}" | grep -oE '(branch|tag|remote|worktree|submodule|stash)' | head -1)"
fi

if [ -n "$GIT_DENIED" ]; then
  emit_deny "Blocked by m-skills (Guidelines §9): \`git ${GIT_DENIED}\` writes to the repository, and every git write is the user's to run — no exceptions, including when the user says \"ship it\". Print the exact command for them to paste; leave the working tree as it is. Read-only git stays open: status, diff, log, show, blame, rev-parse, merge-base, describe, and the listing forms of branch/tag/remote/stash/worktree. ${OPTOUT_LINE}"
fi

# --no-verify / --no-gpg-sign are git-only flags; their presence anywhere is the rule break.
if printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])--(no-verify|no-gpg-sign)([[:space:]]|=|$)'; then
  emit_deny "Blocked by m-skills (Guidelines §9): skipping hooks with --no-verify / --no-gpg-sign is forbidden. Fix the root cause the hook is reporting instead. ${OPTOUT_LINE}"
fi

# ── §10 — golden / snapshot updates ──────────────────────────────────────────
# Static patterns first.
if printf '%s' "$CMD" | grep -Eq -- '(--update-snapshots?|--updateSnapshot|--update-golden|--accept-snapshots?|UPDATE_SNAPSHOTS=|SNAPSHOT_UPDATE=|UPDATE_GOLDEN=|insta[[:space:]]+accept|--snapshot-update)'; then
  emit_deny "Blocked by m-skills (Guidelines §10): golden and visual-snapshot updates are user-only. Surface the diff and its report path, then stop — \"Diffs detected — review the report at <path>; if intended, run <update-command> manually.\" Auto-updating erases the exact signal the test exists to produce. ${OPTOUT_LINE}"
fi

# A bare -u only means "update snapshots" next to a test runner that defines it, and
# only when the flag belongs to THAT runner. Two corrections are load-bearing here:
#
#   · mocha and jasmine are not on the list. Mocha's -u is --ui (bdd/tdd/qunit), so
#     `mocha -u tdd` is an ordinary run; jasmine has no snapshot concept at all.
#   · the runner and the flag must share a command segment. Matching across the whole
#     string denied `jest --listTests | sort -u`, where the -u is sort's.
#
# Over-blocking is the worst failure a guard has: the reason text points at
# .m-skills-no-guards, and reaching for it disarms all three guards permanently.
SNAP_RUNNER='(^|[^[:alnum:]_./-])(jest|vitest|ava|playwright)([^[:alnum:]_-]|$)'
SNAP_U='(^|[[:space:]])-[a-zA-Z]*u[a-zA-Z]*([[:space:]]|$)'
printf '%s\n' "$CMD" | tr '|;&' '\n\n\n' | while IFS= read -r seg; do
  printf '%s' "$seg" | grep -Eq "$SNAP_RUNNER" || continue
  printf '%s' "$seg" | grep -Eq "$SNAP_U"      || continue
  printf 'deny\n'
  break
done | grep -q deny && \
  emit_deny "Blocked by m-skills (Guidelines §10): \`-u\` updates snapshots on this test runner, and that is user-only. Report the diffs and let the user run the update themselves. ${OPTOUT_LINE}"

# Then the project's OWN resolved update command. Prose can never do this — §10's
# whole point is that the command is project-specific. Cached per session: the
# resolution spawns node, and this hook runs on every Bash call.
resolve_update_cmd() {
  local state cache root
  local session; session="$(json_field "$INPUT" "session_id")"
  root="$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" rev-parse --show-toplevel 2>/dev/null || printf '%s' "${CLAUDE_PROJECT_DIR:-$(pwd)}")"
  state="$(m_skills_state_dir "$session")"
  cache="$state/updatecmd-$(m_skills_gate_cache_key "$root")"
  if [ -f "$cache" ]; then
    cat "$cache"
    return 0
  fi
  mkdir -p "$state" 2>/dev/null || return 1
  local resolved
  resolved="$(cd "$root" 2>/dev/null && m_skills_gate_table --list 2>/dev/null \
              | sed -n 's/^[[:space:]]*Update (user-only)[[:space:]]*//p' | head -1)"
  [ "$resolved" = "n-a" ] && resolved=""
  printf '%s' "$resolved" > "$cache" 2>/dev/null
  printf '%s' "$resolved"
}

UPDATE_CMD="$(resolve_update_cmd)"
if [ -n "$UPDATE_CMD" ] && printf '%s' "$CMD" | grep -qF -- "$UPDATE_CMD"; then
  emit_deny "Blocked by m-skills (Guidelines §10): \`${UPDATE_CMD}\` is this project's resolved snapshot-update command, and it is user-only. Surface the diffs and the report path, then stop. ${OPTOUT_LINE}"
fi

# ── Catastrophic filesystem operations (additive scope) ──────────────────────
# Home counts only as itself, its top-level globs, or its parent: `~/.cache/x` names one
# directory and passes, while `~/`, `~/*`, `~/.*`, and `~/..` are denied.
if printf '%s' "$CMD" | grep -Eq '(^|[^[:alnum:]_./-])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR])[a-zA-Z]*[[:space:]]+((/|\.\.|\*)([[:space:]]|/|$)|(~|\$HOME)(/(\*|\.\*|\.\.?)?)?([[:space:];&|]|$))'; then
  emit_deny "Blocked by m-skills: recursive force-delete of a root, home, parent, or bare glob path is unrecoverable. Name the specific directory instead. ${OPTOUT_LINE}"
fi

if printf '%s' "$CMD" | grep -Eq '(^|[^[:alnum:]_./-])mkfs([.[:space:]]|$)|(^|[^[:alnum:]_./-])dd[[:space:]]+.*of=/dev/'; then
  emit_deny "Blocked by m-skills: this writes directly to a block device. ${OPTOUT_LINE}"
fi

exit 0
