#!/usr/bin/env bash
# m-skills — apply the Reply Protocol (guidelines-meta §17) to every response, not only
# to turns where a pack skill is running.
#
# §17 is influence, not a command: there is no skill to invoke. This hook is how the same
# rules reach ordinary conversation. It fires on startup, resume, clear, and compact —
# a context clear is where a session-only setting lapses unnoticed, which is the
# working-memory tax §17 exists to remove.
#
# Opt-in is a flag file the user creates. No flag → silent exit, zero cost.
#   global : $CLAUDE_CONFIG_DIR/.m-skills-adhd-always  (default ~/.claude)
#   project: .claude/.m-skills-adhd-on
#
# Output contract: plain-text stdout becomes Claude's context. First character must not be
# '{' or the runtime parses it as a JSON directive. Never blocks: always exit 0.

set -uo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# $0 is the absolute script path, so resolve the skill relative to it rather than
# trusting CLAUDE_PLUGIN_ROOT to be exported into the hook environment.
PLUGIN="$(cd "$(dirname -- "$0")/.." 2>/dev/null && pwd)" || exit 0

GLOBAL_FLAG="$CONFIG_DIR/.m-skills-adhd-always"
PROJECT_FLAG="$PROJECT/.claude/.m-skills-adhd-on"

SCOPE=""
[ -f "$GLOBAL_FLAG" ]  && SCOPE="all projects — $GLOBAL_FLAG"
[ -f "$PROJECT_FLAG" ] && SCOPE="this project — $PROJECT_FLAG"
[ -z "$SCOPE" ] && exit 0

GUIDELINES="$PLUGIN/skills/guidelines-meta/SKILL.md"
[ -f "$GUIDELINES" ] || exit 0

# Extract §17 only: from its heading up to (not including) the next same-level heading.
SECTION="$(awk '
  /^### 17\./            { grabbing = 1 }
  grabbing && /^### 18\./ { exit }
  grabbing               { print }
' "$GUIDELINES")" || exit 0
[ -z "$SECTION" ] && exit 0

printf 'REPLY PROTOCOL ACTIVE (%s). This applies to every response this session, including work that never touches an m-skills skill.\n' "$SCOPE"
printf 'The user saying "stop adhd mode" turns it off for this session only; deleting the flag file turns it off for good.\n\n'
printf '%s\n' "$SECTION"
exit 0
