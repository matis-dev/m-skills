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
#
# When agy changes — an argument renamed, so this cannot find what to check — the call
# goes through and a line naming the tool lands in ~/.claude/m-skills/guards.log. A host
# update is not the user's mistake, and denying would stop all their work until m-skills
# caught up. Only a fault in m-skills itself (an unknown guard name, an unreadable guard
# answer) still denies.

set -uo pipefail

# Usable before the JSON library loads, so it escapes by deletion rather than by engine.
deny() {
  printf '{"decision":"deny","reason":"%s"}\n' "$(printf '%s' "$1" | tr -d '"\\')"
  exit 0
}

# A broken install steps aside: the guards cannot run, and that is no reason to stop work.
DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

GUARD="${1:-}"
case "$GUARD" in
  guard-mutations.sh|guard-outward.sh|guard-secrets.sh) ;;
  *) deny "m-skills adapter: unknown guard '${GUARD}' in hooks.json." ;;
esac

# The cwd is the plugin directory, so this reaches only the global flag; the project
# flag resolves inside the guard, once workspacePaths has set CLAUDE_PROJECT_DIR.
m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

TOOL="$(json_field "$INPUT" "toolCall.name")"
case "$TOOL" in
  run_command)                  AS=Bash;  FIELD=command;   ARG="$(json_field "$INPUT" "toolCall.args.CommandLine")" ;;
  view_file)                    AS=Read;  FIELD=file_path; ARG="$(json_field "$INPUT" "toolCall.args.AbsolutePath")" ;;
  write_to_file)                AS=Write; FIELD=file_path; ARG="$(json_field "$INPUT" "toolCall.args.TargetFile")" ;;
  replace_file_content|multi_replace_file_content)
                                AS=Edit;  FIELD=file_path; ARG="$(json_field "$INPUT" "toolCall.args.TargetFile")" ;;
  *) exit 0 ;;
esac

# Empty means agy renamed the argument. The guards would read that as "nothing to
# check", so it is logged where the user can find it, then the call goes through.
if [ -z "$ARG" ]; then
  m_skills_guard_log "agy sent ${TOOL} without the argument the guards check; update scripts/antigravity-adapt.sh"
  exit 0
fi

WS="$(json_field "$INPUT" "workspacePaths.0")"
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
