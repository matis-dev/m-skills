#!/usr/bin/env bash
# m-skills — SessionStart bootstrap.
#
# Fires once per session. Two jobs:
#   1. Every session: report real env files that git tracks, once tracked, or does
#      not ignore — from names alone, before the model has read anything.
#   2. Only when .claude/PROJECT-PROFILE.md is missing or drifted: detect what it can
#      mechanically and hand Claude a verified starting point.
#
# Silent when: nothing to report · this isn't a project directory · the user opted out
# (.m-skills-no-bootstrap silences job 2 only; job 1 honours .m-skills-no-guards).
# Never writes anything unless M_SKILLS_AUTOPROFILE=1 is set.
#
# Output contract: plain-text stdout becomes Claude's context on SessionStart. The first
# character must not be '{' or the runtime parses it as a JSON directive.

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
# Accepts KEY="v" / KEY='v' / KEY=v, leading indentation, # comments, and a trailing
# comment after a quoted value — every shape the template at the end of this file uses.
read_conf() {
  local line key val
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in *=*) ;; *) continue ;; esac
    key="${line%%=*}"; val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    case "$key" in
      LINT|TYPECHECK|TEST|BUILD|E2E|VISUAL|A11Y|AUDIT|UPDATE_CMD|VISUAL_REPORT) ;;
      *) continue ;;
    esac
    env_pinned "$key" && continue
    val="${val#"${val%%[![:space:]]*}"}"
    case "$val" in
      \"*)  val="${val#\"}";  val="${val%%\"*}" ;;
      \'*)  val="${val#\'}";  val="${val%%\'*}" ;;
      *)    val="${val%%[[:space:]]#*}" ;;
    esac
    val="${val%"${val##*[![:space:]]}"}"
    printf -v "$key" '%s' "$val"
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
#   | `<lint>` | pnpm run lint | notes |
# A cell that is empty, `n-a`, or still a `<placeholder>` is treated as unset and
# falls through to the conf / detection below — so a half-filled profile is safe,
# which is the normal state (§5 "progressive, not a questionnaire").
# Nothing is executed: awk emits KEY<TAB>VALUE and the loop assigns by an explicit case.
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
  # **Golden / snapshot update command (USER-ONLY …):** `pnpm run e2e:update`
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

if [ -f pyproject.toml ]; then
  RUNNER=""
  command -v uv >/dev/null 2>&1 && RUNNER="uv run"
  [ -z "$RUNNER" ] && [ -f poetry.lock ] && RUNNER="poetry run"
  [ -z "$LINT" ]      && LINT="$RUNNER ruff check ."
  [ -z "$TYPECHECK" ] && TYPECHECK="$RUNNER mypy ."
  [ -z "$TEST" ]      && TEST="$RUNNER pytest"
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

RESOLVED=0
for k in "${GATE_NAMES[@]}"; do [ -n "${!k}" ] && RESOLVED=$((RESOLVED + 1)); done
if [ "$RESOLVED" -eq 0 ]; then
  echo "❌ No quality gates resolved. Create $CONF (see the template at the end of this script)."
  exit 1
fi

# ── 3. Run ────────────────────────────────────────────────────────────────────
echo "⚖️  Quality Check — $RESOLVED gate(s), $SOURCE"
echo

declare -a RESULTS=()
STEP=0
for i in "${!GATE_NAMES[@]}"; do
  k="${GATE_NAMES[$i]}"; cmd="${!k}"
  [ -z "$cmd" ] && continue
  STEP=$((STEP + 1))
  echo "▶ [$STEP/$RESOLVED] ${GATE_LABELS[$i]} — $cmd"
  # A child shell, so a gate cannot reassign this loop's variables; pipefail kept
  # so `cmd | tee log` still fails when cmd does.
  bash -o pipefail -c "$cmd"
  RESULTS+=("$k:$?")
  echo
done

# ── 4. Summary ────────────────────────────────────────────────────────────────
echo "═══════════════════════════════"
echo "  Quality Check Results"
echo "═══════════════════════════════"
FAILED=0
VISUAL_FAILED=0
for r in "${RESULTS[@]}"; do
  k="${r%%:*}"; code="${r##*:}"
  for i in "${!GATE_NAMES[@]}"; do [ "${GATE_NAMES[$i]}" = "$k" ] && label="${GATE_LABELS[$i]}"; done
  if [ "$code" -eq 0 ]; then
    echo "  ✅ $label"
  else
    echo "  ❌ $label"
    FAILED=$((FAILED + 1))
    { [ "$k" = "VISUAL" ] || [ "$k" = "E2E" ]; } && VISUAL_FAILED=1
  fi
done
echo "═══════════════════════════════"

if [ "$FAILED" -eq 0 ]; then
  echo "✅ Quality Check Passed."
  exit 0
fi

echo "❌ Quality Check Failed ($FAILED gate(s)). Fix issues above."
if [ "$VISUAL_FAILED" -eq 1 ]; then
  echo
  echo "ℹ️  Visual diffs may be intentional — review ${VISUAL_REPORT:-the test report}."
  echo "   If intended, run '${UPDATE_CMD:-the snapshot update command}' manually (NEVER automated)."
fi
exit 1

# ──────────────────────────────────────────────────────────────────────────────
# .claude/quality-gates.conf template — copy the block below, drop the leading '# '
#
# LINT="pnpm run lint"
# TYPECHECK="pnpm run type-check"
# TEST="pnpm run test:ci"
# BUILD="pnpm run build"
# E2E="pnpm run e2e"
# VISUAL=""                       # empty = n-a, gate skipped
# A11Y="pnpm run e2e:a11y"
# AUDIT="pnpm audit --omit=dev"
# VISUAL_REPORT="playwright-report/"
# UPDATE_CMD="pnpm run e2e:update"  # never executed by this script
)

