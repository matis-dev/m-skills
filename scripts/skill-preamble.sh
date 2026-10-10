#!/usr/bin/env bash
# m-skills — inject the shared preamble when a pack skill starts.
#
# Claude Code 2.1.158 has no skill-load event (InstructionsLoaded is for CLAUDE.md
# memory files, memory_type User|Project|Local|Managed — not skills). This covers
# both invocation paths instead:
#
#   UserPromptExpansion  → the user typed /m-skills:<name>. Covers the 11 skills
#                          with disable-model-invocation: true. Emits additionalContext.
#   PostToolUse (Skill)  → the model invoked an auto-loadable knowledge skill
#                          (design, testing, security, accessibility, documentation).
#                          Emits decision:block + reason, which the runtime feeds
#                          back to Claude while the turn continues.
#
# What it injects, deterministically, so the skill files stop re-deriving it:
#   1. the gate table, as implementing-architect's gate resolver lists it
#   2. guidelines-meta §9, §10, §15, §19, read live from the skill file
#   3. the composition map for this skill — which modules and reference files it
#      names — derived by grepping the skill file rather than from a static table,
#      so it cannot drift out of step with the file it describes.
#
# Silent for any skill outside this pack. Advisory: fails OPEN.

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
# Dependency note: bash + coreutils only, like the rest of the pack. A payload is read
# by jq or Python when the machine has one, and by the awk reader below otherwise — a
# real parser either way, because pulling a command out of JSON with sed is how a
# guard gets bypassed by a quoted newline. Nothing has to be installed: a work laptop
# that may not install Python still runs every guard.
#
# Windows (Git Bash) breaks jq and Python in ways that fail OPEN, so both are handled here:
#   - `python3` is often the Microsoft Store stub: on PATH, exits 9009, prints nothing.
#     A guard handed an empty command allows it. A real Python 3 there is usually
#     `python` or `py -3`, so each candidate is run once, not just found.
#   - Native jq.exe and python.exe end lines with CRLF, and $(…) keeps the CR:
#     "run_command\r" matches no case arm. Every call goes through m_skills_lf.
#
# The engine name stays "python3" whichever interpreter answered; M_SKILLS_PY holds it.

M_SKILLS_JSON_ENGINE=""
M_SKILLS_PY=()
if command -v jq >/dev/null 2>&1; then
  M_SKILLS_JSON_ENGINE="jq"
else
  for _m_py in python3 python "py -3"; do
    command -v "${_m_py%% *}" >/dev/null 2>&1 || continue
    # shellcheck disable=SC2086 # "py -3" is meant to split into command and flag
    if $_m_py -c 'import json, sys; sys.exit(sys.version_info[0] != 3)' >/dev/null 2>&1; then
      read -r -a M_SKILLS_PY <<< "$_m_py"
      M_SKILLS_JSON_ENGINE="python3"
      break
    fi
  done
  unset _m_py
  command -v awk >/dev/null 2>&1 && [ -z "$M_SKILLS_JSON_ENGINE" ] && M_SKILLS_JSON_ENGINE="awk"
fi

