#!/usr/bin/env bash
# m-skills — inject the shared preamble when a pack skill starts.
#
# Claude Code 2.1.158 has no skill-load event (InstructionsLoaded is for CLAUDE.md
# memory files, memory_type User|Project|Local|Managed — not skills). This covers
# both invocation paths instead:
#
#   UserPromptExpansion  → the user typed /m-skills:<name>. Covers the 10 skills
#                          with disable-model-invocation: true. Emits additionalContext.
#   PostToolUse (Skill)  → the model invoked an auto-loadable knowledge skill
#                          (design, testing, security, accessibility, documentation).
#                          Emits decision:block + reason, which the runtime feeds
#                          back to Claude while the turn continues.
#
# What it injects, deterministically, so sixteen skill files stop re-deriving it:
#   1. the gate table resolved by check-quality.sh --list
#   2. guidelines-meta §9, §10, §15, §19, read live from the skill file
#
# Silent for any skill outside this pack. Advisory: fails OPEN.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

# UserPromptExpansion is registered with no matcher, so this fires on EVERY user
# prompt. Decide "not mine" with a shell builtin before spending a jq/python3
# spawn on it — an ordinary message must cost nothing.
case "$INPUT" in *m-skills:*) ;; *) exit 0 ;; esac

advisory_require_json_engine

EVENT="$(json_field "$INPUT" "hook_event_name")"

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

# guidelines-meta is the source of the preamble; injecting it into itself is noise.
[ "$SKILL" = "guidelines-meta" ] && exit 0

GUIDELINES="$DIR/../skills/guidelines-meta/SKILL.md"
[ -f "$GUIDELINES" ] || exit 0

# Once per skill per session. A skill invoked through the Skill tool AND its slash
# command satisfies both arms below, which injected the same ~40 lines twice; the
# marker makes that impossible and also stops a re-invocation repeating it.
# Same idiom as advise-propagation.sh.
#
# Trade-off, stated because it is real: after a context compaction the preamble is
# gone and will not re-fire for an already-marked skill. Acceptable — §9 and §10 are
# enforced by guard-mutations.sh whether or not Claude remembers them, and the gate
# table is re-derivable with `check-quality.sh --list`.
MARK="$(m_skills_state_dir)/preamble/$SKILL"
[ -f "$MARK" ] && exit 0
mkdir -p "$(dirname "$MARK")" 2>/dev/null || exit 0
: > "$MARK" 2>/dev/null || exit 0

# Extract one numbered section: its heading through to the next heading or rule.
section() {
  awk -v n="$1" '
    $0 ~ "^### " n "\\." { grabbing = 1 }
    grabbing && NR > start && (/^### /  && $0 !~ "^### " n "\\.") { exit }
    grabbing && /^## / { exit }
    grabbing && /^---$/ { exit }
    grabbing { print; start = NR }
  ' "$GUIDELINES"
}

# The resolved gates, cached per session — the resolution spawns node.
gates() {
  local state cache root
  root="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}")"
  state="$(m_skills_state_dir)"
  cache="$state/gates-$(m_skills_gate_cache_key "$root")"
  if [ -f "$cache" ]; then cat "$cache"; return 0; fi
  mkdir -p "$state" 2>/dev/null || return 1
  (cd "$root" 2>/dev/null && bash "$DIR/../skills/implementing-architect/check-quality.sh" --list 2>/dev/null) \
    | tee "$cache" 2>/dev/null
}

GATES="$(gates)"
[ -z "$GATES" ] && GATES="  (gate resolution unavailable — resolve from the Project Profile per Guidelines §5)"

BODY="$(cat <<EOF
m-skills preamble for \`${SKILL}\` — injected by the plugin's hook, not by the model.

## Resolved gates for this project (Guidelines §5)

Use these verbatim. Do not re-derive them, and never invent a command that is not listed.

\`\`\`
${GATES}
\`\`\`

A role showing \`n-a\` has no gate in this project — say so and move on (Guidelines §5.3).

## Enforced, not advisory

§9 and §10 below are enforced by the plugin's PreToolUse hook. A git mutation or a
snapshot-update command will be **denied by the runtime**, not merely discouraged.
They are restated here so you know why before you reach for one.

$(section 9)
$(section 10)

## Still on you — no hook can check these

$(section 15)
$(section 19)
EOF
)"

case "$EVENT" in
  UserPromptExpansion) emit_context "UserPromptExpansion" "$BODY" ;;
  PostToolUse)         emit_block "$BODY" ;;
esac
