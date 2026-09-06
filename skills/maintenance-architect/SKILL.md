---
name: maintenance-architect
description: Use for dependency upgrades, security advisories, deprecations, lockfile hygiene, and the rot sweep (suppressions, skipped tests, dead code, stale docs). Triages by reachability, batches upgrades so a break is attributable, records deliberate non-upgrades in the profile. Never bundles an upgrade with a refactor.
argument-hint: "[+ modifiers: advisories only | upgrades | rot sweep | prepare only]"
disable-model-invocation: true
---

# Skill: Maintenance Architect — Dependency Health & Rot Control

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Profile section owned:** §Guardrails → do-not-touch and pinned-dependency rationale (Guidelines §5). Every deliberate *non*-upgrade gets recorded with its reason, so nobody re-litigates it in six months.


**Why this skill exists:** maintenance is the work that is never urgent until it is catastrophic. It falls between building and shipping, so it belongs to nobody and happens never — until a security advisory lands on a dependency four majors behind, and the upgrade that should have taken an afternoon takes a week. This skill makes it a routine with a defined scope instead of an emergency.

---

## Operational Constraints (Strict)

1. **Never bundle an upgrade with a refactor.** The single most valuable rule here. If an upgrade needs code changes, the upgrade is one change and the adaptation is a *separate* one where possible. Mixed diffs make `git bisect` useless and turn a five-minute revert into an archaeology session.
2. **One batch, one class, one revert.** Each batch must be revertible on its own (§Batching). A batch you cannot undo in one step is too big.
3. **Green before, green after — with the same gates.** Establish a passing baseline *first*. Upgrading on top of an already-failing suite means you cannot attribute the failure, and you will blame the upgrade.
4. **Never upgrade to silence a warning you haven't read.** Deprecation warnings name a migration path. Read it. Bumping the version to make the message go away, without following the migration, defers the break to a worse moment.
5. **Never weaken to pass.** Not a suppression, not a skip, not a pinned-back transitive to dodge a real incompatibility (Testing Architect constraint 3). A suppression added during maintenance is rot created by rot-control.
6. **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open. Lockfile changes stay unstaged. **The lockfile is the rollback** — surface `git checkout <lockfile>` as a command per `module-handover` §4; the hook denies it if you run it yourself.
7. **An upgrade is a deploy.** Anything that reaches production goes through the `deployment-architect` skill. A dependency bump is a production change wearing a smaller hat.
8. **Bounded** (Guidelines §16). One inventory pass, one batch of changes, one verification round per batch. Not an open loop of nudging versions until CI turns green.

---

## What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/rot-sweep.md` | Phase 5 — the findings no gate reports because nothing fails. |
| `${CLAUDE_SKILL_DIR}/references/report-format.md` | Assembling the output. |
| `module-threat-model` → `references/triage.md` | Triaging an advisory by reachability. |
| `module-gate-battery` | Between batches, and for the visual-diff stop. |
| `module-handover` | The revert command, the lockfile rollback. |

---

## Phase 1 — Inventory

Read, don't guess. Resolve `<audit>` and the rest from the profile.

| Source | What it tells you |
|---|---|
| `<audit>` output | Known advisories, with severity and whether a fix exists |
| The manifest vs. the registry (`outdated` equivalent) | How far behind, and whether the gap is patch / minor / major |
| Build and test output | Deprecation warnings — the pre-announcement of tomorrow's break |
| Lockfile | Duplicate versions of the same package, and unexpected transitives |
| Runtime/engine constraints | An LTS going end-of-life is a deadline with a date |
| The profile's pinned list | What is deliberately held back, and why |

**Distinguish direct from transitive.** A transitive advisory is usually fixed by upgrading the parent, not by pinning the child — an override is a last resort that must be recorded with an expiry condition.

---

## Phase 2 — Triage by Urgency, Not by Version Number

"Behind" is not a problem in itself. A stable dependency four minors behind, doing its job, is fine. Sort by consequence:

| Tier | What qualifies | Action |
|---|---|---|
| **Now** | An advisory that is *actually reachable* in this codebase — the vulnerable function is called, on a path that handles untrusted input | Fix immediately, alone, and ship it alone |
| **Soon** | Advisory with no reachable path · runtime nearing end-of-life · a deprecation with an announced removal date | Schedule it; do it while it is still cheap |
| **Routine** | Patch and minor bumps, tooling, types | Batch it (§3) |
| **Deliberate hold** | Breaking major with no benefit here · a rewrite in disguise · a dependency being removed anyway | **Record the reason in the profile** and stop re-examining it |