# The built-in reader: a validating JSON parser in portable awk, run with LC_ALL=C so
# every length and offset is in bytes. It must answer exactly as jq does, or the reader
# the machine happens to have becomes the way past a guard:
#   - the last duplicate key wins, and a later duplicate of an ancestor discards what
#     was found beneath the earlier one ({"a":{"b":1},"a":{}} has no a.b);
#   - \uXXXX decodes to UTF-8, a surrogate pair to one character, a lone one to U+FFFD;
#   - invalid JSON, a raw control character in a string included, prints nothing;
#   - null prints nothing, other non-strings print as JSON text (true, 3, {...}).
# Linear time. Every \\ and \" is first masked in a copy with two bytes that cannot
# occur in valid JSON, so the quotes left standing are exactly the string boundaries:
# one split finds every string, two regex tests check every escape, and only keys and
# the value asked for are cut from the original and decoded.
M_SKILLS_JSON_AWK='
BEGIN {
  ESC["\""] = "\""; ESC["/"] = "/"; ESC["n"] = "\n"; ESC["t"] = "\t"
  ESC["r"] = "\r"; ESC["b"] = sprintf("%c", 8); ESC["f"] = sprintf("%c", 12)
  CTRL = sprintf("[%c-%c%c%c%c-%c]", 1, 8, 11, 12, 14, 31)
  Q2 = sprintf("%c%c", 1, 1)
  np = split(ENVIRON["M_SKILLS_JP"], W, ".")
}
{ buf = buf $0 "\n" }
END {
  ok = 1; found = 0; out = ""
  if (buf ~ CTRL) exit
  y = buf
  gsub(/\\[\\"]/, Q2, y)
  if (y ~ /\\([^\/bfnrtu]|$)/ || y ~ /\\u([^0-9a-fA-F]|.[^0-9a-fA-F]|..[^0-9a-fA-F]|...[^0-9a-fA-F])/) exit
  if (!lex(y)) exit
  ti = 1; pval(0, 1)
  if (ok && ti == nt + 1 && found) printf "%s", out
}
function lex(y,   m, i, pos) {
  m = split(y, P, /"/); nt = 0; pos = 1
  for (i = 1; i <= m; i++) {
    if (i % 2) { if (!lexs(P[i])) return 0 }
    else if (i == m || index(P[i], "\t") || index(P[i], "\n") || index(P[i], "\r")) return 0
    else { T[++nt] = "s"; SS[nt] = pos; SL[nt] = length(P[i]) }
    pos += length(P[i]) + 1
  }
  return 1
}
function sraw(n) { return substr(buf, SS[n], SL[n]) }
function lexs(x,   n, j, c, st) {
  n = length(x); j = 1
  while (j <= n) {
    c = substr(x, j, 1)
    if (c == " " || c == "\t" || c == "\n" || c == "\r") { j++; continue }
    if (index("{}[]:,", c)) { T[++nt] = c; j++; continue }
    st = j
    while (j <= n && index("+-.0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", substr(x, j, 1))) j++
    if (j == st) return 0
    c = substr(x, st, j - st)
    if (c !~ /^(true|false|null|-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][-+]?[0-9]+)?)$/) return 0
    T[++nt] = "v"; V[nt] = c
  }
  return 1
}
function pval(d, on,   st, t) {
  st = ti; t = T[ti]
  if (t == "s") { ti++; if (on && d == np) { out = dec(sraw(st)); found = 1 }; return }
  if (t == "v") { ti++; if (on && d == np) { out = (V[st] == "null") ? "" : V[st]; found = 1 }; return }
  if (t == "{") pobj(d, on)
  else if (t == "[") parr(d, on)
  else { ok = 0; return }
  if (ok && on && d == np) { out = raw(st, ti - 1); found = 1 }
}
function pobj(d, on,   k, kon) {
  if (T[++ti] == "}") { ti++; return }
  while (ok) {
    if (T[ti] != "s") { ok = 0; return }
    k = dec(sraw(ti))
    if (T[++ti] != ":") { ok = 0; return }
    ti++
    kon = on && d < np && k == W[d + 1]
    if (kon) { found = 0; out = "" }
    pval(d + 1, kon)
    if (!ok) return
    if (T[ti] == ",") { ti++; continue }
    if (T[ti] == "}") { ti++; return }
    ok = 0
  }
}
function parr(d, on,   k, kon) {
  if (T[++ti] == "]") { ti++; return }
  k = 0
  while (ok) {
    kon = on && d < np && W[d + 1] ~ /^[0-9]+$/ && k++ == W[d + 1] + 0
    if (kon) { found = 0; out = "" }
    pval(d + 1, kon)
    if (!ok) return
    if (T[ti] == ",") { ti++; continue }
    if (T[ti] == "]") { ti++; return }
    ok = 0
  }
}
function raw(a, b,   r, i) {
  r = ""
  for (i = a; i <= b; i++) {
    if (T[i] == "s") r = r "\"" sraw(i) "\""
    else if (T[i] == "v") r = r V[i]
    else r = r T[i]
  }
  return r
}
function dec(x,   m, i, t, c, h, lo, r) {
  if (!index(x, "\\")) return x
  m = split(x, S, /\\/); r = S[1]; i = 2
  while (i <= m) {
    t = S[i]
    if (t == "") { r = r "\\"; if (++i <= m) r = r S[i++]; continue }
    c = substr(t, 1, 1)
    if (c != "u") { r = r ESC[c] substr(t, 2); i++; continue }
    h = hex(substr(t, 2, 4))
    if (h >= 55296 && h <= 56319 && length(t) == 5 && i < m && S[i + 1] ~ /^u[dD][c-fC-F]/) {
      lo = hex(substr(S[++i], 2, 4)); h = 65536 + (h - 55296) * 1024 + (lo - 56320); t = S[i]
    } else if (h >= 55296 && h <= 57343) h = 65533
    r = r utf8(h) substr(t, 6); i++
  }
  return r
}
function hex(s,   v, i) {
  v = 0
  for (i = 1; i <= 4; i++) v = v * 16 + index("0123456789abcdef", tolower(substr(s, i, 1))) - 1
  return v
}
function utf8(c) {
  if (c < 128) return sprintf("%c", c)
  if (c < 2048) return sprintf("%c%c", 192 + int(c / 64), 128 + c % 64)
  if (c < 65536) return sprintf("%c%c%c", 224 + int(c / 4096), 128 + int(c / 64) % 64, 128 + c % 64)
  return sprintf("%c%c%c%c", 240 + int(c / 262144), 128 + int(c / 4096) % 64, 128 + int(c / 64) % 64, 128 + c % 64)
}
'

# m_skills_lf — drop the CR from each CRLF line ending; LF output passes unchanged.
# A literal CR in the script, since BSD sed has no \r escape.
m_skills_lf() { sed $'s/\r$//'; }
m_skills_jq() { jq "$@" | m_skills_lf; }
m_skills_py() { "${M_SKILLS_PY[@]}" "$@" | m_skills_lf; }

# Read the entire stdin payload. Call once; stdin is not rewindable.
hook_read_input() { cat; }

# json_field <payload> <dotted.path> — prints the string value, empty if absent. A
# numeric segment indexes an array: workspacePaths.0.
json_field() {
  local payload="$1" path="$2"
  case "$M_SKILLS_JSON_ENGINE" in
    jq)
      printf '%s' "$payload" | m_skills_jq -r --arg p "$path" '
        reduce ($p | split(".")[]) as $k (.;
          if type == "object" then .[$k]
          elif type == "array" and ($k | test("^[0-9]+$")) then .[$k | tonumber]
          else null end)
        | if . == null then "" elif type == "string" then . else tojson end
      ' 2>/dev/null
      ;;
    python3)
      printf '%s' "$payload" | m_skills_py -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
