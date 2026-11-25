#!/usr/bin/env bash
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
#
# Speed is a guard property, not a nicety: a guard that outlives its hooks.json timeout is
# skipped, and the call runs unchecked. Git Bash pays ~70-90 ms per process and ~340 ms
# per Python start, so the hot path of a guard spawns only the JSON engine:
#   - the probe below runs once per PATH and is cached in the private state base;
#   - m_skills_re / m_skills_fixed match in bash, json_fields reads every field in one run;
#   - on Windows awk is tried before Python — one cheap process, and no code page in the way.

# m_skills_state_base — sets M_SKILLS_STATE_BASE to this user's private state dir, or
# returns 1. The base is a predictable name in a shared /tmp, and the hooks read caches
# back out of it — the engine choice, the gate table the preamble injects as "use
# verbatim", the update command the guard denies. Another user who creates the name first
# would own all three, so it is used only when it is ours, private, and not a symlink.
# Windows skips the check: TEMP is per-user there. Spawns nothing on the usual path: mkdir
# only when the base is missing, and the chmod that tightens a base an older version left
# at 755 runs once, recorded in .private.
m_skills_state_base() {
  local base="${TMPDIR:-/tmp}/m-skills-${UID:-0}"
  [ -d "$base" ] || mkdir -p -m 700 "$base" 2>/dev/null
  if [ "${OS:-}" != Windows_NT ]; then
    [ -d "$base" ] && [ ! -L "$base" ] && [ -O "$base" ] || return 1
    [ -f "$base/.private" ] || { chmod 700 "$base" 2>/dev/null && : > "$base/.private"; } || return 1
  fi
  M_SKILLS_STATE_BASE="$base"
}

M_SKILLS_JSON_ENGINE=""
M_SKILLS_PY=()
M_SKILLS_ENGINE_CACHE=""
m_skills_state_base && M_SKILLS_ENGINE_CACHE="$M_SKILLS_STATE_BASE/engine"

# The probe. Each Python candidate is run once, not just found (the Store stub).
_m_skills_probe() {
  local c py order="jq python awk"
  [ "${OS:-}" = Windows_NT ] && order="jq awk python"
  M_SKILLS_JSON_ENGINE=""; M_SKILLS_PY=()
  for c in $order; do
    case "$c" in
      jq|awk) command -v "$c" >/dev/null 2>&1 && { M_SKILLS_JSON_ENGINE="$c"; return 0; } ;;
      python)
        for py in python3 python "py -3"; do
          command -v "${py%% *}" >/dev/null 2>&1 || continue
          # shellcheck disable=SC2086 # "py -3" is meant to split into command and flag
          if $py -c 'import json, sys; sys.exit(sys.version_info[0] != 3)' >/dev/null 2>&1; then
            # shellcheck disable=SC2206 # one of three fixed names, no glob characters
            M_SKILLS_PY=($py); M_SKILLS_JSON_ENGINE="python3"; return 0
          fi
        done ;;
    esac
  done
  return 1
}

# The cache: engine, interpreter, and the PATH and OS it was probed under, one per line.
# Read with builtins and trusted only as one of the fixed answers the probe can give:
# M_SKILLS_PY is executed, so a planted line must never reach it.
_m_skills_engine_load() {
  local e p key
  [ -n "$M_SKILLS_ENGINE_CACHE" ] || return 1
  { IFS= read -r e && IFS= read -r p && IFS= read -r key; } 2>/dev/null < "$M_SKILLS_ENGINE_CACHE" || return 1
  [ "$key" = "$PATH|${OS:-}" ] || return 1
  case "$e:$p" in
    jq:|awk:) command -v "$e" >/dev/null 2>&1 || return 1 ;;
    python3:python3|python3:python|"python3:py -3") command -v "${p%% *}" >/dev/null 2>&1 || return 1 ;;
    *) return 1 ;;
  esac
  M_SKILLS_JSON_ENGINE="$e"
  # shellcheck disable=SC2206 # validated above: one of three fixed names
  M_SKILLS_PY=($p)
}

