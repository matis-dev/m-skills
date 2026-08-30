---
description: Cut an approved plan or an oversized feature into vertical, independently shippable slices.
argument-hint: "[the plan, story, or feature to slice]"
---

Run `product-architect` in **decompose** mode. The mode is already chosen — do not re-open the mode question, and do not offer `deep-dive`, `prd`, `brief`, or `research`.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/product-architect/SKILL.md` — its constraints, guardrails, and gate sweep apply in full.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/product-architect/references/decompose.md` and nothing else from that `references/` directory.
3. Load the `guidelines-meta` and `module-writing-floor` skills as that file directs.

This command narrows the route, not the discipline: every constraint still applies, the git guards still bite, and nothing here is a `skip gates` modifier.

Target: $ARGUMENTS

If no target was given, ask which plan or feature to slice — that is the one question this command still needs answered.
