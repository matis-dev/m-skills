---
name: testing-architect
description: How tests are designed, placed, and authored — the single source of truth for test strategy. Use when writing or reviewing unit specs, integration tests, end-to-end and visual specs, or accessibility specs. Covers layer selection, naming, setup and mocking discipline, coverage targets, security-regression TDD cases for the review threat model, the green-but-lying traps (fake-timer flush failures, compiler-silenced fixtures, blind-spot gates), and visual and a11y authoring patterns across every theme the project ships. Stack-agnostic — resolves frameworks, commands, and helpers from the Project Profile. Cited by planning-architect and implementing-architect.
argument-hint: "[target area] [+ modifiers: make gates green | hold coverage]"
---

# Skill: Testing Architect — Test Strategy & Authoring

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("tests later", "skip gates", "fix the findings", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Conventions (test layers, placement, coverage bar) (Guidelines §5). Fill it on first use per **Guidelines §5.1–§5.4** — read the repo first, ask only what the code cannot say, write it back. If the project has no tests yet, propose the layer set and placement, and record them once agreed.

**Role:** Test Strategist & Author.
**Purpose:** Single source of truth for **how** tests are designed, placed, written, and verified. Cited by Planning Architect (for test-planning sections) and Implementing Architect (for actually writing them).
**Trigger:** "Use Testing Architect" — or by reference from another skill needing test strategy.
**Portability:** The procedure is universal. Frameworks, commands, helper paths, and theme names come from the **Project Profile** (Guidelines §5) — read it before writing a single spec, and match the project's existing specs rather than importing another project's style.

---

## Operational Constraints (Strict — restated from Guidelines)

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). Any git command that writes — and any `gh` command that publishes — is **denied by the runtime**, as is `--no-verify` and any snapshot-update command. Read-only inspection stays open. Files stay unstaged and visual diffs stay the user's to review.
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

> **What to test against comes from the `module-threat-model` skill** — its §6 lists the sinks worth a regression test and its §1 names the category. How the test is built, where it lives, and what it asserts is this skill's job. The pairing rule is one-directional: the test must **fail against the unpatched code**. A security test that passes before the fix is asserting the happy path with a scary name.

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
| `module-threat-model` §6 | A change reaches a security sink. |
| `module-gate-battery` | Running or trusting a green suite. |
| `module-operability-floor` | Asserting focus destination and announcement — the barriers no scan reports. |

---

## 7. Verification (when invoked from Implementing Architect)

Run the profile's gates per the `module-gate-battery` skill — its order, its one-batch rule, its result table. Then **manual** review by the user, then a manual smoke of the running app if the change is user-visible. Stay within the bounded-passes ceiling (Guidelines §16).

## Quality Checklist Before Claiming "Tests Done"

- [ ] Every new/changed public function has a spec covering happy, edge, and error paths.
- [ ] Any change reaching an import/deserialization, injection, consent, authz/IDOR, or path sink has a **failing-first security-regression** spec named by the attack — or is explicitly stated to reach none.
- [ ] Coverage meets the profile's bar on new code, or each gap has a one-line justification.
- [ ] Checked for the green-but-lying traps (§3): no fake-timer flush illusion, no compiler-silenced stale fixture, every test double updated for new methods, blind-spot gates verified past.
- [ ] Every UI-visible change has visual coverage in **all** themes across the relevant device/browser projects.
- [ ] Every UI-visible change has a11y coverage in all themes (rule scan + keyboard walk).
- [ ] Any new overlay, async status, or client-side route change asserts its focus destination and its announcement — the barriers no scan reports (`accessibility-architect` §3).
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

_Skill Version: v2.0 — Genericized: §0 resolves layers, frameworks, commands, helper paths, and theme names from the Project Profile instead of hardcoding one project's stack; visual/a11y sections restated framework-agnostically ("all themes the project ships", "the project's a11y engine"). §3 promotes the green-but-lying traps to their own section and generalizes them — the fake-timer/construction-time-subscription trap now reads as a scheduler-scope rule rather than one framework's gotcha, joined by compiler-silenced fixtures, hand-maintained test doubles, gates with blind spots, and the limits of automated a11y scans. Adds constraint 3 (never weaken a test to get green), the "would deleting the implementation fail this test?" check, an integration layer, and a Design Architect cross-reference for the a11y items scans miss. Prior v1.3 — companion tooling docs; v1.2 — security-regression TDD cases; v1.1 — zoneless fakeAsync trap_
