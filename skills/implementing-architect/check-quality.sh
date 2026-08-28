#!/usr/bin/env bash
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
# skill-preamble.sh injects as the resolved gate table, so if it ignored the profile the
# hook would hand Claude auto-detected commands under the profile's name.
#
# Snapshot policy: NEVER runs a golden/snapshot update command. Diffs are surfaced for manual review.
# Usage: bash .claude/skills/implementing-architect/check-quality.sh [--list]

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

CONF=".claude/quality-gates.conf"
PROFILE=".claude/PROJECT-PROFILE.md"
GATE_KEYS=(LINT TYPECHECK TEST BUILD E2E VISUAL A11Y AUDIT)
GATE_LABELS=("Lint" "Type-check" "Tests + Coverage" "Build" "E2E" "Visual regression" "Accessibility" "Dependency audit")

for k in "${GATE_KEYS[@]}"; do eval "$k=\"\${$k:-}\""; done
VISUAL_REPORT="${VISUAL_REPORT:-}"
UPDATE_CMD="${UPDATE_CMD:-}"

# Which of these arrived from the environment (LINT=x bash check-quality.sh)? That
# is the most explicit signal available, so it outranks the profile too. Everything
# not marked here is fair game for the profile to override.
ENV_PINNED=""
for k in "${GATE_KEYS[@]}" VISUAL_REPORT UPDATE_CMD; do
  if [ -n "${!k}" ]; then
    ENV_PINNED="$ENV_PINNED $k"
    printf -v "ENVVAL_$k" '%s' "${!k}"
  fi
done
env_pinned() { case " $ENV_PINNED " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
# Sourcing the conf below blindly assigns, which used to silently clobber a value
# passed on the invocation. Re-apply the pinned ones afterwards so precedence reads
# the way anyone would expect: env > profile > conf > detection.
restore_env_pinned() {
  local k v
  for k in $ENV_PINNED; do v="ENVVAL_$k"; printf -v "$k" '%s' "${!v}"; done
}

# ── 1. Explicit config ────────────────────────────────────────────────────────
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"
  restore_env_pinned
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
# No eval: awk emits KEY<TAB>VALUE and the loop assigns by an explicit case.
if [ -f "$PROFILE" ]; then
  PROFILE_SET=0
  while IFS="$(printf '\t')" read -r pkey pval; do
    [ -z "$pkey" ] && continue
    env_pinned "$pkey" && continue
    case "$pkey" in
      LINT|TYPECHECK|TEST|BUILD|E2E|VISUAL|A11Y|AUDIT|UPDATE_CMD|VISUAL_REPORT)
        printf -v "$pkey" '%s' "$pval"; PROFILE_SET=1 ;;
    esac
  done <<PROFILE_ROWS
$(awk '
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
' "$PROFILE")
PROFILE_ROWS
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
    local s; s="$(pick_script "$@")" && eval "$var=\"\$RUN \$s\""
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
elif [ -f Makefile ]; then
  for i in "${!GATE_KEYS[@]}"; do
    k="${GATE_KEYS[$i]}"; t="$(echo "$k" | tr '[:upper:]' '[:lower:]')"
    [ -z "${!k}" ] && has_make_target "$t" && eval "$k=\"make $t\""
  done
elif [ -f pyproject.toml ]; then
  RUNNER=""
  command -v uv >/dev/null 2>&1 && RUNNER="uv run"
  [ -z "$RUNNER" ] && [ -f poetry.lock ] && RUNNER="poetry run"
  [ -z "$LINT" ]      && LINT="$RUNNER ruff check ."
  [ -z "$TYPECHECK" ] && TYPECHECK="$RUNNER mypy ."
  [ -z "$TEST" ]      && TEST="$RUNNER pytest"
elif [ -f Cargo.toml ]; then
  [ -z "$LINT" ]  && LINT="cargo clippy -- -D warnings"
  [ -z "$TEST" ]  && TEST="cargo test"
  [ -z "$BUILD" ] && BUILD="cargo build --release"
  [ -z "$AUDIT" ] && AUDIT="cargo audit"
elif [ -f go.mod ]; then
  [ -z "$LINT" ]      && LINT="go vet ./..."
  [ -z "$TYPECHECK" ] && TYPECHECK="go build ./..."
  [ -z "$TEST" ]      && TEST="go test ./..."
fi

# ── --list: show resolution and exit ──────────────────────────────────────────
if [ "${1:-}" = "--list" ]; then
  echo "Gate resolution ($SOURCE):"
  for i in "${!GATE_KEYS[@]}"; do
    k="${GATE_KEYS[$i]}"
    printf '  %-18s %s\n' "${GATE_LABELS[$i]}" "${!k:-n-a}"
  done
  printf '  %-18s %s\n' "Update (user-only)" "${UPDATE_CMD:-n-a}"
  exit 0
fi

RESOLVED=0
for k in "${GATE_KEYS[@]}"; do [ -n "${!k}" ] && RESOLVED=$((RESOLVED + 1)); done
if [ "$RESOLVED" -eq 0 ]; then
  echo "❌ No quality gates resolved. Create $CONF (see the template at the end of this script)."
  exit 1
fi

# ── 3. Run ────────────────────────────────────────────────────────────────────
echo "⚖️  Quality Check — $RESOLVED gate(s), $SOURCE"
echo

declare -a RESULTS=()
STEP=0
for i in "${!GATE_KEYS[@]}"; do
  k="${GATE_KEYS[$i]}"; cmd="${!k}"
  [ -z "$cmd" ] && continue
  STEP=$((STEP + 1))
  echo "▶ [$STEP/$RESOLVED] ${GATE_LABELS[$i]} — $cmd"
  eval "$cmd"
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
  for i in "${!GATE_KEYS[@]}"; do [ "${GATE_KEYS[$i]}" = "$k" ] && label="${GATE_LABELS[$i]}"; done
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