if ! _m_skills_engine_load; then
  _m_skills_probe
  [ -n "$M_SKILLS_ENGINE_CACHE" ] && [ -n "$M_SKILLS_JSON_ENGINE" ] && \
    printf '%s\n%s\n%s\n' "$M_SKILLS_JSON_ENGINE" "${M_SKILLS_PY[*]}" "$PATH|${OS:-}" \
      > "$M_SKILLS_ENGINE_CACHE" 2>/dev/null
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
  NUL = (ENVIRON["M_SKILLS_JNUL"] == "1")
  npaths = split(ENVIRON["M_SKILLS_JP"], PATHS, " ")
}
{ buf = buf $0 "\n" }
END {
  bad = NUL ? 1 : 0
  if (buf ~ CTRL) exit bad
  y = buf
  gsub(/\\[\\"]/, Q2, y)
  if (y ~ /\\([^\/bfnrtu]|$)/ || y ~ /\\u([^0-9a-fA-F]|.[^0-9a-fA-F]|..[^0-9a-fA-F]|...[^0-9a-fA-F])/) exit bad
  if (!lex(y)) exit bad
  # One walk per path; whether the document is valid does not depend on the path, so
  # the first walk decides it before anything is printed.
  for (pi = 1; pi <= npaths; pi++) {
    np = split(PATHS[pi], W, ".")
    ok = 1; found = 0; out = ""
    ti = 1; pval(0, 1)
    if (!(ok && ti == nt + 1)) exit bad
    if (NUL) printf "%s%c", (found ? out : ""), 0
    else if (found) printf "%s", out
  }
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
  if (c == 0) return ""   # \u0000 is dropped, as $(…) drops a NUL from every other reader
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

# m_skills_has <text> <grep args…> — true if a line of <text> matches. grep -c reads to
# the end: `printf | grep -q` kills printf with SIGPIPE once <text> outgrows the pipe
# buffer, and under pipefail the match reads as a miss. No here-string: past the pipe
# size bash writes it to a temp file, and an unwritable TMPDIR would read as a miss too.
m_skills_has() { local n; n="$(printf '%s' "$1" | grep -c "${@:2}")"; [ "${n:-0}" != 0 ]; }

# m_skills_re <text> <ERE> — bash's own regex over the whole text, no subprocess. The
# guards match with this; m_skills_has spawned three processes per check.
#
# grep reads line by line, so its ^ and $ anchor at every line break and nothing crosses
# one; in [[ =~ ]] a newline is an ordinary character. A pattern gives the same answer
# both ways only if no part of it can match a newline except a boundary, so guard
# patterns are written to that rule:
#   - a boundary is (^|[^…]) or ([…]|$), whose class includes the newline: a match that
#     starts after one is a match at the start of a line, as grep would see it;
#   - a separator inside a match is $M_SKILLS_SP, which is [[:space:]] without newline;
#   - "any characters" is $M_SKILLS_ANY, which is .* without newline;
#   - a bare $ is written (${M_SKILLS_NL}|\$).
# Looping over the lines instead costs one regcomp per line per pattern — 1.8 s on a
# command with an 8,000-line heredoc, measured — which is the timeout this replaces.
m_skills_re() { [[ $1 =~ $2 ]]; }
M_SKILLS_NL=$'\n'
M_SKILLS_SP=$'[[:blank:]\v\f\r]'
M_SKILLS_ANY=$'[^\n]*'

# m_skills_fixed <text> <string> — whether <string> occurs in <text>, as grep -F does
# for a one-line string. No subprocess.
m_skills_fixed() { [[ $1 == *"$2"* ]]; }

# m_skills_re_lines <text> <ERE> — true if a line of <text> matches, exactly as grep -E:
# for a short text (a path) matched with a pattern written for grep, where the rule above
# does not hold. A one-line text takes a single match.
m_skills_re_lines() {
  case "$1" in *"$M_SKILLS_NL"*) ;; *) [[ $1 =~ $2 ]]; return ;; esac
  local f=$- IFS=$'\n' l
  set -f
  # shellcheck disable=SC2206 # split on newline is the point; globbing is off
  local -a lines=($1)
  case "$f" in *f*) ;; *) set +f ;; esac
  for l in "${lines[@]}"; do [[ $l =~ $2 ]] && return 0; done
  return 1
}

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
import json, re, sys
try:
    d = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    if isinstance(d, dict):
        d = d.get(k)
    elif isinstance(d, list) and k.isdigit() and int(k) < len(d):
        d = d[int(k)]
    else:
        d = None
        break