PROJECT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$PROJECT" 2>/dev/null || exit 0

PROFILE=".claude/PROJECT-PROFILE.md"
OPTOUT=".claude/.m-skills-no-bootstrap"

# Fingerprint of the inputs a profile is derived from. Used by BOTH paths: the
# drift check compares it against the marker in an existing profile, and the
# draft writer stamps it so that check has something to compare against later.
# $1 is the package.json script list (may be empty).
m_skills_fingerprint() {
  printf '%s' "$(printf '%s|' "$1" \
    "$(ls package.json Makefile pyproject.toml Cargo.toml go.mod 2>/dev/null | sort | tr '\n' ' ')" \
    "$(ls CHANGELOG.md README.md docs/*.md Documentation/*.md 2>/dev/null | sort | tr '\n' ' ')" \
    "$(ls Dockerfile vercel.json netlify.toml fly.toml Procfile serverless.yml 2>/dev/null | sort | tr '\n' ' ')")" \
  | cksum | cut -d' ' -f1
}

# package.json script names, one per line; empty without a manifest or node.
m_skills_pkg_scripts() {
  [ -f package.json ] && command -v node >/dev/null 2>&1 || return 0
  node -e "const s=require('./package.json').scripts||{};console.log(Object.keys(s).join('\n'))" 2>/dev/null
}

# `--fingerprint` prints the marker for the repo as it is now and exits. A profile written
# by hand (/m-skills:onboard) stamps it, so the drift check below has something to compare.
if [ "${1:-}" = "--fingerprint" ]; then
  m_skills_fingerprint "$(m_skills_pkg_scripts)"
  exit 0
fi

# ── Secret files and git — every session, profile or not ──────────────────────
# Names only: git's index, log, and ignore rules. No secret file is opened, so nothing
# in one reaches the model. Runs ahead of every profile branch: a .env committed next
# month matters more than any profile row, and a project that already has a profile
# would otherwise never hear about it.
m_skills_secret_hygiene() {
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
  m_skills_guards_disabled && return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local spec=(':(glob)**/.env' ':(glob)**/.env.*' ':(glob)**/.envrc')
  real_env() { grep -E "$M_SKILLS_ENV_RE" | grep -Ev "$M_SKILLS_EXAMPLE_RE" | sort -u; }
  bullets()  { printf '%s\n' "$1" | grep -v '^$' | sed 's/^/  - /'; }

  local tracked history unignored ignored on_disk
  tracked="$(git ls-files -- "${spec[@]}" 2>/dev/null | real_env)"
  history="$(git log --all --format= --name-only --diff-filter=A -- "${spec[@]}" 2>/dev/null | real_env)"
  [ -n "$tracked" ] && history="$(printf '%s\n' "$history" | grep -vxF -- "$tracked")"
  unignored="$(git ls-files --others --exclude-standard -- "${spec[@]}" 2>/dev/null | real_env)"
  # --directory stops git descending into ignored trees such as node_modules
  ignored="$(git ls-files --others --ignored --exclude-standard --directory -- "${spec[@]}" 2>/dev/null | real_env)"
  on_disk="$(printf '%s\n' "$tracked" "$unignored" "$ignored" | grep -v '^$' | sort -u)"

  local sandboxed=0 hint=1 f
  for f in .claude/settings.json .claude/settings.local.json "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"; do
    [ -f "$f" ] && [ "$(json_field "$(cat "$f")" sandbox.enabled)" = "true" ] && sandboxed=1
  done
  { [ -z "$on_disk" ] || [ "$sandboxed" -eq 1 ] || [ -f .claude/.m-skills-no-sandbox-hint ]; } && hint=0
  [ -z "$tracked$history$unignored" ] && [ "$hint" -eq 0 ] && return 0

  local ignore_lines='    .env
    .env.*
    .envrc
    !.env.example
    !.env.sample
    !.env.template'

  if [ -n "$tracked$history" ]; then
    local tracked_part="" history_part="" untrack=""
    [ -n "$tracked" ] && tracked_part="
Tracked right now:
$(bullets "$tracked")"
    [ -n "$history" ] && history_part="
Removed from the index, but still in history — every existing clone has them:
$(bullets "$history")"
    [ -n "$tracked" ] && untrack="
- Stop tracking. The user runs it, because git writes are theirs: \`git rm --cached $(printf '%s\n' "$tracked" | tr '\n' ' ' | sed 's/ $//')\`, then commit, with these lines in .gitignore:
$ignore_lines"
    printf '%s\n' "m-skills 🚨 SECRET FILES IN GIT — raise this with the user BEFORE anything else, including their current request.

Found by name in git's index and log. No file was opened, so whether they hold real values is unknown — treat them as exposed.
$tracked_part$history_part

Tell the user, plainly, first:
- Rotate every credential these files ever held, at its provider. Untracking, deleting, or ignoring a file does not undo the exposure. Rotation is theirs; never attempt it.$untrack
- Purging history (git filter-repo, BFG) rewrites every commit and needs a force-push. Name it as an option, never run it, and say rotation comes first.
- Never open, cat, or grep these files to check the values — that is the exposure this prevents. \`git log --all --oneline -- <path>\` shows when one was committed without printing it.
"
  fi

  if [ -n "$unignored" ]; then
    printf '%s\n' "m-skills ⚠️ ENV FILES NOT IGNORED BY GIT — one \`git add .\` away from being committed:
$(bullets "$unignored")

Open your reply with this in one line, whatever the user asked, and offer to add these lines to .gitignore (a file edit — ask first):
$ignore_lines
Confirm afterwards with \`git check-ignore -v <path>\`, never by opening the file.
"
  fi

  if [ "$hint" -eq 1 ]; then
    local deny_read="" perm_deny="" p
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      deny_read="$deny_read${deny_read:+, }\"./$p\""
      perm_deny="$perm_deny${perm_deny:+, }\"Read(./$p)\""
    done <<< "$on_disk"
    printf '%s\n' "m-skills ℹ️ Real env files are on disk in this project:
$(bullets "$on_disk")
The m-skills secret guard denies reads that name them, but \`grep -r\` or a script that loads dotenv reaches them without naming them — only the OS closes that. At a natural pause, offer ONCE to merge this into .claude/settings.json (ask first; the sandbox also isolates the network, so point the user at /sandbox to review it):

{
  \"permissions\": { \"deny\": [$perm_deny] },
  \"sandbox\": { \"enabled\": true, \"filesystem\": { \"denyRead\": [$deny_read] } }
}

If they decline, create .claude/.m-skills-no-sandbox-hint so this is not offered again.
"
  fi
}
m_skills_secret_hygiene

# ── Silence conditions ────────────────────────────────────────────────────────
[ -f "$OPTOUT" ] && exit 0

# ── Profile exists: check it still tells the truth ────────────────────────────
# A stale profile is worse than a missing one, because the skills TRUST it. Three
# signals, strongest first. A date alone is not one of them: an old profile can be
# perfectly accurate and a profile written this morning can already be wrong.
if [ -f "$PROFILE" ]; then
  DRIFT=""

  # 1. CLAIM CHECK (strongest — zero false positives). Every command and path the
  #    profile names is a falsifiable claim. Verify them against the repo as it is now.
  PKG_SCRIPTS="$(m_skills_pkg_scripts)"
  # backticked tokens only — prose is not a claim
  CLAIMS="$(grep -oE '`[^`]+`' "$PROFILE" 2>/dev/null | tr -d '`' | sort -u)"
  while IFS= read -r c; do
    [ -z "$c" ] && continue
    case "$c" in
      # a named script that no longer exists in the manifest
      npm\ run\ *|pnpm\ run\ *|yarn\ run\ *|bun\ run\ *)
        sc="${c##* run }"; sc="${sc%% *}"
        [ -n "$PKG_SCRIPTS" ] && ! printf '%s\n' "$PKG_SCRIPTS" | grep -qxF -- "$sc" \
          && DRIFT="$DRIFT
  - command \`$c\` is in the profile but \`$sc\` is no longer a script in package.json"
        ;;
      # a file path that no longer resolves. Match a known extension OR a slash, so
      # bare filenames like CHANGELOG.md are checked while version strings like 3.5.0
      # are not mistaken for paths.
      *.md|*.json|*.yml|*.yaml|*.toml|*.js|*.ts|*.cjs|*.mjs|*.sh|*.conf|*.lock|*/*)
        case "$c" in *'<'*|*'*'*|*' '*|http*|*'|'*) continue ;; esac
        [ ! -e "$c" ] && DRIFT="$DRIFT
  - path \`$c\` is named in the profile but does not exist"
        ;;
    esac
  done <<< "$CLAIMS"

  # 2. FINGERPRINT (cheap change-detection). Hash the inputs the profile was derived
  #    from. Different hash = something it depends on moved; re-verify it.
  FP_NOW="$(m_skills_fingerprint "$PKG_SCRIPTS")"
  FP_OLD="$(grep -oE '<!-- m-skills-fingerprint: [0-9]+ -->' "$PROFILE" 2>/dev/null | grep -oE '[0-9]+' | head -1)"
  if [ -n "$FP_OLD" ] && [ "$FP_OLD" != "$FP_NOW" ]; then
    DRIFT="$DRIFT
  - the manifest/docs/deploy-config fingerprint changed since the profile was written"
  fi

  # 3. Clean? Say nothing. Silence is the common case and must stay free.
  [ -z "$DRIFT" ] && exit 0

  printf '%s\n' "m-skills: \`.claude/PROJECT-PROFILE.md\` makes claims that no longer match this repo.
This matters because the skills TRUST that file — a stale row silently misroutes every
decision built on it.
$DRIFT

WHAT TO DO — not now, and do not interrupt what the user asked for. At a natural pause,
mention the drift in ONE line and offer to fix just those rows. Verify against the repo
before rewriting anything; do not regenerate the whole profile, and do not touch rows
that are still correct. If a row is genuinely gone, \`n-a\` is the honest value.
Record the new fingerprint as \`<!-- m-skills-fingerprint: $FP_NOW -->\` when you edit it."
  exit 0
fi

# Is this even a project? Bail on scratch directories so the pack never nags.
IS_PROJECT=0
for marker in package.json Makefile pyproject.toml Cargo.toml go.mod composer.json mix.exs build.gradle .git; do
  [ -e "$marker" ] && IS_PROJECT=1 && break
done
[ "$IS_PROJECT" -eq 0 ] && exit 0

# Greenfield? A repo with a manifest but almost no source is a project about to start,
# not a project to analyse. It gets a different message: nothing to detect, only to decide.
# "Source" is not a JavaScript word. The old list stopped at a dozen web languages,
# so a shell, C, C#, Kotlin, Swift, Elixir, or Lua project reported zero files and got
# greeted as not-yet-started — this pack's own repo included.
SRC_COUNT=$(find . -type f \
  \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \
     -o -name '*.vue' -o -name '*.svelte' -o -name '*.astro' \
     -o -name '*.py' -o -name '*.rs' -o -name '*.go' -o -name '*.java' -o -name '*.rb' -o -name '*.php' \
     -o -name '*.c' -o -name '*.h' -o -name '*.cc' -o -name '*.cpp' -o -name '*.hpp' -o -name '*.cs' \
     -o -name '*.kt' -o -name '*.kts' -o -name '*.swift' -o -name '*.m' -o -name '*.mm' \
     -o -name '*.ex' -o -name '*.exs' -o -name '*.erl' -o -name '*.scala' -o -name '*.clj' \
     -o -name '*.hs' -o -name '*.dart' -o -name '*.lua' -o -name '*.pl' -o -name '*.sh' -o -name '*.bash' \
     -o -name '*.sql' -o -name '*.vb' -o -name '*.fs' -o -name '*.zig' -o -name '*.nim' \) \
  -not -path './node_modules/*' -not -path './.git/*' -not -path './vendor/*' -not -path './dist/*' \
  -not -path './build/*' -not -path './target/*' -not -path './.venv/*' -not -path './venv/*' \
  2>/dev/null | head -20 | wc -l)
GREENFIELD=0
[ "$SRC_COUNT" -lt 3 ] && GREENFIELD=1

# A populated source tree settles it whatever the extension is — the list above will
# always be missing somebody's language, and a wrong greenfield greeting on a real
# codebase routes every downstream decision to "decide" instead of "read the repo".
if [ "$GREENFIELD" -eq 1 ]; then
  for d in src lib app scripts pkg internal cmd source; do
    [ -d "$d" ] || continue
    if [ "$(find "$d" -type f 2>/dev/null | head -5 | wc -l)" -ge 3 ]; then
      GREENFIELD=0; break
    fi
  done
fi

# ── Mechanical detection ──────────────────────────────────────────────────────
GATES="$(m_skills_gate_table --list 2>/dev/null \
         | sed 's/^Gate resolution.*$/(resolved from this project:)/')"

PM="unknown"
[ -f package-lock.json ] && PM="npm"
[ -f pnpm-lock.yaml ]    && PM="pnpm"
[ -f yarn.lock ]         && PM="yarn"
{ [ -f bun.lockb ] || [ -f bun.lock ]; } && PM="bun"
[ -f uv.lock ]     && PM="uv"
[ -f poetry.lock ] && PM="poetry"
[ -f Cargo.lock ]  && PM="cargo"
[ -f go.sum ]      && PM="go"

DEPS=""
if [ -f package.json ] && command -v node >/dev/null 2>&1; then
  DEPS="$(node -e "const p=require('./package.json');console.log(Object.keys({...p.dependencies,...p.devDependencies}).join(' '))" 2>/dev/null)"
fi

hint() { case " $DEPS " in *" $1 "*) printf '%s ' "$2" ;; esac; }
FRAMEWORKS="$(hint @angular/core Angular; hint react React; hint vue Vue; hint svelte Svelte; hint next Next.js; hint nuxt Nuxt)"
UI="$(hint tailwindcss Tailwind; hint daisyui DaisyUI; hint @mui/material MUI; hint bootstrap Bootstrap; hint @chakra-ui/react Chakra; hint shadcn-ui shadcn)"
TESTS="$(hint jest Jest; hint vitest Vitest; hint karma Karma; hint jasmine Jasmine; hint mocha Mocha; hint @playwright/test Playwright; hint cypress Cypress; hint @testing-library/react Testing-Library; hint @axe-core/playwright axe-core)"
I18N="$(hint i18next i18next; hint @ngx-translate/core ngx-translate; hint react-i18next react-i18next; hint vue-i18n vue-i18n)"

DOCS=""
for d in CHANGELOG.md README.md ARCHITECTURE.md DEPLOYMENT.md API.md TESTS.md CONTRIBUTING.md \
         docs/CHANGELOG.md docs/ARCHITECTURE.md docs/API.md docs/TESTS.md \
         Documentation/CHANGELOG.md Documentation/ARCHITECTURE.md Documentation/API.md Documentation/TESTS.md; do
  [ -f "$d" ] && DOCS="$DOCS $d"
done
[ -z "$DOCS" ] && DOCS=" (none found at the usual paths)"

COMMIT="no commitlint config found — infer the convention from git log"
for c in commitlint.config.js commitlint.config.cjs commitlint.config.mjs commitlint.config.ts .commitlintrc .commitlintrc.json .commitlintrc.js; do
  [ -f "$c" ] && COMMIT="$c — read the enforced types and subject-case rule from it" && break
done

CI=""
[ -d .github/workflows ] && CI="$(ls .github/workflows 2>/dev/null | head -5 | tr '\n' ' ')"
[ -z "$CI" ] && CI="(no GitHub workflows — check for other CI config)"

# ── Brownfield structural signals ─────────────────────────────────────────────
# On an existing project most profile rows ARE answerable from the repo. Find the
# evidence so nobody gets asked a question the filesystem already answers.
# One helper, no eval — eval re-parses escaped parens and silently breaks the find.
find_src() {
  find . \( -path ./node_modules -o -path ./.git -o -path ./vendor -o -path ./dist \
            -o -path ./build -o -path ./target -o -path ./.next -o -path ./coverage \) -prune \
       -o "$@" -print 2>/dev/null
}

# Where do tests live, and how many are there?
TEST_FILES="$(find_src -type f \( -name '*.spec.*' -o -name '*.test.*' -o -name 'test_*.py' \
              -o -name '*_test.go' -o -name '*_spec.rb' \) | head -200)"
TEST_COUNT="$(printf '%s\n' "$TEST_FILES" | grep -c . )"
if [ "$TEST_COUNT" -gt 0 ]; then
  TEST_SAMPLE="$(printf '%s\n' "$TEST_FILES" | head -3 | tr '\n' ' ')"
  if printf '%s\n' "$TEST_FILES" | grep -qE '^\./(tests?|spec|__tests__)/'; then
    TEST_PLACEMENT="a dedicated test tree"
  else
    TEST_PLACEMENT="beside the source"
  fi
  TESTS_FOUND="$TEST_COUNT files, $TEST_PLACEMENT — e.g. $TEST_SAMPLE"
else
  TESTS_FOUND="none found — no test layer established yet"
fi

# Styling / design-token evidence
STYLE_SIGNALS=""
for f in tailwind.config.js tailwind.config.ts tailwind.config.cjs theme.ts theme.js tokens.css \
         src/styles/tokens.css src/theme.ts src/styles/theme.ts panda.config.ts unocss.config.ts; do
  [ -f "$f" ] && STYLE_SIGNALS="$STYLE_SIGNALS $f"
done
CSSVARS="$(grep -rl -e '--color' -e '--space' -e ':root' --include='*.css' --include='*.scss' \
           --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build . 2>/dev/null | head -3 | tr '\n' ' ')"
[ -n "$CSSVARS" ] && STYLE_SIGNALS="$STYLE_SIGNALS $CSSVARS"
# same file can arrive from both passes
STYLE_SIGNALS="$(printf '%s\n' $STYLE_SIGNALS | sed 's|^\./||' | sort -u | tr '\n' ' ')"
[ -z "${STYLE_SIGNALS// /}" ] && STYLE_SIGNALS="(none found — design system may be undocumented or absent)"

# How does this thing deploy? These files answer most of §Deployment.
DEPLOY_SIGNALS=""
for f in Dockerfile docker-compose.yml docker-compose.yaml vercel.json netlify.toml fly.toml \
         railway.json render.yaml Procfile app.yaml serverless.yml wrangler.toml firebase.json \
         amplify.yml captain-definition .buildpacks Chart.yaml skaffold.yaml; do
  [ -f "$f" ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS $f"
done
[ -d k8s ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS k8s/"
[ -d .platform ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS .platform/"
DEPLOY_WF="$(grep -rliE 'deploy|release|publish' .github/workflows 2>/dev/null | head -3 | tr '\n' ' ')"
[ -n "$DEPLOY_WF" ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS $DEPLOY_WF"
[ -z "$DEPLOY_SIGNALS" ] && DEPLOY_SIGNALS=" (none found — deployment may be manual or undocumented)"

# Environment contract
ENV_SIGNALS=""
for f in .env.example .env.sample .env.template env.example .env.dist; do
  [ -f "$f" ] && ENV_SIGNALS="$ENV_SIGNALS $f"
done
[ -z "$ENV_SIGNALS" ] && ENV_SIGNALS=" (no env example file — the env contract is undocumented)"

# Repo shape
SHAPE="single package"
[ -f pnpm-workspace.yaml ] && SHAPE="monorepo (pnpm workspaces)"
[ -f turbo.json ]         && SHAPE="monorepo (turbo)"
[ -f nx.json ]            && SHAPE="monorepo (nx)"
[ -f lerna.json ]         && SHAPE="monorepo (lerna)"
[ -f go.work ]            && SHAPE="monorepo (go workspaces)"
grep -q '"workspaces"' package.json 2>/dev/null && [ "$SHAPE" = "single package" ] && SHAPE="monorepo (npm/yarn workspaces)"

# In a monorepo the packages usually differ in stack and gates, so name them —
# one flat profile is wrong for most of them (Guidelines §5, Packages section).
PACKAGES=""
case "$SHAPE" in monorepo*)
  for d in packages apps libs services modules; do
    [ -d "$d" ] || continue
    for pkg in "$d"/*/; do
      [ -f "$pkg/package.json" ] || [ -f "$pkg/Cargo.toml" ] || [ -f "$pkg/go.mod" ] || continue
      PACKAGES="$PACKAGES ${pkg%/}"
    done
  done
  PACKAGES="$(printf '%s' "$PACKAGES" | tr ' ' '\n' | grep -c . 2>/dev/null || echo 0) found:$PACKAGES"
  ;;
esac

# ── Optional: write the draft ─────────────────────────────────────────────────
WROTE=""
if [ "${M_SKILLS_AUTOPROFILE:-0}" = "1" ]; then
  mkdir -p .claude
  FP_NOW="$(m_skills_fingerprint "$(m_skills_pkg_scripts)")"
  {
    echo "# Project Profile"
    # The drift check above looks for this marker; a draft without one can never
    # report fingerprint drift. Re-record it whenever the profile is edited.
    echo "<!-- m-skills-fingerprint: $FP_NOW -->"
    echo
    echo "> Draft written by the m-skills SessionStart bootstrap on $(date +%Y-%m-%d)."
    echo "> Rows below the divider are DETECTED facts. Rows marked TODO need someone to read the code."
    echo
    echo "## Identity"
    echo
    echo "- **Package manager:** \`$PM\`"
    echo "- **Stack:** ${FRAMEWORKS:-TODO — read a source file}"
    echo "- **Project:** TODO — one line on what this is"
    echo
    echo "## Commands (detected)"
    echo
    echo '```'
    echo "$GATES"
    echo '```'
    echo
    echo "## Conventions"
    echo
    echo "- **Design system / UI vocabulary:** ${UI:-TODO — open an existing component}"
    echo "- **Test layers in use:** ${TESTS:-TODO — no test deps detected}"
    echo "- **Localized?** ${I18N:-no i18n dependency detected — confirm}"
    echo "- **Test file placement:** TODO — open one existing test"
    echo "- **Coverage bar:** TODO"
    echo
    echo "## Documentation Targets"
    echo
    echo "Found:$DOCS"
    echo
    echo "## Commit Convention"
    echo
    echo "- $COMMIT"
    echo
    echo "## Guardrails Specific to This Project"
    echo
    echo "- **Do not touch:** TODO"
    echo "- **Known blind spots:** TODO — what a green pipeline does not prove here"
    echo
    echo "## Recurring Propagation Sites"
    echo
    echo "_(empty on day one — add a line each time a change lands somewhere the gates missed)_"
  } > "$PROFILE"
  WROTE="A DRAFT has been written to $PROFILE (M_SKILLS_AUTOPROFILE=1). Verify every row; complete the TODOs."
fi

# ── Greenfield: nothing to detect, only to decide ─────────────────────────────
if [ "$GREENFIELD" -eq 1 ]; then
printf '%s\n' "m-skills: this looks like a project that has not really started yet ($SRC_COUNT source files found).
No \`.claude/PROJECT-PROFILE.md\` exists, and there is very little to detect from.

What is knowable now:

- Package manager: $PM
- Gate resolution:
$GATES
- Dependency hints: ${FRAMEWORKS:-none}${UI:+, }${UI:-}${TESTS:+, }${TESTS:-}

$WROTE
WHAT TO DO WITH THIS — do not interrupt whatever the user actually asked for.

A greenfield profile is filled by DECIDING, not detecting, and the decisions belong to whichever
skill first needs them — never to a questionnaire up front (Guidelines §5):

- Writing the first code or tests → \`testing-architect\` / \`implementing-architect\` establish §Conventions.
- Building the first screen → \`design-architect\` runs in Establish mode and writes §Design.
- First deploy → \`deployment-architect\` writes §Deployment.
- First changelog entry → \`rolling-history\` writes §Documentation Targets and §Commit Convention.

So do NOT offer to fill the profile. Offer the conversation instead — at a natural pause, in ONE line:

  \"Project looks new — want to start with /m-skills:brainstorming-planner kickoff? It works out what
   you're building and the first slice, and the setup falls out of that.\"

That skill's Kickoff Mode is the greenfield entry point: it establishes what is being built, routes each
foundational decision to the skill that owns it, defers the rest as \`pending\`, and ends with a plan for
the first slice. If the user would rather just start coding, that is fine too — say nothing more and let
the owning skills ask when they actually need something."
exit 0
fi

# ── Hand it to Claude ─────────────────────────────────────────────────────────
printf '%s\n' "m-skills: this project has no \`.claude/PROJECT-PROFILE.md\`, so the pack's skills would
auto-detect their commands every session instead of reading them once.

Mechanically detected just now (verified from real files — safe to trust):

- Package manager: $PM
- Gate resolution:
$GATES
- Framework hints (from the manifest): ${FRAMEWORKS:-none detected}
- UI / design system hints: ${UI:-none detected}
- Test tooling hints: ${TESTS:-none detected}
- i18n hints: ${I18N:-none detected}
- Repo shape: $SHAPE${PACKAGES:+
- Workspace packages: $PACKAGES
  (each may differ in stack, gates, and deploy target — the profile needs a §Packages
   table, and skills resolve the package from the paths they touch, not from the root)}
- Docs found:$DOCS
- Commit convention: $COMMIT
- CI workflows: $CI
- Tests: $TESTS_FOUND
- Styling / token evidence:$STYLE_SIGNALS
- Deployment evidence:$DEPLOY_SIGNALS
- Env contract:$ENV_SIGNALS

$WROTE

WHAT TO DO WITH THIS — do not act on it now, and do not interrupt whatever the user
actually asked for. At a natural pause, offer in ONE line: \"No PROJECT-PROFILE.md here —
want me to write one? ~2 min. /m-skills:onboard does it and also adopts the existing docs.\" Then:

- Only if they say yes: fill the template at $PLUGIN/skills/guidelines-meta/PROJECT-PROFILE.template.md
  and write it to .claude/PROJECT-PROFILE.md. Fill every row the repo can answer — the detected values
  above plus whatever the files they point at reveal. Mark a row \`pending: <when>\` ONLY when the answer
  genuinely does not exist yet (no deploy has ever happened, no UI exists); its owning skill fills it
  when that moment arrives (Guidelines §5). A row left \`pending\` because nobody opened the file is a
  defect, not a deferral.
- **This is an existing project, so investigate before you ask.** The signals above are pointers,
  not answers. Open the files they point at: a test (placement, framework, style), a component and
  a token/style file (design system), the changelog (format), the deploy config and CI workflow
  (how it ships), the env example (what config it needs). Almost every profile row is answerable
  from the repo.
- **Only then ask** — and only for what the code genuinely cannot say: intent, preferences, who
  fires a deploy, where production secrets live, the coverage bar the team wants, the rollback
  they would actually perform. Asking a question the repo already answers is a defect.
- Never invent a value to fill a row — an absent gate is \`n-a\`.
- If they decline, create .claude/.m-skills-no-bootstrap so this never asks again."
exit 0
