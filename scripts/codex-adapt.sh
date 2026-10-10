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
# Never crashes: Codex runs the tool anyway when a hook exits non-zero (observed with
# exit 127). Every path the patch names is checked — a secret file hidden behind the
# first one, or reached by a Move to, still denies the whole patch.
#
# When Codex changes — no patch text, or a header this script does not know — the
# known paths are still checked, the rest goes through, and a line naming what was
# unreadable lands in ~/.claude/m-skills/guards.log. A host update is not the user's
# mistake, and denying would stop all their edits until m-skills caught up.

set -uo pipefail

# Usable before the JSON library loads, so it escapes by deletion rather than by engine.
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
    "$(printf '%s' "$1" | tr -d '"\\')"
  exit 0
}

# A broken install steps aside: the guard cannot run, and that is no reason to stop work.
DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

[ "$(json_field "$INPUT" "tool_name")" = apply_patch ] || exit 0

PATCH="$(json_field "$INPUT" "tool_input.command")"
if [ -z "$PATCH" ]; then
  m_skills_guard_log "Codex sent apply_patch without its patch text; update scripts/codex-adapt.sh"
  exit 0
fi

SESSION="$(json_string "$(json_field "$INPUT" "session_id")")"
PATHS=0
while IFS= read -r line; do
  line="${line%$'\r'}"
  case "$line" in
    '*** Begin Patch'*|'*** End Patch'*|'*** End of File'*) continue ;;
  esac
  [[ $line =~ ^[[:space:]]*\*\*\*[[:space:]]*(Add\ File|Update\ File|Delete\ File|Move\ to):[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] || {
    if [[ $line =~ ^[[:space:]]*\*\*\*[[:space:]]*([A-Za-z][A-Za-z ]*): ]]; then
      m_skills_guard_log "apply_patch header '${BASH_REMATCH[1]}' is unknown, its file went unchecked; update scripts/codex-adapt.sh"
    elif [[ $line =~ ^[[:space:]]*\*\*\*[[:space:]] ]]; then
      m_skills_guard_log "apply_patch carries an unnamed header, its file went unchecked; update scripts/codex-adapt.sh"
    fi
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

[ "$PATHS" -gt 0 ] || m_skills_guard_log "apply_patch named no file this adapter can find; update scripts/codex-adapt.sh"
exit 0
