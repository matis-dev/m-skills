#!/usr/bin/env bash
# m-skills — point a fresh or compacted context at an unfinished implementing-architect run.
#
# implementing-architect keeps .claude/PROGRESS.md on any plan of three or more steps and
# deletes it once the summary is emitted, so the file existing means a run did not finish.
# Compaction and /clear drop the conversation that knew about it; this hook is what makes
# the next stretch of work read the handoff instead of re-deriving it.
#
# Silent when the file is absent. Fires on startup, resume, clear, and compact.
#
# Output contract: plain-text stdout becomes Claude's context. First character must not be
# '{' or the runtime parses it as a JSON directive. Never blocks: always exit 0.

set -uo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
PROGRESS="$PROJECT/.claude/PROGRESS.md"
[ -s "$PROGRESS" ] || exit 0

UPDATED="$(date -r "$PROGRESS" '+%Y-%m-%d %H:%M' 2>/dev/null || echo unknown)"

printf 'UNFINISHED RUN: .claude/PROGRESS.md exists (last updated %s).\n' "$UPDATED"
printf 'An implementing-architect run stopped before its summary. Read the file before anything\n'
printf 'else, then resume at the step its handoff names. If the user has moved on to other work,\n'
printf 'ask with AskUserQuestion whether to resume the run or discard the file — never delete it unasked.\n'
exit 0
