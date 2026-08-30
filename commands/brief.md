---
description: Write a one-page product brief — the north star, the anti-goals, and nothing else.
argument-hint: "[the product or idea the brief covers]"
---

Run `product-architect` in **brief** mode. The mode is already chosen — do not re-open the mode question, and do not offer `decompose`, `deep-dive`, `prd`, or `research`.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/product-architect/SKILL.md` — its constraints, guardrails, and gate sweep apply in full.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/product-architect/references/brief.md` and nothing else from that `references/` directory.
3. Load the `guidelines-meta` and `module-writing-floor` skills as that file directs.

Guardrail 5 is the one this command is most likely to trip: a brief that grows into a PRD has failed. One page, north star, anti-goals.

Target: $ARGUMENTS

If no target was given, ask what the brief is for.