for k in sys.argv[1].split("."):
    if isinstance(d, dict):
        d = d.get(k)
    elif isinstance(d, list) and k.isdigit() and int(k) < len(d):
        d = d[int(k)]
    else:
        d = None
        break
print(d if isinstance(d, str) else ("" if d is None else json.dumps(d)))
' "$path" 2>/dev/null
      ;;
    awk)
      printf '%s' "$payload" | M_SKILLS_JP="$path" LC_ALL=C awk "$M_SKILLS_JSON_AWK" 2>/dev/null
      ;;
    *) return 1 ;;
  esac
}

# json_string <text> — the text as a JSON string literal, quotes included. Plain bash:
# writing JSON needs no parser, so this is the same on every machine.
json_string() {
  local s="$1" c i
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  if [[ $s == *[[:cntrl:]]* ]]; then
    for ((i = 1; i < 32; i++)); do
      printf -v c "\\$(printf '%03o' "$i")"
      s="${s//"$c"/$(printf '\\u%04x' "$i")}"
    done
  fi
  printf '"%s"' "$s"
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

# m_skills_guard_log <reason> — a check that stepped aside, one tab-separated line in
# $CLAUDE_CONFIG_DIR/m-skills/guards.log (default ~/.claude): time, script, reason.
# Steps aside rather than denies whenever the machine or the host version is the cause —
# neither is the user's mistake, and blocking every call would stop their work over it.
# The reason names what was missing, never the command or path, so no secret path is logged.
m_skills_guard_log() {
  local d="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/m-skills"
  mkdir -p "$d" 2>/dev/null || return 0
  printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${0##*/}" "$1" >> "$d/guards.log" 2>/dev/null
  return 0
}

# A guard with no reader at all — awk missing too — steps aside.
guard_require_json_engine() {
  [ -n "$M_SKILLS_JSON_ENGINE" ] && return 0
  m_skills_guard_log "no JSON reader: jq, Python 3, and awk are all missing"
  exit 0
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

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

# UserPromptExpansion is registered with no matcher, so this fires on EVERY user
# prompt. Decide "not mine" with a shell builtin before spending a jq/python3
# spawn on it — an ordinary message must cost nothing.
case "$INPUT" in *m-skills:*) ;; *) exit 0 ;; esac

advisory_require_json_engine

EVENT="$(json_field "$INPUT" "hook_event_name")"
SESSION="$(json_field "$INPUT" "session_id")"

case "$EVENT" in
  UserPromptExpansion)
    NAME="$(json_field "$INPUT" "command_name")"
    ;;
  PostToolUse)
    NAME="$(json_field "$INPUT" "tool_input.skill")"
    [ -z "$NAME" ] && NAME="$(json_field "$INPUT" "tool_input.name")"
    ;;
  *) exit 0 ;;
