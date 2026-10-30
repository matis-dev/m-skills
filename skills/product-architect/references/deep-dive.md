# Reference: Mode: deep-dive

*`product-architect` reference — read when the run needs it.*

## Mode: `deep-dive` — Refine One Feature Into Milestones

For a feature that is understood but not yet shaped. Lighter than a PRD, more than a plan.

1. **Pattern check** — how this class of feature is normally built, and which conventions users already expect. Anything cited as an industry pattern is either something you can point to or is labelled an assumption.
2. **Refine the scope** — say what in the original idea is bloat and what is missing. Agreeing is not the job (`brainstorming-planner` guardrail); a tighter version is the deliverable.
3. **Name the hidden complexity** — the three technical risks that decide whether this is a week or a month: shared state, real-time behaviour, permissions, migration, third-party limits.
4. **Three milestones** — walking skeleton, then the real experience (validation, errors, the grey paths), then scale and delight. Each milestone is a `decompose` input, not a ticket.

---
