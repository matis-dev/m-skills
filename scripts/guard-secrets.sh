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
# Opt out with .claude/.m-skills-no-guards. Fails CLOSED.

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
SECRET="$M_SKILLS_SECRET_RE"

# File tools also get `docker.env`-style names. Shell words do not: there,
# `process.env` would match.
FILE_SECRET="$SECRET|(^|/)[^/]+\\.env\$"

# is_secret <path> <regex>
is_secret() {
  printf '%s' "$1" | grep -Eq "$EXAMPLE" && return 1
  printf '%s' "$1" | grep -Eq "$2"
}

# glob_hits_secret <pattern> [shell] — whether a glob would match a secret file:
# `.env*`, `.e?v`, `*.pem`. A pattern with no literal character (`*`, `*.*`) names
# nothing. With `shell`, a dotfile only matches a pattern that starts with a dot,
# which is how bash expands it.
glob_hits_secret() {
  local pat="${1##*/}" name
  case "$pat" in *[A-Za-z0-9]*) ;; *) return 1 ;; esac
  for name in .env .env.local .env.production .env.development .envrc \
              _.pem _.key _.p12 id_rsa id_ed25519 .npmrc .pypirc .netrc; do
    if [ "${2:-}" = shell ]; then
      case "$name" in .*) case "$pat" in .*) ;; *) continue ;; esac ;; esac
    fi
    # shellcheck disable=SC2053 # the right side is meant to be a pattern
    [[ $name == $pat ]] && return 0
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
    is_secret "$FILE" "$FILE_SECRET" && deny_write "$FILE"
    ;;
  Read)
    FILE="$(json_field "$INPUT" "tool_input.file_path")"
    [ -n "$FILE" ] && is_secret "$FILE" "$FILE_SECRET" && deny_read "$FILE"
    ;;
  Grep)
    # A search pointed at a secret file, or filtered down to one, reads it. A
    # directory-wide search is left to the runtime's own Read deny rules.
    P="$(json_field "$INPUT" "tool_input.path")"
    G="$(json_field "$INPUT" "tool_input.glob")"
    [ -n "$P" ] && is_secret "$P" "$FILE_SECRET" && deny_read "$P"
    [ -n "$G" ] && { is_secret "$G" "$FILE_SECRET" || glob_hits_secret "$G"; } && deny_read "$G"
    ;;
  Bash)
    CMD="$(json_field "$INPUT" "tool_input.command")"
    [ -z "$CMD" ] && exit 0
    # One pass over the whole command; almost every command ends here.
    HITS="$(words "$CMD" | grep -Ev "$EXAMPLE" | grep -E "$SECRET")"
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
