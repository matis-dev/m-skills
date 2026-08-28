---
name: testing-architect
description: How tests are designed, placed, and authored — the single source of truth for test strategy. Use when writing or reviewing unit specs, integration tests, end-to-end and visual specs, or accessibility specs. Covers layer selection, naming, setup and mocking discipline, coverage targets, security-regression TDD cases for the review threat model, the green-but-lying traps (fake-timer flush failures, compiler-silenced fixtures, blind-spot gates), and visual and a11y authoring patterns across every theme the project ships. Stack-agnostic — resolves frameworks, commands, and helpers from the Project Profile. Cited by planning-architect and implementing-architect.
argument-hint: "[target area] [+ modifiers: make gates green | hold coverage]"
---

# Skill: Testing Architect — Test Strategy & Authoring

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("tests later", "skip gates", "fix the findings", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Conventions (test layers, placement, coverage bar) (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo for the answers first** — then ask at most 3–4 questions covering only what the code cannot say, and write it back. A question the repo already answers is a defect (Guidelines §5.3); so is deferring a row whose answer sits in a file you didn't open. If the project has no tests yet, propose the layer set and placement, and record them once agreed.

**Role:** Test Strategist & Author.
**Purpose:** Single source of truth for **how** tests are designed, placed, written, and verified. Cited by Planning Architect (for test-planning sections) and Implementing Architect (for actually writing them).
**Trigger:** "Use Testing Architect" — or by reference from another skill needing test strategy.
**Portability:** The procedure is universal. Frameworks, commands, helper paths, and theme names come from the **Project Profile** (Guidelines §5) — read it before writing a single spec, and match the project's existing specs rather than importing another project's style.

---

## Operational Constraints (Strict — restated from Guidelines)

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). A `git add` / `commit` / `push` / branch operation, a `--no-verify`, or a snapshot-update command is **denied by the runtime**. Files stay unstaged and visual diffs stay the user's to review.
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

> **What to test against comes from the `security-architect` skill** (§1 categories, §2 trust boundaries); how the test is built and where it lives is this skill's job. A fix it writes is paired here, and the pairing rule is one-directional: the test must **fail against the unpatched code**. A security test that passes before the fix is asserting the happy path with a scary name.

A finding from Code Review Architect's security pass is closed with a **failing-first test exercising the malicious input**, then the fix — not just a hardened line. Name the test by the attack, not by the fix.

The sinks worth a regression test, whenever a change reaches one:

- **Untrusted deserialization / import** — feed a payload carrying prototype-polluting keys (`__proto__`, `constructor.prototype`) or unexpected shape through the real import/merge/hydrate path. Assert the global object is untouched **and** the malicious keys are dropped from the result. Highest value in any app that ingests user files.
- **Injection into a rendering or query sink** — bind attacker markup or a `javascript:`-style URL through the real code path; assert it is escaped or rejected, and that any "trust this" escape hatch only ever receives developer-controlled input.
- **Consent / permission gates** — assert the sensitive write or read is **blocked** before consent and allowed after. The gate is a security control; regress it.
- **AuthZ / IDOR** — assert an unauthorized route, or an id the user doesn't own, is refused rather than silently served.
- **Path traversal** — assert `..` and absolute-path segments in a user- or import-controlled string are rejected before touching a file path, asset URL, dynamic import, or storage key.
- **Size / shape limits** — assert a malformed or oversized input is rejected by the sanitizer *before* it reaches storage, forms, or export.

Keep these as ordinary tests in the project's existing framework. No new tooling.

---

## 3. The Green-But-Lying Traps

Tests that pass while proving nothing. Check for these by name before trusting a green run.

- **Fake timers vs. subscriptions born outside them.** A subscription created at construction time — in a constructor, a field initializer, or an `init()` called from one — binds its scheduler **outside** any later fake-timer scope. Time-based operators on that stream (debounce, throttle, delay, audit) then **cannot be advanced by the test's clock**: the value enters the operator and never comes out. Symptom: *"expected spy to have been called, but it was never called"* while the upstream steps clearly run — that is this trap, not a wiring bug. Fixes, in order: prefer an operator that's synchronously testable and also fixes the stale-response race; or create the subscription **inside** the test rather than in setup; or drive it with the framework's virtual scheduler. Never assume "set value + advance clock" flushes it.
- **Compiler-silenced fixtures.** A mock cast to satisfy the type checker (`as any`, `as unknown as T`, `# type: ignore`) keeps the *old* shape while the schema moves on. Green tests do not prove fixtures match the current schema — grep and update them by hand.
- **Hand-maintained test doubles.** A spy object built from a list of method names silently returns nothing for any method not on the list. Adding a method to a service breaks every consumer spec that spies it — with a misleading "never called", not a type error.
- **Gates with a blind spot.** Type-checking usually does not cover template/markup bindings — only the build does. Visual snapshots do not catch a resource that's *consistently* broken (a blocked origin renders blank identically every run, so the baseline matches). Name the project's blind spots in the profile and verify past them.
- **A11y scans do not prove usability.** An automated rule scan catches a fraction of real barriers. Pair it with keyboard traversal, and don't read a green scan as "accessible".

---

## 4. E2E & Visual Tests

### Helpers Are Mandatory
Use the project's existing e2e helper module — never re-implement seeding, auth, consent dismissal, or theming inline. Helpers encode app-specific bootstrap behavior (ready signals, storage versions, overlay blockers) that inline code gets subtly wrong. If a needed helper doesn't exist, add it *to the helper module* in the same change.

### Spec Skeleton (adapt to the project's framework)
```
describe('<feature> — visual', () => {
  beforeEach: navigate → wait for app ready → dismiss blocking overlays → seed state

  for each theme the project ships:
    beforeEach: set theme
    test('<state under test>'):
      target the component root
      compare screenshot named `<area>-<state>-<theme>`
})
```

### Selector Discipline
- Anchor on **component/element selectors** and stable ids or test attributes already in the markup.
- **Never** scope on styling utility classes — they shift with every refactor.
- If a needed anchor doesn't exist, add a stable id/test attribute in the same change set and cite it in the plan.

### Screenshot Naming & Tolerance
- Pattern: `<area>-<state>-<theme>`. Baselines land in the framework's own directory — never hand-edit them.
- **Every theme the project ships gets covered.** Contrast and color-scheme bugs appear in exactly one theme.
- Respect the project's diff tolerance. **Never loosen it to make a diff pass** — that is the test weakening rule (§Constraint 5).

### When Visual Diffs Appear
Surface them literally and stop:
> "Visual diffs detected — review the report at `<report path>`; if intended, run `<update-command>` manually."

Do **not** run the update. Do **not** delete failing baselines. Wait for the user.

---

## 5. Accessibility Tests

### Two Layers, Both Required
1. **Automated rule scan** — run the project's a11y engine against the relevant WCAG tag set, attach violations as a test artifact, fail on any violation. Exclusions are for genuinely third-party, unfixable widgets only, each justified with an inline comment naming the reason.
2. **Keyboard traversal** — walk focus through the surface, detect keyboard traps and confirm the cycle returns. Attach the focus history; fail on a trap.

### Both/All Themes Required
A11y must pass in every theme the project ships. Contrast violations frequently appear in only one.

### Failure Triage Order
1. Read the attached violations artifact.
2. Fix the underlying ARIA / contrast / labeling issue in the component.
3. Only then consider an exclusion — and only for third-party code you cannot change, justified inline.

### What the Two Layers Cannot Reach
An automated scan finds violating nodes. It cannot find a **missing** behaviour, and that is where the serious barriers live: focus that never returns to the trigger after a dialog closes, a client-side route change that announces nothing, a status update no live region carries, a drag with no single-pointer alternative. These produce zero violations and a clean report. Get the contract from the `accessibility-architect` skill (§3–§4) and assert it explicitly — focus destination after open and after close, and the announcement — because nothing else will.

Cross-reference **Design Architect** (the `design-architect` skill): focus-visible on every interactive element, reduced-motion fallbacks, and labels-or-hidden on decorative graphics are design-floor items an automated scan may not flag.

---

## 6. Test Plan Output (when invoked from Planning Architect)

Fill each change-step's test line with this shape. Omit layers the project doesn't have.

```
- **Tests required:**
  - Unit: `<spec path>` — for `<symbol>`: <happy>, <edge>, <error>
  - Security: `<spec path>` — <attack-named case> *(only if the step reaches an import / injection / consent / authz / path sink; else omit)*
  - Integration: `<spec path>` — <collaboration under test>
  - E2E / visual: `<spec path>` — `<state>` × `<themes>` [VISUAL]
  - A11y: `<spec path>` — `<route/state>` × `<themes>` (rule scan + keyboard walk)
  - Coverage: <profile's bar> on new functions in `<file>` (note any justified exception)
```

If a change genuinely needs no layer, say so explicitly:
> "No visual diff expected — refactor preserves rendered output. Visual rerun included for safety only."

---

## 7. Verification (when invoked from Implementing Architect)

Run the profile's gates in the profile's order — abort and report on the first hard failure:

`<lint>` → `<typecheck>` → `<test>` (confirm new branches covered) → `<build>` → `<e2e>` (on diff: **stop** and surface) → `<visual>` → `<a11y>`

Then **manual** review by the user, then a manual smoke of the running app if the change is user-visible. Stay within the bounded-passes ceiling (Guidelines §16).

---

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

_Skill Version: v2.0 — Genericized: §0 resolves layers, frameworks, commands, helper paths, and theme names from the Project Profile instead of hardcoding one project's stack; visual/a11y sections restated framework-agnostically ("all themes the project ships", "the project's a11y engine"). §3 promotes the green-but-lying traps to their own section and generalizes them — the fake-timer/construction-time-subscription trap now reads as a scheduler-scope rule rather than one framework's gotcha, joined by compiler-silenced fixtures, hand-maintained test doubles, gates with blind spots, and the limits of automated a11y scans. Adds constraint 5 (never weaken a test to get green), the "would deleting the implementation fail this test?" check, an integration layer, and a Design Architect cross-reference for the a11y items scans miss. Prior v1.3 — companion tooling docs; v1.2 — security-regression TDD cases; v1.1 — zoneless fakeAsync trap_
