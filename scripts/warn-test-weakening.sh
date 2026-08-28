#!/usr/bin/env bash
# m-skills — PostToolUse advisory: a skip marker just appeared in a test file.
#
# The narrowest defensible slice of the pack's four never-weaken rules
# (testing-architect 5, debugging-architect 4, security-architect 3,
# maintenance-architect 5). Those rules only bind while their skill is loaded;
# adding `.skip` is exactly the shortcut taken when it isn't.
#
# Detects NEWLY INTRODUCED skip markers only, by counting them in old_string vs
# new_string. Deliberately does NOT try to spot deleted assertions or loosened
# tolerances — that needs semantic diffing, and a noisy advisory is one the reader
# learns to scroll past.
#
# Advisory, never a block in the fatal sense: the runtime feeds the reason back and
# the turn continues, so Claude either justifies the skip or reverts it.
#
# Silent outside test files. Respects .m-skills-no-guards. Fails OPEN.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0
advisory_require_json_engine

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

FILE="$(json_field "$INPUT" "tool_input.file_path")"
[ -z "$FILE" ] && exit 0

# The same test-file shapes profile-bootstrap.sh already detects.
printf '%s' "$FILE" | grep -Eq '\.(spec|test)\.[A-Za-z0-9]+$|(^|/)test_[^/]+\.py$|_test\.go$|_spec\.rb$|(^|/)(tests?|spec|__tests__)/' || exit 0

MARKERS='(describe|it|test|context|suite)\.(skip|only|todo)\(|\bx(it|describe|test|context)\(|@pytest\.mark\.(skip|skipif|xfail)|\bt\.Skip\(|#\[ignore\]|\.skip\(|\.only\('

count() { printf '%s' "$1" | grep -Eo "$MARKERS" 2>/dev/null | grep -c . ; }

OLD="$(json_field "$INPUT" "tool_input.old_string")"
NEW="$(json_field "$INPUT" "tool_input.new_string")"
# A Write has no old_string; its content is wholly new.
[ -z "$NEW" ] && NEW="$(json_field "$INPUT" "tool_input.content")"
[ -z "$NEW" ] && exit 0

BEFORE="$(count "$OLD")"
AFTER="$(count "$NEW")"
[ "$AFTER" -le "$BEFORE" ] 2>/dev/null && exit 0

ADDED="$(printf '%s' "$NEW" | grep -Eo "$MARKERS" | sort -u | tr '\n' ' ')"

emit_block "m-skills advisory — \`${FILE}\` gained a skip/only marker (${ADDED}).

Testing Architect constraint 5: never weaken a test to make it pass. Loosening a tolerance, deleting an assertion, adding a skip, or widening a mock to swallow the failure is a defect, not a fix — the same rule appears in debugging-architect 4, security-architect 3, and maintenance-architect 5.

If this is a deliberate, temporary quarantine: say so in one line, name what re-enables it, and keep it out of the \"gates green\" claim. If it is standing in for a fix, revert it and fix the cause instead. A \`.only\` in particular silently stops every other test in the file from running, which reads as green.

Advisory only — this hook cannot tell a legitimate quarantine from a shortcut."