**Reachability is the honest question** for advisories (`module-threat-model` → `references/triage.md`), and it takes minutes to answer. "Critical" on a package used only by a build script that never sees untrusted input is not a production emergency — say so plainly rather than performing urgency. Equally, a "moderate" on a parser fed by user uploads deserves the Now tier. **Never inflate a rating to look diligent, and never downgrade one to avoid work** (Guidelines §15).

---

## Phase 3 — Batch So a Break Is Attributable

Order matters — cheapest-to-verify and least-coupled first:

1. **Types and dev-only tooling** — cannot reach production; break loudly at build time.
2. **Patch versions of direct dependencies** — one batch, all together.
3. **Minor versions of direct dependencies** — one batch, or split by subsystem if the surface is wide.
4. **Each major, individually.** Never two majors in one batch. Never a major alongside anything else.
5. **Framework or runtime majors — their own change entirely**, with their own plan via the `planning-architect` skill. These are projects, not chores, and calling one a "bump" is how a week disappears.

Between every batch: run the gates (`module-gate-battery`). A batch that breaks something is **reverted, not debugged in place** — restore the lockfile, then split the batch and retry the halves. That is bisection, and it beats staring at a diff of forty version numbers.

---

## Phase 4 — Verify Beyond Green

Gates prove the code compiles and the tests still pass. Upgrades break things gates do not watch:

- **Read the changelog for anything with a behaviour change**, not just a version diff. Silent behaviour changes in a patch release are common and are exactly what tests written before them will not catch.
- **Bundle or artifact size** — a dependency that doubled is a finding.
- **The peer/engine graph** — an unmet peer that resolves today but warns is tomorrow's break.
- **Anything with a native or platform build step** — verify on the target, not only locally.
- **Visual and golden tests** for anything touching rendering (`module-craft-floor`, `testing-architect`). A styling dependency's minor bump moves pixels; that diff is surfaced and reviewed manually like any other (`module-gate-battery` §4).
- **Lockfile churn** — an unexpectedly large diff for a small bump means something transitive moved. Look before shipping.

---

## Phase 5 — The Rot Sweep

The findings no gate reports, because nothing fails: suppressions, permanently-skipped tests masquerading as coverage, unused dependencies, dead code, stale TODOs, doc drift, config drift, duplicate transitives.

**Read `${CLAUDE_SKILL_DIR}/references/rot-sweep.md`.** Run it periodically, report per `module-findings`, and **fix only what the user approves** — this phase generates a list, not a rewrite.

---

## Cadence

Maintenance done on a schedule stays small; done on discovery, it is always an emergency.

- **Every change set:** the `<audit>` gate already runs — do not ignore its output because it isn't today's task.
- **Weekly-ish:** patch and dev-tooling batch. Ten minutes.
- **Monthly-ish:** minors, deprecation warnings, and the rot sweep.
- **Quarterly-ish:** majors, one at a time, each with its own plan.
- **Immediately:** a reachable advisory. Alone, shipped alone.

*(To automate the reminder rather than remember it, the `/loop` and `/schedule` commands can run this skill on an interval.)*

---

## Quality Checklist Before Claiming "Maintained"

- [ ] Inventory read from real output — advisory counts and versions never estimated (Guidelines §15).
- [ ] Advisories triaged by **reachability**, not by their headline severity; the reasoning is stated.
- [ ] Green baseline established **before** any change.
- [ ] Batches are single-class and independently revertible; no two majors together.
- [ ] No upgrade bundled with a refactor.
- [ ] Changelogs read for anything with a behaviour change — not just version numbers compared.
- [ ] Bundle/artifact size and lockfile churn checked.
- [ ] Visual diffs from styling dependencies surfaced for manual review, never auto-accepted.
- [ ] Nothing suppressed, skipped, or pinned back to force a pass.
- [ ] Deliberate holds recorded in the profile with a reason and a revisit condition.
- [ ] Rot sweep reported as findings; nothing deleted without approval.
- [ ] **No `git add`, `commit`, or `push`** — lockfile changes left unstaged for the user.

---

_v1.0 — version history in CHANGELOG.md_