s = d if isinstance(d, str) else ("" if d is None else json.dumps(d))
sys.stdout.buffer.write(re.sub("[\ud800-\udfff]", "\ufffd", s).encode("utf-8"))
' "$path" 2>/dev/null
      ;;
    awk)
      printf '%s' "$payload" | M_SKILLS_JP="$path" LC_ALL=C awk "$M_SKILLS_JSON_AWK" 2>/dev/null
      ;;
    *) return 1 ;;
  esac
}

# The multi-field readers. Each prints every value followed by a NUL, in path order, and
# exits non-zero with no output when the payload is not exactly one valid JSON document.
# A NUL inside a value (\u0000) is dropped, as $(…) drops it from json_field. Python reads
# and writes bytes as UTF-8: decoding stdin with the Windows code page raises on bytes
# like 0x81, and a reader that prints nothing hands the guard an empty command to allow.
M_SKILLS_JQ_FIELDS='[inputs] | if length != 1 then error("not one document") else .[0] end
  | . as $d | ($p | split(" ")[]) as $path
  | $d | reduce ($path | split(".")[]) as $k (.;
      if type == "object" then .[$k]
      elif type == "array" and ($k | test("^[0-9]+$")) then .[$k | tonumber]
      else null end)
  | (if . == null then "" elif type == "string" then . else tojson end)
  | (split("\u0000") | join("")) + "\u0000"'
M_SKILLS_PY_FIELDS='
import json, re, sys
try:
    d = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
except Exception:
    sys.exit(1)
out = []
for p in sys.argv[1:]:
    v = d
    for k in p.split("."):
        if isinstance(v, dict):
            v = v.get(k)
        elif isinstance(v, list) and k.isdigit() and int(k) < len(v):
            v = v[int(k)]
        else:
            v = None
            break
    s = v if isinstance(v, str) else ("" if v is None else json.dumps(v, separators=(",", ":"), ensure_ascii=False))
    out.append(re.sub("[\ud800-\udfff]", "\ufffd", s).replace("\0", "") + "\0")
sys.stdout.buffer.write("".join(out).encode("utf-8"))
'
_m_skills_fields() { # <path>… — the payload on stdin
  local IFS=' '
  case "$M_SKILLS_JSON_ENGINE" in
    jq)      jq -j -n --arg p "$*" "$M_SKILLS_JQ_FIELDS" ;;
    python3) "${M_SKILLS_PY[@]}" -c "$M_SKILLS_PY_FIELDS" "$@" ;;
    awk)     M_SKILLS_JP="$*" M_SKILLS_JNUL=1 LC_ALL=C awk "$M_SKILLS_JSON_AWK" ;;
    *)       return 1 ;;
  esac
}