esac

# Only this pack's skills. Anything else is somebody else's business.
case "$NAME" in
  m-skills:*) SKILL="${NAME#m-skills:}" ;;
  *) exit 0 ;;
esac
# The name becomes a path segment below (skills/<name>/, commands/<name>.md, the
# marker). Every skill and command name is [a-z0-9-]; anything else, ../ included,
# is not one of ours.
case "$SKILL" in ''|*[!a-z0-9-]*) exit 0 ;; esac

# A route command (commands/<name>.md) is a thin pre-routed entry into one architect —
# /m-skills:decompose is product-architect in decompose mode. Left unresolved, SKILL would
# be "decompose": no skills/decompose/SKILL.md exists, so the composition map below comes
# out empty, and the once-per-session marker gets written under the wrong key — so the
# architect the command then reads injects the whole preamble a second time.
#
# The owner is derived from the command file itself, never from a table here. Every command
# body names its architect as `skills/<owner>/SKILL.md` in step 1, so that path IS the
# declaration; a static map would be one more cross-reference to rot, which is the same
# reason the composition map below is grepped rather than tabulated.
CMD_FILE="$DIR/../commands/$SKILL.md"
if [ -f "$CMD_FILE" ]; then
  for cand in $(grep -ohE 'skills/[a-z0-9-]+/SKILL\.md' "$CMD_FILE" 2>/dev/null); do
    cand="${cand#skills/}"; cand="${cand%/SKILL.md}"
    [ -f "$DIR/../skills/$cand/SKILL.md" ] || continue
    SKILL="$cand"
    break
  done
fi

# guidelines-meta is the source of the preamble; injecting it into itself is noise.
# A module is a fragment loaded BY an architect that already got the preamble.
[ "$SKILL" = "guidelines-meta" ] && exit 0
case "$SKILL" in module-*) exit 0 ;; esac

GUIDELINES="$DIR/../skills/guidelines-meta/SKILL.md"
[ -f "$GUIDELINES" ] || exit 0

# Once per skill per session. A skill invoked through the Skill tool AND its slash
# command satisfies both arms below, which injected the same ~40 lines twice; the
# marker makes that impossible and also stops a re-invocation repeating it.
# Scoped by the payload's session_id — keyed on anything constant, "once per session"
# silently becomes "once per machine" and the injection stops happening at all.
#
# Trade-off, stated because it is real: after a context compaction the preamble is
# gone and will not re-fire for an already-marked skill. Acceptable — §9 and §10 are
# table is re-derivable from the gate resolver's --list mode.
MARK="$(m_skills_state_dir "$SESSION")/preamble/$SKILL"
[ -f "$MARK" ] && exit 0
mkdir -p "$(dirname "$MARK")" 2>/dev/null || exit 0
: > "$MARK" 2>/dev/null || exit 0

# The resolved gates, cached per session — the resolution spawns node.
gates() {
  local state cache root
  root="$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" rev-parse --show-toplevel 2>/dev/null || printf '%s' "${CLAUDE_PROJECT_DIR:-$(pwd)}")"
  state="$(m_skills_state_dir "$SESSION")"
  cache="$state/gates-$(m_skills_gate_cache_key "$root")"
  if [ -f "$cache" ]; then cat "$cache"; return 0; fi
  mkdir -p "$state" 2>/dev/null || return 1
  (cd "$root" 2>/dev/null && m_skills_gate_table --list 2>/dev/null) \
    | tee "$cache" 2>/dev/null
}

