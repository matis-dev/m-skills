#!/usr/bin/env bash
# m-skills — PreToolUse guard for secret-bearing files.
#
# Enforces security-architect constraint 5: never write a real secret into a
# tracked file, and never read one into the conversation.
#
# READS and WRITES of real secret files are both denied. The env contract the pack
# depends on (guidelines-meta §5, deployment-architect Phase 0, profile-bootstrap.sh)
# lives in the example files — .env.example / .sample / .template / .dist — and
# those are never blocked in either direction.
#
# This is a tripwire, not a boundary. It sees the path a tool names: Read on .env,
# `cat .env`, `source .env`, `--env-file=.env`, `open('.env')`, `cat .e*`. A process
# that reaches the file without naming it (`grep -r KEY .`, a script that loads
# dotenv itself) passes. The boundary is sandbox.filesystem.denyRead — see README,
# Enforcement.
#
# Opt out with .claude/.m-skills-no-guards. With no JSON reader at all, steps aside and logs.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

TOOL="$(json_field "$INPUT" "tool_name")"

# Example files always pass; the lists are shared with profile-bootstrap.sh.
EXAMPLE="$M_SKILLS_EXAMPLE_RE"
GUARDED_RE="$M_SKILLS_GUARDED_RE"

# File tools also get `docker.env`-style names. Shell words do not: there,
# `process.env` would match.
GUARDED_FILE_RE="$GUARDED_RE|(^|/)[^/]+\\.env\$"

# A shell word that is only an extension (`.key`, `.pem`) is a property path — jq's
# `.key`, JS's `obj.key` split at the dot — not a file with a name.
BARE_EXT='^\.(pem|key|p12|pfx|jks|keystore)$'

# is_secret <path> <regex>. A Windows path (C:\proj\.env) is read with forward
# slashes, or no (^|/) anchor ever matches it.
is_secret() {
  local p="${1//\\//}"
  printf '%s' "$p" | grep -Eq "$EXAMPLE" && return 1
  printf '%s' "$p" | grep -Eq "$2"
}

