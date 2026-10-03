---
description: Write a durable product requirements document — scope, non-goals, and requirements nobody has to re-derive.
argument-hint: "[the product or feature the PRD covers]"
---

Run `product-architect` in **prd** mode. The mode is already chosen — do not re-open the mode question, and do not offer `decompose`, `deep-dive`, `brief`, or `research`.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/product-architect/SKILL.md` — its constraints, guardrails, and gate sweep apply in full. Constraint 1 (every number sourced or labelled) is the load-bearing one here.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/product-architect/references/prd.md` and nothing else from that `references/` directory.
3. Load the `guidelines-meta` and `module-writing-floor` skills as that file directs.

One thing this command does not skip: the skill's judgement about whether the work genuinely needs a PRD. If it does not, say so in one line before writing it.

Target: $ARGUMENTS

If no target was given, ask what the PRD is for.