# json_fields <payload> <VAR> <path> [<VAR> <path>]… — reads every path in one engine run
# and assigns each value to its variable; absent, null, or an unreadable payload leaves it
# empty. A numeric segment indexes an array: workspacePaths.0. One process, not one per
# field: on Git Bash each costs a third of a second under Python.
#
# The payload goes in as a here-string, which spawns no writer. Past the pipe size bash
# writes it to a temp file instead, and an unwritable TMPDIR would read as "no fields" —
# so a run that printed nothing is retried once through printf, as json_field reads it.
# A run that fails both ways also empties the engine cache, so the next hook re-probes:
# an interpreter that broke since it was cached must not keep handing guards nothing.
# Locals are prefixed so no caller's variable name is shadowed by printf -v.
json_fields() {
  local _jf_payload="$1" _jf_i; shift
  local -a _jf_vars=() _jf_paths=()
  while [ $# -ge 2 ]; do _jf_vars+=("$1"); _jf_paths+=("$2"); shift 2; done
  for _jf_i in "${!_jf_vars[@]}"; do printf -v "${_jf_vars[$_jf_i]}" '%s' ""; done
  [ ${#_jf_vars[@]} -gt 0 ] || return 0
  if ! _m_skills_read_fields < <(_m_skills_fields "${_jf_paths[@]}" 2>/dev/null <<< "$_jf_payload"); then
    _m_skills_read_fields < <(printf '%s' "$_jf_payload" | _m_skills_fields "${_jf_paths[@]}" 2>/dev/null) || {
      [ -n "$M_SKILLS_ENGINE_CACHE" ] && : > "$M_SKILLS_ENGINE_CACHE" 2>/dev/null
      return 1
    }
  fi
}
# Reads one NUL-terminated value per name in _jf_vars; fails, setting nothing, unless the
# first one arrives. Native jq.exe ends lines with CRLF, so each value loses the CR before
# every LF and at the end — what m_skills_lf does, without the sed.
_m_skills_read_fields() {
  local _jf_v _jf_n
  for _jf_n in "${!_jf_vars[@]}"; do
    IFS= read -r -d '' _jf_v || { [ "$_jf_n" -gt 0 ] && break; return 1; }
    _jf_v="${_jf_v//$'\r\n'/$'\n'}"
    printf -v "${_jf_vars[$_jf_n]}" '%s' "${_jf_v%$'\r'}"
  done
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
# One definition for guard-secrets.sh (what may not be read or written) and
# profile-bootstrap.sh (what must not sit in git). Two copies would drift apart.

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
# idiom as adhd-always-on.sh: presence is the whole signal, contents ignored.
m_skills_guards_disabled() {
  local project="${CLAUDE_PROJECT_DIR:-$PWD}"
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
#
# The id becomes a directory name, so anything outside [A-Za-z0-9._-] turns into _, one per
# byte (LC_ALL=C), as the tr this replaces did — the names every hook already uses stay.
m_skills_session_id() {
  local from_payload="${1:-}" LC_ALL=C
  [ -n "$from_payload" ] && { printf '%s' "${from_payload//[^A-Za-z0-9._-]/_}"; return; }
  [ -n "${CLAUDE_SESSION_ID:-}" ] && { printf '%s' "${CLAUDE_SESSION_ID//[^A-Za-z0-9._-]/_}"; return; }
  local boot
  boot="$(awk '{print $22}' "/proc/$PPID/stat" 2>/dev/null)" \
    || boot="$(ps -o lstart= -p "$PPID" 2>/dev/null)"
  printf 'pp%s' "$(printf '%s' "${boot:-0}$PPID" | cksum | cut -d' ' -f1)"
}

# A per-session marker directory, so an advisory can fire once rather than every
# time the same file is touched. Pass the payload's session_id; two concurrent
# sessions then never silence each other.
#
# Prints nothing and returns 1 when the base is not ours (m_skills_state_base, top of
# this file). The update-command guard then runs uncached; the advisories, the gate
# preamble, and the pick check stay silent.
m_skills_state_dir() {
  m_skills_state_base || return 1
  printf '%s/%s' "$M_SKILLS_STATE_BASE" "$(m_skills_session_id "${1:-}")"
}
