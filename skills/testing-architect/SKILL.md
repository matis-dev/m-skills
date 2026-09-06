---
name: testing-architect
description: Load when writing or reviewing unit, integration, end-to-end, visual, or accessibility tests. Owns layer selection, placement, naming, mocking discipline, coverage targets, security-regression TDD cases, the green-but-lying traps, and theme-matrix visual and a11y patterns. Frameworks and commands come from the Project Profile.
argument-hint: "[target area] [+ modifiers: make gates green | hold coverage]"
---

# Skill: Testing Architect — Test Strategy & Authoring

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Profile section owned:** §Conventions (test layers, placement, coverage bar) (Guidelines §5.1–§5.4). If the project has no tests yet, propose the layer set and placement, and record them once agreed.

---

## Operational Constraints (Strict — restated from Guidelines)

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open.
2. **Tests are part of the deliverable** (§11) — no "tests TBD", no merge-ready code without paired tests.
3. **Never weaken a test to make it pass.** Loosening a tolerance, deleting an assertion, adding a skip, or widening a mock to swallow the failure is a defect. Fix the code or surface the disagreement.

---

## 0. Resolve the Layers First

Read the profile and write down what actually exists here. Everything below applies to whichever of these the project has; a layer with no tooling is `n-a`, not a reason to invent one.

| Layer | Purpose | Resolved from profile |
|---|---|---|
| **Unit** | One unit's behavior, isolated at I/O boundaries | framework, command, file placement |
| **Integration** | Real collaborators wired together | framework, command |
| **E2E** | User-visible flows in a real runtime | framework, command, device/browser matrix |
| **Visual / golden** | Rendered output vs. approved baseline | command, tolerance, report path, **user-only** update command |
| **Accessibility** | Automated rule scan + keyboard traversal | command, rule tags, exclusions |
| **Static** | Types, lint | commands |

**Companion docs:** if the profile names a test-tooling doc or a suite-inventory doc, keep them in sync when strategy changes. This skill is the authoring procedure; those are the reference.

---

## 1. Unit Tests

### Placement & Naming
- Follow the project's existing convention (spec beside the source, or a mirrored `tests/` tree) — read a sibling test before creating a new file.
- One `describe` per public API; one test per observable behavior, named in plain English (`'sets the id and timestamp'`, never `'test1'` or `'should work'`).

### Setup Pattern
- Build the unit through the project's normal construction path (DI container, factory, framework test harness) so the graph mirrors runtime. Avoid hand-instantiating when the app doesn't.
- Provide **real** collaborators where the unit-under-test owns the contract; **mock only at I/O boundaries** — network, filesystem, database, clock, randomness, navigation.
- Never mock the unit's own helpers. That tests your mocks.

### What to Cover
- **Happy path** — the documented behavior.
- **Edge cases** — empty input, missing optional fields, boundary values (test *both* sides of every bound).
- **Error paths** — invalid input, rejection, validator failure, and what the user sees when it happens.
- **Security regression** — see §2. Only when the change actually reaches such a sink; most changes reach none, and saying so is a complete answer.
- **Coverage target:** the profile's bar (commonly 100% branch on new functions). If a branch is genuinely untestable (a defensive `never` return), justify it in one inline comment and move on.

### Anti-patterns to Reject
- Vague names that describe the code instead of the behavior.
- Real sleeps/`setTimeout` waits — use the framework's fake timers or an explicit completion signal.
- Assertions on implementation details (call counts of private helpers) instead of outcomes.
- Snapshot-serializing large objects in unit tests to avoid deciding what matters. Visual comparison is the visual layer's job.
- A test that passes whether or not the feature works. If deleting the implementation doesn't fail the test, the test is decoration.

---

## 2. Security-Regression Cases (TDD for the threat model)

> **What to test against comes from the `module-threat-model` skill** — its `references/regression-targets.md` lists the sinks worth a regression test and its §1 names the category. How the test is built, where it lives, and what it asserts is this skill's job. The pairing rule is one-directional: the test must **fail against the unpatched code**. A security test that passes before the fix is asserting the happy path with a scary name.

A finding from Code Review Architect's security pass is closed with a **failing-first test exercising the malicious input**, then the fix — not just a hardened line. Name the test by the attack, not by the fix.

This applies only when the change actually reaches such a sink; most changes reach none, and saying so is a complete answer. Keep these as ordinary tests in the project's existing framework. No new tooling.

## 3. Trusting a Green Run

A passing suite is evidence about the suite, not about the feature. The named failure modes — the fake-timer flush illusion, compiler-silenced fixtures, hand-maintained test doubles, gates with structural blind spots, a scan mistaken for accessibility, and a test that passes with the implementation deleted — live in the `module-gate-battery` skill §3. Check them by name before calling a green run proof of anything.

## 4. What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/e2e-visual.md` | Authoring an e2e or visual spec — helpers, selectors, screenshot naming, theme matrix. |
| `${CLAUDE_SKILL_DIR}/references/a11y-tests.md` | Authoring accessibility coverage — the two required layers and the triage order. |
| `${CLAUDE_SKILL_DIR}/references/test-plan-output.md` | Filling a plan's `Tests:` lines from `planning-architect`. |
| `module-threat-model` → `references/regression-targets.md` | A change reaches a security sink. |
| `module-gate-battery` | Running or trusting a green suite. |
| `module-operability-floor` | Asserting focus destination and announcement — the barriers no scan reports. |

---

## 5. Verification (when invoked from Implementing Architect)

Run the profile's gates per the `module-gate-battery` skill — its order, its one-batch rule, its result table. Then **manual** review by the user, then a manual smoke of the running app if the change is user-visible. Stay within the bounded-passes ceiling (Guidelines §16).

## Quality Checklist Before Claiming "Tests Done"

- [ ] Every new/changed public function has a spec covering happy, edge, and error paths.
- [ ] Any change reaching an import/deserialization, injection, consent, authz/IDOR, or path sink has a **failing-first security-regression** spec named by the attack — or is explicitly stated to reach none.
- [ ] Coverage meets the profile's bar on new code, or each gap has a one-line justification.
- [ ] Checked for the green-but-lying traps (§3): no fake-timer flush illusion, no compiler-silenced stale fixture, every test double updated for new methods, blind-spot gates verified past.
- [ ] Every UI-visible change has visual coverage in **all** themes across the relevant device/browser projects.
- [ ] Every UI-visible change has a11y coverage in all themes (rule scan + keyboard walk).
- [ ] Any new overlay, async status, or client-side route change asserts its focus destination and its announcement — the barriers no scan reports (`module-operability-floor` §2–§3).
- [ ] Visual specs use the project's helpers — no inline seeding, auth, consent, or theming.
- [ ] Selectors anchor on component tags or stable test attributes — never styling classes.
- [ ] No test was weakened (tolerance loosened, assertion deleted, skip added) to get green.
- [ ] No `git add`, `git commit`, `git push`, `git checkout`, or `--no-verify` was ever issued.
- [ ] If baselines failed, they are surfaced for manual review — **not** auto-updated.

---

## When to Use This Skill

- Cited by **Planning Architect** when filling the test columns of a plan.
- Cited by **Implementing Architect** when authoring or extending tests under an approved plan.
- Direct invocation: "Use Testing Architect" — to review or upgrade an existing area's suite without a fresh plan.

---

_v2.0 — version history in CHANGELOG.md_
