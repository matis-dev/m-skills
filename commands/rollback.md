---
description: Something is broken in production — restore first, resolve the rollback command, then investigate.
argument-hint: "[the symptom, and the environment]"
---

Run `deployment-architect` in **Rollback** mode. Go straight to it — skip Phase 0 through Phase 6 entirely. The readiness gate is irrelevant when something is already broken.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/deployment-architect/SKILL.md` and go to its **Rollback Mode** section.
2. Load `module-handover` §4 for the copy-ready command shape, and `guidelines-meta`.

The order is fixed and this command does not change it: state the symptom in one line → hand over the resolved rollback command → verify recovery with the health check and critical path → name what rollback did **not** undo → **only then** investigate cause.

**You do not run it.** A rollback is a production write, so it is the user's to fire under Constraint 2, and `guard-outward.sh` denies it at the runtime regardless. Speed comes from the command already being correct, not from you typing it.

Symptom: $ARGUMENTS

If no symptom was given, ask what is broken and in which environment — one question, then straight to the command.
