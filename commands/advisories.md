---
description: Triage and clear known security advisories by reachability — batched so a break is attributable, nothing bundled with a refactor.
argument-hint: "[optional: a package or advisory to scope to]"
---

Run `maintenance-architect` in **advisories only** mode. The scope is already chosen — handle known advisories, and do not expand into general upgrades or the rot sweep. Name in the output what you skipped.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/maintenance-architect/SKILL.md` — its constraints apply in full, Constraint 1 (never bundle an upgrade with a refactor) most of all.
2. Phase 1 inventory from the profile's `<audit>` gate output — read it, do not guess. Then Phase 2 triage.
3. Load `module-threat-model` §5 to triage each advisory by **reachability**, not by severity label alone. Load `module-gate-battery` between batches, `module-handover` for the revert and lockfile-rollback commands, and `guidelines-meta`.
4. Read `${CLAUDE_PLUGIN_ROOT}/skills/maintenance-architect/references/report-format.md` when assembling the output.

Establish a green baseline **before** any upgrade — Constraint 3. One batch, one class, one revert. A deliberate non-upgrade gets recorded in the profile with its reason.

Scope: $ARGUMENTS
