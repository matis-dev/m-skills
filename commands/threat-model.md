---
description: Map the trust boundaries of a feature before it is built — what it newly accepts, what it newly grants.
argument-hint: "[the feature, endpoint, or plan to model]"
---

Run `security-architect` in **model** mode. The mode is already chosen — do not re-open the mode question, and do not drift into `harden`, `remediate`, or `triage`.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/security-architect/SKILL.md` — its constraints and guardrails apply in full.
2. Load the `module-threat-model` skill and read its `references/trust-boundaries.md`, plus its §1 for the categories actually in play. Read nothing else from that module.
3. Load the `guidelines-meta` skill.

This mode is **read-only**. It produces the trust-boundary map and the per-step `[SEC]` notes `planning-architect` carries into a plan — not a fix. "It crosses no trust boundary" is a valid and complete outcome; say it plainly rather than manufacturing findings.

Target: $ARGUMENTS

If no target was given, ask which feature or endpoint to model.
