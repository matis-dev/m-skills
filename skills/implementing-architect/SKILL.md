---
name: implementing-architect
description: Use to execute an approved plan. Implements only what the plan says, authors the paired tests, runs every profile gate in one batch, then the Change Propagation Protocols (shared shape, public API and test doubles, external origins) that a green pipeline cannot prove. Never stages, commits, pushes, or auto-updates golden files.
argument-hint: "[plan, story, or findings to fix] [+ modifiers: defer tests | skip gates]"
disable-model-invocation: true
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/check-quality.sh:*)
---

# Skill: Implementing Architect — Implementation & Quality Validator

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Profile section owned:** §Conventions and §Guardrails (Guidelines §5.1–§5.4). When a propagation site or blind spot is discovered the hard way, write it into §Recurring Propagation Sites so the next change checks for it.

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

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open. The update command stays user-only (§Manual Visual Review).
2. **Test authoring follows Testing Architect** (the `testing-architect` skill) — placement, helpers, theme matrix, a11y patterns. No ad-hoc test setups.
3. **UI work follows Design Architect** (the `design-architect` skill) — its §2 direction brief is written before the markup, and `module-craft-floor` and its refuse list apply before a UI change is called done.
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
- [ ] UI-visible changes cleared the Design Architect craft floor and refuse list, and match the direction brief.
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

_v4.0 — version history in CHANGELOG.md_