GATES="$(gates)"
[ -z "$GATES" ] && GATES="  (gate resolution unavailable — resolve from the Project Profile per Guidelines §5)"

# The composition map. Derived from the file itself, never from a table here: a
# static list would be one more cross-reference to rot, which is the failure this
# whole tier exists to remove.
SKILLS_ROOT="$DIR/../skills"
SKILL_FILE="$SKILLS_ROOT/$SKILL/SKILL.md"
MODULES="$(grep -ohE 'module-[a-z-]+' "$SKILL_FILE" 2>/dev/null | sort -u)"
REFS="$(grep -ohE 'references/[a-z0-9-]+\.md' "$SKILL_FILE" 2>/dev/null | sort -u)"

# A skill names a sibling's reference files in prose ("harden → its
# references/secure-construction.md", where "its" is a module). Listing those under
# ${CLAUDE_SKILL_DIR}/ told Claude to read five paths that resolve nowhere, so split
# the hits by where the file actually lives and drop any that exist in neither place.
OWN_REFS=""; FOREIGN_REFS=""
for r in $REFS; do
  if [ -f "$SKILLS_ROOT/$SKILL/$r" ]; then
    OWN_REFS="$OWN_REFS$r
"
  else
    for d in "$SKILLS_ROOT"/*/; do
      [ -f "$d$r" ] || continue
      FOREIGN_REFS="$FOREIGN_REFS$(basename "${d%/}")/$r
"
      break
    done
  fi
done
OWN_REFS="$(printf '%s' "$OWN_REFS" | grep -v '^$' | sort -u)"
FOREIGN_REFS="$(printf '%s' "$FOREIGN_REFS" | grep -v '^$' | sort -u)"

COMPOSITION=""
if [ -n "$MODULES" ] || [ -n "$OWN_REFS" ] || [ -n "$FOREIGN_REFS" ]; then
  COMPOSITION="
## What this skill composes from

Load a piece **when the run reaches it**, not up front — that is the point of the split.
Read what the run needs and no more. Never re-derive a piece's content from memory, and
never paste one back wholesale into a reply.
"
  [ -n "$MODULES" ] && COMPOSITION="$COMPOSITION
Shared modules, loaded by name with the Skill tool:
$(printf '%s\n' "$MODULES" | sed 's/^/  - /')
"
  [ -n "$OWN_REFS" ] && COMPOSITION="$COMPOSITION
Reference files, read with the Read tool from \`\${CLAUDE_SKILL_DIR}/\`:
$(printf '%s\n' "$OWN_REFS" | sed 's/^/  - /')
"
  [ -n "$FOREIGN_REFS" ] && COMPOSITION="$COMPOSITION
Reference files owned by ANOTHER skill — load that skill by name first, then read the
file from its directory. They do not exist under this skill's \`\${CLAUDE_SKILL_DIR}/\`:
$(printf '%s\n' "$FOREIGN_REFS" | sed 's/^/  - /')
"
fi

BODY="$(printf '%s\n' "m-skills preamble for \`${SKILL}\` — injected by the plugin's hook, not by the model.

## Resolved gates for this project (Guidelines §5)

Use these verbatim. Do not re-derive them, and never invent a command that is not listed.

\`\`\`
${GATES}
\`\`\`

A role showing \`n-a\` has no gate in this project — say so and move on (Guidelines §5 step 3, §15).

## Enforced, not advisory

§9 and §10 below are enforced by the plugin's PreToolUse hook. A git mutation or a
snapshot-update command will be **denied by the runtime**, not merely discouraged.
They are restated here so you know why before you reach for one.

$(m_skills_section "$GUIDELINES" 9)
$(m_skills_section "$GUIDELINES" 10)

## Still on you — no hook can check these

$(m_skills_section "$GUIDELINES" 15)
$(m_skills_section "$GUIDELINES" 19)
${COMPOSITION}")"

case "$EVENT" in
  UserPromptExpansion) emit_context "UserPromptExpansion" "$BODY" ;;
  PostToolUse)         emit_block "$BODY" ;;
esac
