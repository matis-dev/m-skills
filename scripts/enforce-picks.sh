#!/usr/bin/env bash
# m-skills — a pick in the picker must provably start the skill it names.
#
# Guidelines §17 makes a picked option that names a gated skill the user starting it:
# the model reads that skill's SKILL.md and runs it. That was prose only. A session on
# 2026-09-13 picked "Yes — run debugging-architect" and got a grep and a plan file
# instead, and even a pick that worked loaded the file with Read, so skill-preamble.sh
# (Skill tool and slash command only) never injected the gates. Three branches:
#
#   PostToolUse · AskUserQuestion  a chosen option label naming a gated skill leaves a
#                                  pending marker and tells Claude which file to read.
#   PostToolUse · Read | Bash      reading that SKILL.md clears the marker, logs
#                                  "loaded", and injects the preamble via skill-preamble.sh.
#   Stop                           a marker still pending holds the turn open once;
#                                  on the second stop it is logged "NOT loaded" and let go.
#
# Only an OFFERED label counts, never free text typed into Other — a remark is not a
# pick. Skill names come from the skill files, never from the payload, and the answer
# text is neither executed, used in a path, nor logged.
#
# Log: $CLAUDE_CONFIG_DIR/m-skills/picks.log (default ~/.claude), one tab-separated line
# per outcome: time, session, project, skill, loaded | NOT loaded.
#
# Honours .m-skills-no-guards. Advisory: fails OPEN.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

# Read, Bash, and Stop fire constantly; they only matter while a pick is pending in
# some session. Decide that with a glob before spending a jq/python3 spawn.
STATE_BASE="$(dirname "$(m_skills_state_dir probe)")"
case "$INPUT" in
  *AskUserQuestion*) ;;
  *) pending=0
     for m in "$STATE_BASE"/*/pick/*; do [ -e "$m" ] && { pending=1; break; }; done
     [ "$pending" -eq 1 ] || exit 0 ;;
esac

advisory_require_json_engine

EVENT="$(json_field "$INPUT" "hook_event_name")"
TOOL="$(json_field "$INPUT" "tool_name")"
SESSION="$(json_field "$INPUT" "session_id")"
PICKS="$(m_skills_state_dir "$SESSION")/pick"
SKILLS="$(cd "$DIR/../skills" 2>/dev/null && pwd)" || exit 0

log_pick() { # <skill> <outcome>
  local d="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/m-skills"
  mkdir -p "$d" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(m_skills_session_id "$SESSION")" \
    "${CLAUDE_PROJECT_DIR:-$PWD}" "$1" "$2" >> "$d/picks.log" 2>/dev/null
  return 0
}

# The skills the model cannot start on its own — frontmatter only, as suggest-skills.sh reads it.
gated_names() {
  local f
  for f in "$SKILLS"/*/SKILL.md; do
    awk 'NR == 1 && $0 == "---" { fm = 1; next }
         fm && $0 == "---"      { exit }
         !fm                    { exit }
         /^disable-model-invocation:[ \t]*true[ \t]*$/ { g = 1 }
         END { exit !g }' "$f" 2>/dev/null && basename "$(dirname "$f")"
  done
}

