#!/usr/bin/env bash
# m-skills — offer the gated pipeline skills instead of leaving them invisible.
#
# Eleven skills carry disable-model-invocation: true, so they never appear in the
# model's skill roster. "Please implement the plan" therefore gets ordinary default
# behaviour — no gate battery, no propagation sweep — and nothing tells the user that
# implementing-architect existed. The flag is right: a casual remark must never start
# a code-writing process. The silence is not. This hook injects the roster plus the
# instruction to *ask*, so the gate stays exactly as strict and only the recall
# burden goes away.
#
# On by default — the people this serves are the ones who never read the README.
# Opt out with a flag file, the same convention the PreToolUse guards use:
#   project: .claude/.m-skills-no-suggest
#   global : $CLAUDE_CONFIG_DIR/.m-skills-no-suggest  (default ~/.claude)
#
# The roster is derived from the skill files on each run rather than hardcoded, so a
# twelfth gated skill appears here the day it is added and cannot drift out of step.
#
# Output contract: plain-text stdout becomes Claude's context. First character must not be
# '{' or the runtime parses it as a JSON directive. Never blocks: always exit 0.

set -uo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# $0 is the absolute script path, so resolve the skills relative to it rather than
# trusting CLAUDE_PLUGIN_ROOT to be exported into the hook environment.
PLUGIN="$(cd "$(dirname -- "$0")/.." 2>/dev/null && pwd)" || exit 0

[ -f "$CONFIG_DIR/.m-skills-no-suggest" ] && exit 0
[ -f "$PROJECT/.claude/.m-skills-no-suggest" ] && exit 0

SKILLS="$PLUGIN/skills"
[ -d "$SKILLS" ] || exit 0

# name + the first sentence of description, for every skill the model cannot reach on
# its own. Frontmatter only, so a "name:" further down a skill body can't leak in.
ROSTER="$(
  for f in "$SKILLS"/*/SKILL.md; do
    [ -f "$f" ] || continue
    awk '
      NR == 1 && $0 == "---" { fm = 1; next }
      fm && $0 == "---"      { exit }
      !fm                    { exit }
      /^name:/               { sub(/^name:[ \t]*/, "");        n = $0 }
      /^description:/        { sub(/^description:[ \t]*/, ""); d = $0 }
      /^disable-model-invocation:[ \t]*true[ \t]*$/ { gated = 1 }
      END {
        if (!gated || n == "" || d == "") exit
        # Cut at ". " rather than "." so version numbers like 2.2 survive intact.
        i = index(d, ". ")
        if (i > 0) d = substr(d, 1, i)
        # Long first sentences get trimmed at a word boundary — a roster this is read
        # for intent-matching is worth less when it ends mid-word.
        if (length(d) > 150) {
          d = substr(d, 1, 147)
          if (match(d, /[ ][^ ]*$/)) d = substr(d, 1, RSTART - 1)
          d = d " …"
        }
        printf "  %s — %s\n", n, d
      }
    ' "$f" 2>/dev/null
  done | sort
)"

[ -z "$ROSTER" ] && exit 0

printf 'SKILL SUGGESTIONS ACTIVE. The m-skills pipeline skills below are gated with\n'
printf 'disable-model-invocation, so they are absent from your skill roster and you cannot\n'
printf 'start one on your own:\n\n'
printf '%s\n' "$ROSTER"
printf '\nWhen a message clearly matches one and does not name it, ASK. Do not silently fall\n'
printf 'back to default behaviour, and do not invoke anything unasked.\n\n'
printf 'Obvious single match — confirm, three options:\n'
printf '  "This looks like a <skill> job — <what it would do>. Run it?"\n'
printf '  [Yes — run <skill>] [No — a different skill] [No — just continue]\n\n'
printf 'Genuinely ambiguous — one option per candidate plus the decline, four max:\n'
printf '  [<skill-a> — <the angle it takes>] [<skill-b> — <its angle>] [No — just continue]\n\n'
printf 'On "yes": invoke the skill if the runtime allows it. If the gate refuses a model-side\n'
printf 'invocation, hand over the exact line to paste — /m-skills:<name> — and say that is why.\n'
printf 'The flow never dead-ends on a yes.\n\n'
printf 'Do not ask on small talk, a one-line tweak, or a turn where a skill is already running.\n'
printf 'Never re-ask a match the user already declined this session.\n\n'
printf 'Turning it off: the user saying "stop suggesting" ends it for this session; the file\n'
printf '.claude/.m-skills-no-suggest ends it for this project, and the same name in\n'
printf '%s ends it everywhere.\n' "$CONFIG_DIR"
exit 0
