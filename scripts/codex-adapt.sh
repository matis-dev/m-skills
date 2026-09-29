#!/usr/bin/env bash
# m-skills — run guard-secrets.sh over a Codex apply_patch, one path at a time.
#
# Usage, from the Codex build's hooks/hooks.json (matcher apply_patch):
#   bash "$PLUGIN_ROOT/scripts/codex-adapt.sh"
#
# Codex sends shell calls in Claude Code's own shape, so the three guards run on those
# unchanged. Only edits need translating: Codex has no Write or Edit, and names the files
# it touches inside patch text. Shapes captured from codex-cli 0.159.0 on 2026-09-29 (a
# logging hook in a scratch workspace), not taken from the docs:
#
#   in   {"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n
#          *** Update File: src/a.txt\n*** Move to: src/b.txt\n…*** End Patch"},
#         "session_id":…, "cwd":…}   — paths relative to cwd, which is also the hook's cwd
#   out  hookSpecificOutput.permissionDecision "deny" — Codex blocks the call and shows
#        the model the reason. No output = no opinion.
#
# Fails CLOSED, and never crashes: Codex runs the tool anyway when a hook exits non-zero
# (observed with exit 127). Every path the patch names is checked — a secret file hidden
# behind the first one, or reached by a Move to, still denies the whole patch. A header
# this script does not know is denied rather than skipped.

set -uo pipefail

# Usable before the JSON library loads, so it escapes by deletion rather than by engine.
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
    "$(printf '%s' "$1" | tr -d '"\\')"
  exit 0
}

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || deny "m-skills adapter: cannot locate its own directory, so this edit could not be checked."
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || deny "m-skills adapter: scripts/lib/hook-json.sh is missing, so this edit could not be checked."

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

[ -n "$M_SKILLS_JSON_ENGINE" ] \
  || deny "m-skills guard: neither jq nor python3 is available, so this edit could not be checked against the secret-file guard. Guards fail closed by design. Install jq or python3, or opt out with: touch .claude/.m-skills-no-guards"

[ "$(json_field "$INPUT" "tool_name")" = apply_patch ] || exit 0

PATCH="$(json_field "$INPUT" "tool_input.command")"
[ -n "$PATCH" ] || deny "m-skills adapter: apply_patch arrived without its patch text, so it could not be checked. Guards fail closed; if Codex renamed the argument, rebuild the plugin from an updated m-skills."

SESSION="$(json_string "$(json_field "$INPUT" "session_id")")"
PATHS=0
while IFS= read -r line; do
  line="${line%$'\r'}"
  case "$line" in
    '*** Begin Patch'*|'*** End Patch'*|'*** End of File'*) continue ;;
  esac
  [[ $line =~ ^[[:space:]]*\*\*\*[[:space:]]*(Add\ File|Update\ File|Delete\ File|Move\ to):[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] || {
    [[ $line =~ ^[[:space:]]*\*\*\*[[:space:]] ]] && deny "m-skills adapter: apply_patch carries a header this adapter does not know (${line:0:80}), so the files it touches could not be checked. Rebuild the plugin from an updated m-skills."
    continue
  }
  PATHS=$((PATHS + 1))
  OUT="$(printf '{"tool_name":"Write","tool_input":{"file_path":%s},"session_id":%s}' \
    "$(json_string "${BASH_REMATCH[2]}")" "$SESSION" | bash "$DIR/guard-secrets.sh" 2>/dev/null)"
  [ -z "$OUT" ] && continue
  case "$(json_field "$OUT" "hookSpecificOutput.permissionDecision")" in
    deny|ask) printf '%s\n' "$OUT"; exit 0 ;;
    *) deny "m-skills adapter: guard-secrets.sh answered in a shape this adapter does not recognise." ;;
  esac
done <<< "$PATCH"

[ "$PATHS" -gt 0 ] || deny "m-skills adapter: apply_patch names no file this adapter can find, so it could not be checked. Guards fail closed."
exit 0