# glob_hits_secret <pattern> [shell] — whether a glob would match a secret file:
# `.env*`, `.e?v`, `*.pem`. A pattern with no literal character (`*`, `*.*`, `[a-z]*` —
# a bracket expression is a set, not literal text) names nothing. With `shell`, a dotfile only matches a pattern that starts with a dot,
# which is how bash expands it.
glob_hits_secret() {
  local glob="${1//\\//}" name lit
  glob="${glob##*/}"
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

# QUOTE_LEX — the quote reading words, segments, and quoting_unsure share, so the
# three cannot disagree about where a quote ends. lex() classifies $0 at i and moves
# q: sq, "\"", "a" for $'…' (where \ escapes, as it does not in '…'), or "#" for a
# comment, which newline() ends. A `#` opens one only at the start of a word, after
# a blank or an operator; an escape pair leaves p non-blank, so `a\ #x` stays a word.
# Classes: esc (a pair; i left on its second character), open, close, sep (splits
# a command), run (`$(` or a backtick inside double quotes), heredoc, lit.
QUOTE_LEX='
  function newline() { if (q == "#") q = ""; p = " " }
  function lex(   c, nx) {
    c = substr($0, i, 1); nx = substr($0, i + 1, 1)
    if (q == "#") return "lit"
    if (c == "\\" && q != sq) { i++; return "esc" }
    if (q == "") {
      if (c == sq || c == "\"") { q = c; return "open" }
      if (c == "$" && nx == sq) { q = "a"; i++; return "open" }
      if (c == "#" && index(" \t;|&()<>", p)) { q = "#"; return "lit" }
      if (c == "<" && nx == "<") return "heredoc"
      return index(";|&(){}`", c) ? "sep" : "lit"
    }
    if (c == (q == "a" ? sq : q)) { q = ""; return "close" }
    if (q == "\"" && (c == "`" || (c == "$" && nx == "("))) return "run"
    return "lit"
  }
  function after(k, t) { p = (k == "esc") ? "x" : substr(t, length(t), 1) }'

# words <text> [blind] — one word per line, split on whitespace, quotes, and shell
# punctuation, so `--env-file=.env`, `HEAD:.env`, `open('.env')` and `$(<.env)`
# all surface `.env` as a word of its own. Each line is printed twice: as written,
# and with its quoting removed, as bash joins it — `.en""v` and `'.en'v` are `.env`.
# Unquoted, `\.env` is `.env`; a quoted word that starts with `\.` is a regex
# (`grep '\.env'`) and stays whole, marked with \001 because tr drops the quotes that
# tell the two apart. `blind` ignores quotes, so no word stays whole, and drops
# every quote character from the joined copy. On Windows, where `OS=Windows_NT` is
# set in every process, a backslash also separates paths (`C:\proj\.env`), so it
# splits unmarked words.
WIN=0; [ "${OS:-}" = Windows_NT ] && WIN=1
words() {
  printf '%s' "$1" | awk -v sq="'" -v win="$WIN" -v blind="${2:-}" "$QUOTE_LEX"'
    BEGIN { starts = "\"" sq "`;|&<>(){}=,:@$" }
    { newline(); out = ""; deq = ""
      for (i = 1; i <= length($0); i++) {
        s = i; c = substr($0, i, 1); nx = substr($0, i + 1, 1)
        if (blind == "" && c == "\\" && nx == "." && q != "" && q != "#" && (p ~ /[[:space:]]/ || index(starts, p))) {
          out = out "\001"; deq = deq "\001"; p = "\001"; continue
        }
        if (blind == "") k = lex()
        else if (c == "\\") { k = "esc"; i++ }
        else k = (c == sq || c == "\"") ? "open" : "lit"
        t = substr($0, s, i - s + 1); after(k, t)
        if (k == "esc") { t = (win || q != "") ? t : substr(t, 2); out = out t; deq = deq t }
        else if (k == "open" || k == "close") out = out t
        else { out = out t; deq = deq t }
      }
      print out; if (deq != out) print deq }' \
    | tr -s "[:space:]\"'\`;|&<>(){}=,:@\$" '\n' \
    | awk -v win="$WIN" 'index($0, "\001.") == 1 { print "\\" substr($0, 2); next } win { gsub(/\\/, "\n") } { print }'
}

# segments <text> — one command per line, split on ; | & ( ) { } and backticks
# outside quotes. Inside quotes nothing splits (`rg '\.env|x'`, `grep "a|b"`); a
# command that runs inside double quotes makes quoting_unsure true instead.
segments() {
  printf '%s\n' "$1" | awk -v sq="'" "$QUOTE_LEX"'
    { newline(); out = ""
      for (i = 1; i <= length($0); i++) {
        s = i; k = lex(); t = substr($0, s, i - s + 1); after(k, t)
        out = out (k == "sep" ? "\n" : t)
      }
      print out }'
}

# quoting_unsure <text> — true when segments() cannot be trusted to read the command
# as bash does: `$(…)` or a backtick inside double quotes, where bash starts a new
# quoting context; a heredoc, whose body is not shell syntax; or a quote still open
# at the end. Any of them can leave the lexer inside a quote bash has closed, and
# `ls x; cat .env` would then be judged as one `ls`.
quoting_unsure() {
  printf '%s\n' "$1" | awk -v sq="'" "$QUOTE_LEX"'
    { newline()
      for (i = 1; i <= length($0); i++) {
        s = i; k = lex(); t = substr($0, s, i - s + 1); after(k, t)
        if (k == "run" || k == "heredoc") { found = 1; exit }
      }
    }
    END { exit !(found || (q != "" && q != "#")) }'
}

# search_tool <segment> — its command takes a regex and runs no code, so a quoted
# `\.env` in it is a pattern. sed and awk take one too, but run code (`sed '1e cat
# \.env'`). Anywhere else it may be a path: cmd and PowerShell read '\.env' at the
# drive root.
search_tool() {
  local -a w
  read -r -a w <<< "${1//[\"\']/}"
  local i=0 t
  while [ "$i" -lt "${#w[@]}" ] && [[ ${w[$i]} == [A-Za-z_]*=* ]]; do i=$((i + 1)); done
  t="${w[$i]:-}"; t="${t//\\//}"; t="${t##*/}"
  t="$(printf '%s' "${t%.[Ee][Xx][Ee]}" | tr '[:upper:]' '[:lower:]')"
  case "$t" in
    grep|egrep|fgrep|rg|ag|ack|findstr|select-string|sls) return 0 ;;
    git) [ "${w[$((i + 1))]:-}" = grep ] ;;
    *) return 1 ;;
  esac
}

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
    # One pass over the whole command; almost every command ends here. It reads blind,
    # so a quoted '\.env' is a hit until its segment shows a search tool: `bash -c
    # 'cat \.env'` and "$(cat \.env)" undo the escape, and cmd and PowerShell read
    # '\.env' at the drive root.
    HITS="$(words "$CMD" blind | grep -Ev "$EXAMPLE" | grep -Ev "$BARE_EXT" | grep -E "$GUARDED_RE")"
    while IFS= read -r w; do
      [ -n "$w" ] && glob_hits_secret "$w" shell && HITS="$HITS"$'\n'"$w"
    done <<< "$(words "$CMD" | grep -E '[][*?]')"
    HITS="$(printf '%s' "$HITS" | grep -v '^$')"
    [ -z "$HITS" ] && exit 0
    # Then per segment, so `ls .env && cat .env` is judged by its cat. A quoted `\.env`
    # stays a regex only in a search tool's segment, and only when the quote tracking
    # can be trusted; otherwise every separator splits, quoted or not.
    if quoting_unsure "$CMD"; then
      TRUST=0; SEGMENTS="$(printf '%s\n' "$CMD" | awk '{ gsub(/[;|&(){}`]/, "\n"); print }')"
    else
      TRUST=1; SEGMENTS="$(segments "$CMD")"
    fi
    while IFS= read -r seg; do
      mode=blind; [ "$TRUST" = 1 ] && search_tool "$seg" && mode=""
      while IFS= read -r h; do
        # Quotes and backslashes out of both, or `.en""v` and `.e\nv` skip the check.
        [[ ${seg//[\"\'\\]/} == *"${h//\\/}"* ]] || continue
        words "$seg" "$mode" | grep -Fxq -- "$h" || continue
        names_only "$seg" || deny_read "$h"
      done <<< "$HITS"
    done <<< "$SEGMENTS"
    ;;
esac

exit 0