# One line per offered label ("L<TAB>…") and per chosen answer ("A<TAB>…"). The answers
# arrive as tool_response.answers {question: label}; a string response ("Q"="A") is
# parsed as the fallback, since the hook payload shape was inferred from transcripts.
pick_lines() {
  case "$M_SKILLS_JSON_ENGINE" in
    jq)
      printf '%s' "$INPUT" | jq -r '
        def flat: gsub("[\t\n]"; " ");
        (.tool_input.questions[]?.options[]?.label | strings | "L\t" + flat),
        (.tool_response
          | if type == "array" then (map(.text? // "") | join("\n")) else . end
          | if type == "object" then
              (.answers // {} | to_entries[] | .value | if type == "array" then .[] else . end | tostring)
            elif type == "string" then
              (scan("\"=\"([^\"]*)\"") | .[0])
            else empty end
          | "A\t" + flat)' 2>/dev/null
      ;;
    python3)
      printf '%s' "$INPUT" | python3 -c '
import json, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
flat = lambda s: re.sub(r"[\t\n]", " ", s)
qs = (d.get("tool_input") or {}).get("questions") or []
for q in qs if isinstance(qs, list) else []:
    for o in (q.get("options") or []) if isinstance(q, dict) else []:
        if isinstance(o, dict) and isinstance(o.get("label"), str):
            print("L\t" + flat(o["label"]))
r = d.get("tool_response")
if isinstance(r, list):
    r = "\n".join(x.get("text", "") for x in r if isinstance(x, dict))
vals = []
if isinstance(r, dict):
    for v in (r.get("answers") or {}).values():
        vals.extend(v if isinstance(v, list) else [v])
elif isinstance(r, str):
    vals = re.findall(r"\"=\"([^\"]*)\"", r)
for v in vals:
    print("A\t" + flat(str(v)))
' 2>/dev/null
      ;;
  esac
}

case "$EVENT:$TOOL" in

  PostToolUse:AskUserQuestion)
    LINES="$(pick_lines)"
    [ -z "$LINES" ] && exit 0
    GATED="$(gated_names)"
    PICKED=""
    while IFS= read -r label; do
      # a multiSelect answer joins its labels, so an offered label inside the answer counts
      chosen=0
      while IFS= read -r ans; do
        case "$ans" in *"$label"*) chosen=1; break ;; esac
      done <<< "$(printf '%s\n' "$LINES" | sed -n 's/^A\t//p')"
      [ "$chosen" -eq 1 ] || continue
      for name in $GATED; do
        printf '%s' "$label" | grep -qE "(^|[^a-z0-9-])${name}([^a-z0-9-]|\$)" || continue
        case " $PICKED " in *" $name "*) ;; *) PICKED="$PICKED $name" ;; esac
      done
    done <<< "$(printf '%s\n' "$LINES" | sed -n 's/^L\t//p' | grep -v '^$')"
    PICKED="${PICKED# }"
    [ -z "$PICKED" ] && exit 0
    mkdir -p "$PICKS" 2>/dev/null || exit 0
    MSG=""
    for name in $PICKED; do
      : > "$PICKS/$name" 2>/dev/null
      MSG="$MSG
- \`$name\` — Read $SKILLS/$name/SKILL.md now, with the Read tool, and run it in full on the work under discussion. In that file \${CLAUDE_SKILL_DIR} means $SKILLS/$name."
    done
    emit_block "m-skills: the user picked a gated skill in the picker — that is the user starting it (Guidelines §17). No paste line, no second confirm.
$MSG

This turn cannot end until that SKILL.md is loaded."
    ;;

  PostToolUse:Read|PostToolUse:Bash)
    case "$INPUT" in *SKILL.md*) ;; *) exit 0 ;; esac
    [ -d "$PICKS" ] || exit 0
    TARGET="$(json_field "$INPUT" "tool_input.file_path")"
    [ -z "$TARGET" ] && TARGET="$(json_field "$INPUT" "tool_input.command")"
    LOADED=""
    for m in "$PICKS"/*; do
      [ -f "$m" ] || continue
      name="$(basename "$m")"
      # a shell load may reach the file through a variable (D=…/<name>; cat $D/SKILL.md)
      case "$TARGET" in *"skills/$name/SKILL.md"*|*"$name"*SKILL.md*) ;; *) continue ;; esac
      rm -f "$m"
      log_pick "$name" loaded
      [ -z "$LOADED" ] && LOADED="$name"
    done
    [ -z "$LOADED" ] && exit 0
    # One preamble source: hand skill-preamble.sh the payload the Skill tool would have sent.
    printf '{"hook_event_name":"PostToolUse","session_id":%s,"tool_input":{"skill":"m-skills:%s"}}' \
      "$(json_string "$SESSION")" "$LOADED" | bash "$DIR/skill-preamble.sh"
    exit 0
    ;;

  Stop:*)
    [ -d "$PICKS" ] || exit 0
    PENDING=""
    for m in "$PICKS"/*; do [ -f "$m" ] && PENDING="$PENDING $(basename "$m")"; done
    PENDING="${PENDING# }"
    [ -z "$PENDING" ] && exit 0
    # Held once. A second stop means the reminder did not work; record it and let go,
    # or a model that cannot comply loops forever.
    if [ "$(json_field "$INPUT" "stop_hook_active")" = "true" ]; then
      for name in $PENDING; do log_pick "$name" "NOT loaded"; rm -f "$PICKS/$name"; done
      exit 0
    fi
    MSG=""
    for name in $PENDING; do MSG="$MSG
- \`$name\` — Read $SKILLS/$name/SKILL.md and run it on the work under discussion."; done
    emit_block "m-skills: the user picked a gated skill in the picker, but its SKILL.md was never loaded. Picking it was the user starting it (Guidelines §17):
$MSG"
    ;;
esac
exit 0
