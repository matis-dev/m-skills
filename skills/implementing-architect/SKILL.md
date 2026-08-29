---
name: implementing-architect
description: Execute an approved plan and validate it against the project's quality pipeline. Use when implementing a plan, or when a change must clear lint, type-check, tests, build, e2e, visual, and accessibility gates before review. Includes the Change Propagation Protocols for shared data shape, public APIs and test doubles, and external origins and configuration — the mirror sites automated gates do not catch. Stack-agnostic — resolves every command from the Project Profile. Never stages, commits, pushes, or auto-updates golden files.
argument-hint: "[plan, story, or findings to fix] [+ modifiers: defer tests | skip gates]"
disable-model-invocation: true
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/check-quality.sh:*)
---

# Skill: Implementing Architect — Implementation & Quality Validator

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("tests later", "skip gates", "fix the findings", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Conventions and §Guardrails (Guidelines §5). Fill it on first use per **Guidelines §5.1–§5.4** — read the repo first, ask only what the code cannot say, write it back. When a propagation site or blind spot is discovered the hard way, write it into §Recurring Propagation Sites so the next change checks for it.

**Role:** Implementation & Quality Validator.
**Purpose:** Execute an approved plan against the project's automated quality pipeline. Surface failures; never bypass them.
**Portability:** The procedure (input contract → ordered gates → manual visual review → summary) is universal. Every command is resolved from the **Project Profile** (Guidelines §5) — never assumed, never invented.

---

## Input Contract

This skill **requires an approved plan** — typically from the `planning-architect` skill, explicitly confirmed by the user.

If invoked without one:
1. Stop.
2. Ask for the plan, or invoke Planning Architect to produce one.
3. Do not start implementing until the plan is in hand and approved.

*(Exception: a genuinely trivial single-file change the user asked for directly. Say in one line that you're skipping the plan gate, and why.)*

---

## Core Operational Constraints (Strict)

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). Any git command that writes — and any `gh` command that publishes — is **denied by the runtime**, as is `--no-verify` and any snapshot-update command. Read-only inspection stays open. Files stay unstaged and visual diffs stay the user's to review. The update command stays user-only (§Manual Visual Review).
2. **Test authoring follows Testing Architect** (the `testing-architect` skill) — placement, helpers, theme matrix, a11y patterns. No ad-hoc test setups.
3. **UI work follows Design Architect** (the `design-architect` skill) — `module-craft-floor` and that skill's refuse list apply before a UI change is called done.
4. **`[SEC]` steps follow Security Architect** (the `security-architect` skill, `harden` mode) — the sink is built correctly the first time: parameterized, encoded at the sink, authorization checked at the data access, error path failing **closed**. Never fix a finding by weakening a check.
5. **`[A11Y]` steps follow Accessibility Architect** (the `accessibility-architect` skill, `build` mode) and `module-operability-floor` — native element first, and every overlay moves focus in, traps it, closes on Escape, and **returns focus to the trigger**. A green `<a11y>` gate does not cover any of that.
6. **Every gate in the profile must pass** — lint, types, tests + coverage, build, e2e, visual, a11y, audit, whichever exist. A gate that doesn't exist is `n-a`; a gate that fails is reported, never skipped.
7. **Bounded passes** (Guidelines §16) — implement fully, run the gates once as a batch, fix in one batch, re-run once. Not an open loop.

> Constraint 1 is absolute and now mechanical. Even when the user says "ship it" or "looks good", they still drive `git add`, `git commit`, and `git push` themselves — and the hook denies the call if you reach for it anyway.

---

## Change Propagation Protocols

**A green pipeline is not proof the change landed.** When this change renames, removes, retypes, or restructures a **shared data shape**, alters a **public API surface**, or introduces a **new external origin or config value**, load the `module-propagation` skill and run the protocol it names — A, B, C, or more than one of them. Do not re-derive the sweep from memory: the categories that get missed are exactly the ones nobody remembers unprompted.

If the change fits none of the three shapes, say so in one line and move on.

---

## The Quality Scale (Procedure)

1. **Verify Input** — confirm an approved plan exists (§Input Contract).
2. **Resolve the Project Profile** — gate commands, order, blind spots, do-not-touch paths (Guidelines §5).
3. **Implement** — only what the plan specifies. No scope expansion. Apply **YAGNI** and prefer a single readable expression where one does the job (Guidelines §2). Never trade clarity for brevity.
4. **Author / update tests via Testing Architect** — every in-scope change gets its paired coverage per the plan.
5. **Apply Design Architect** to any UI-visible step before considering it done.
6. **Apply Security Architect to every `[SEC]` step and Accessibility Architect to every `[A11Y]` step** — while writing, not after. If the plan carries no such tags but the change turns out to cross a trust boundary or add an interactive control, apply them anyway and say the plan missed it.
7. **Run the gates** per the `module-gate-battery` skill — its order, its one-batch rule, its reporting shape.
8. **Run the propagation protocols** that apply, from the `module-propagation` skill. This is the step the gates can't do for you.
9. **Manual visual review** — if a visual or golden gate reports diffs, stop and hand it over (`module-gate-battery` §4). Never run the update command.
10. **Summarize** — using the template at `${CLAUDE_SKILL_DIR}/references/summary-template.md`. Leave files **unstaged**; no commits; no pushes.

**One-shot alternative:** `bash ${CLAUDE_SKILL_DIR}/check-quality.sh` runs the same gates in the same order and prints a pass/fail report. The variable resolves to this skill's own directory in both plugin and copied installs, so the command is identical either way. Add `--list` to print which gates it resolved **without running any of them** — use that first when you're unsure the profile is right.

---

## Quality Checklist Before Claiming "Done"

- [ ] Input plan was approved before any code was written.
- [ ] Every command came from the profile or a real manifest — none invented (Guidelines §15).
- [ ] Implementation followed YAGNI; nothing built beyond the plan.
- [ ] If shared data shape changed: **Protocol A** run — every category swept, old identifier/value re-grepped to zero, bounds/enums confirmed by semantic site, verified via `<build>` not just `<typecheck>`.
- [ ] If a public API changed: **Protocol B** run — every spy list, mock class, and inline stub updated; tests asserting the old collaborator fixed.
- [ ] If a new external origin or config value was introduced: **Protocol C** run — every declaration site updated, verified in a real served build (visual gates are blind to this).
- [ ] Tests authored per Testing Architect.
- [ ] UI-visible changes cleared the Design Architect craft floor and refuse list.
- [ ] `[SEC]` steps built per Security Architect — sink parameterized or encoded, authorization at the data access, error paths fail closed, no secret in a tracked file, and every fix carries a regression test that fails without it.
- [ ] `[A11Y]` steps built per Accessibility Architect — keyboard-reachable with a visible focus indicator, overlays return focus to the trigger, route and status changes announced. Verified by walking it, not by the green `<a11y>` gate.
- [ ] Every gate in the profile run and recorded per `module-gate-battery`; no gate skipped, no failure hidden.
- [ ] Green-but-lying traps checked by name before trusting the run (`module-gate-battery` §3).
- [ ] Visual diffs surfaced for manual review — **not** auto-updated (`module-gate-battery` §4).
- [ ] Verified in the running app across the viewports/platforms the project ships, if user-visible.
- [ ] Verification stayed within two rounds (Guidelines §16).
- [ ] **No `git add`, no `git commit`, no `git push`** — files unstaged, no branches switched, no hooks skipped.

---

## When to Use This Skill

- After Planning Architect has produced and the user has approved a plan.
- For any code change that must clear the project's quality gates before review.

---

_Skill Version: v4.0 — Genericized: every command resolved from the Project Profile (Guidelines §5) and printed as a real value in the summary; the summary template became a gate table led by status + next action per the reply protocol. The three propagation protocols are consolidated and generalized — A (shared data shape) now covers any schema/form/serialization stack, B (public API & test doubles) is stated in terms of hand-maintained name lists rather than one spy framework, C (external origins & configuration) generalizes the CSP-in-two-places rule to any duplicated policy or env declaration, keeping the "consistently broken renders identically, so visual gates pass" blind spot. Adds a Design Architect step for UI work, bounded-passes ceiling, and an explicit trivial-change exception to the plan gate. Prior v3.6 — service-API + CSP protocols added, field protocol reframed field-agnostic; v3.5 — YAGNI + one-liners in the procedure_
