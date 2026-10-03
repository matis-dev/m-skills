#!/usr/bin/env bash
# m-skills — run a Claude Code guard under Antigravity (agy) PreToolUse.
#
# Usage, from the built plugin's hooks.json:  bash scripts/antigravity-adapt.sh <guard>.sh
#
# The guards stay untouched: this translates agy's payload into the shape they read,
# runs one, and translates its decision back. Shapes captured from agy 1.2.2 on
# 2026-09-29 (a logging hook in a scratch workspace), not taken from the docs:
#
#   in   {"toolCall":{"name":"run_command","args":{"CommandLine":…,"Cwd":…}},
#         "conversationId":…, "workspacePaths":[…], …}
#        view_file → args.AbsolutePath · write_to_file, replace_file_content → args.TargetFile
#   out  {"decision":"deny","reason":…} — agy blocks the call and tells the model
#        "tool call denied by pre-tool hook: <reason>". No output = no opinion.
#   cwd  the plugin directory, and no plugin-root variable is exported.
#
# multi_replace_file_content was not captured; TargetFile is inferred from its sibling.
# If that guess is wrong the call is denied below, visibly, rather than waved through.
#
# Fails CLOSED. The guards treat an empty command or path as "nothing to check", so a
# payload whose argument this cannot find must never reach them as empty.

set -uo pipefail

# Usable before the JSON library loads, so it escapes by deletion rather than by engine.
deny() {
  printf '{"decision":"deny","reason":"%s"}\n' "$(printf '%s' "$1" | tr -d '"\\')"
  exit 0
}

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || deny "m-skills adapter: cannot locate its own directory, so this call could not be checked."
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || deny "m-skills adapter: scripts/lib/hook-json.sh is missing, so this call could not be checked."

GUARD="${1:-}"
case "$GUARD" in
  guard-mutations.sh|guard-outward.sh|guard-secrets.sh) ;;
  *) deny "m-skills adapter: unknown guard '${GUARD}' in hooks.json." ;;
esac

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

[ -n "$M_SKILLS_JSON_ENGINE" ] \
  || deny "m-skills guard: neither jq nor python3 is available, so this call could not be checked against the Guidelines §9/§10 guards. Guards fail closed by design. Install jq or python3, or opt out with: touch .claude/.m-skills-no-guards"

first_workspace() {
  case "$M_SKILLS_JSON_ENGINE" in
    jq) printf '%s' "$1" | jq -r '.workspacePaths[0] // ""' 2>/dev/null ;;
    python3) printf '%s' "$1" | python3 -c '
import json, sys
try: w = json.load(sys.stdin).get("workspacePaths") or [""]
except Exception: w = [""]
print(w[0] if isinstance(w[0], str) else "")' 2>/dev/null ;;
  esac
}

TOOL="$(json_field "$INPUT" "toolCall.name")"
case "$TOOL" in
  run_command)                  AS=Bash;  FIELD=command;   ARG="$(json_field "$INPUT" "toolCall.args.CommandLine")" ;;
  view_file)                    AS=Read;  FIELD=file_path; ARG="$(json_field "$INPUT" "toolCall.args.AbsolutePath")" ;;
  write_to_file)                AS=Write; FIELD=file_path; ARG="$(json_field "$INPUT" "toolCall.args.TargetFile")" ;;
  replace_file_content|multi_replace_file_content)
                                AS=Edit;  FIELD=file_path; ARG="$(json_field "$INPUT" "toolCall.args.TargetFile")" ;;
  *) exit 0 ;;
esac

[ -n "$ARG" ] || deny "m-skills adapter: ${TOOL} arrived without the argument the guards check, so it could not be verified. Guards fail closed; if agy renamed the argument, rebuild the plugin from an updated m-skills."

WS="$(first_workspace "$INPUT")"
[ -n "$WS" ] && export CLAUDE_PROJECT_DIR="$WS"

PAYLOAD="$(printf '{"tool_name":"%s","tool_input":{"%s":%s},"session_id":%s}' \
  "$AS" "$FIELD" "$(json_string "$ARG")" "$(json_string "$(json_field "$INPUT" "conversationId")")")"

OUT="$(printf '%s' "$PAYLOAD" | bash "$DIR/$GUARD" 2>/dev/null)"
[ -z "$OUT" ] && exit 0

DECISION="$(json_field "$OUT" "hookSpecificOutput.permissionDecision")"
REASON="$(json_field "$OUT" "hookSpecificOutput.permissionDecisionReason")"
case "$DECISION" in
  deny|ask) printf '{"decision":"%s","reason":%s}\n' "$DECISION" "$(json_string "$REASON")" ;;
  *) deny "m-skills adapter: ${GUARD} answered in a shape this adapter does not recognise." ;;
esac
exit 0
