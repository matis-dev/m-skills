---
name: planning-architect
description: Use to turn a refined idea or Deep-Dive Execution Prompt into an implementation plan before any non-trivial change. Produces the fixed-shape plan — files, reused utilities, direction brief and design notes, [VISUAL]/[SEC]/[A11Y] tags, tests from testing-architect, per-step model routing, real verification commands, a confirmation gate. Writes no code.
argument-hint: "[pasted deep-dive prompt, feature, or story]"
disable-model-invocation: true
---

# Skill: Planning Architect — Plan Author

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.

---

## Operational Constraints (Strict)

1. **No code is written.** This skill produces a plan only.
2. **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open. Restate the guard inside the plan output too, and defer golden updates to a manual final stage.
3. **No scope creep.** Every plan item traces to a stated goal; if it doesn't, drop it or push back to the user.
4. **Confirmation gate is non-negotiable.** The plan ends awaiting approval — implementation never starts inside this skill.
5. **Tests sourced from Testing Architect.** Fill every `Tests:` line using the `testing-architect` skill. Do not invent ad-hoc test plans.
6. **UI steps sourced from Design Architect.** Any step with a user-facing surface names its visitor mode, its direction brief (structure · palette anchor · type pairing · signature moment), and the design-system components used, per the `design-architect` skill.
7. **Security sourced from Security Architect.** Any step that accepts untrusted input, changes authorization, touches secrets or storage, or adds a dependency names its trust boundary and carries a `[SEC]` tag, per the `security-architect` skill. A feature that crosses no boundary says so explicitly.
8. **Accessibility sourced from Accessibility Architect.** Any step with an interactive surface names its keyboard map and its accessible name/role, and carries an `[A11Y]` tag, per the `accessibility-architect` skill.
9. **Per-step model routing is mandatory.** Every step declares a `Model:` line so the user can switch tiers between steps and save tokens.
10. **Every command in the plan is real.** Read from the profile or a manifest file. An absent gate is written `n-a`, never guessed (Guidelines §15).

---

## Mandatory Considerations

Every plan addresses each of these explicitly:

1. **Project conventions first** — the existing idiom, design system, and topology outrank your preferences (Guidelines §6, §8). Cite the sibling file you matched.
2. **Reuse mandate** — Reconnaissance enumerates existing services/components/utilities to extend rather than duplicate. Cite paths.
3. **YAGNI + one-liners** — every step is scoped to what the goal demands. No speculative abstractions, config, or future-proofing hooks. Where a step's logic is genuinely a single readable expression, say so rather than prescribing scaffolding (Guidelines §2).
4. **Inherited guards restated inside the plan** — no staging, committing, pushing, branching, hook-skipping, or force ops.
5. **Tests as a deliverable** — every code-change item is paired with the tests that verify it. No "tests TBD". Source the *how* from Testing Architect; cite spec paths and helpers.
6. **Golden/visual policy** — mark visually-changing steps `[VISUAL]`. Append a final manual stage: *"User reviews failed visual diffs and runs `<update-command>` only after inspection."* Never instruct the implementer to auto-update.
7. **Goal trace** — every item links to a specific objective. No drive-by scope.
8. **Grey paths planned, not discovered** — loading, empty, error, offline, timeout, permission-denied, and partial-failure states are plan steps with their own tests, not afterthoughts.
9. **Token economy via model tiering** — assign the cheapest tier that does the step well (§Model Tier Routing).
10. **Change-propagation surface** — see the protocol below. This is the single highest-value section of any plan that touches shared shape.
11. **Trust boundaries mapped, not reviewed later** — where untrusted data enters, where privilege changes, where data leaves. Each crossing names its control and where that control is enforced (`module-threat-model` → `references/trust-boundaries.md`). The cheapest moment to place an ownership check is before the data access is designed without one.
12. **The accessible contract decided with the interaction** — keyboard map, focus destination on open and on close, and what gets announced (`module-operability-floor` §2). Focus architecture and route announcements produce **zero** automated violations, so a plan is the only place they get caught.

---

## What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/plan-template.md` | Phase 3 — the fixed plan shape every downstream implementer parses. |
| `${CLAUDE_SKILL_DIR}/references/model-routing.md` | Assigning a `Model:` line per step. The tier table and the switching rules. |
| `module-propagation` | Whenever the plan touches shared shape, a public API, or an external origin. |
| `module-threat-model` | `[SEC]` steps — its `references/trust-boundaries.md` produces the plan's Trust Boundaries table. |
| `module-operability-floor` | `[A11Y]` steps — §2 produces the plan's Accessibility Contract. |

---

## The Change-Propagation Surface (mandatory when it applies)

**Triggers on the *shape* of the change, not on which project you're in.** Whenever the plan renames, removes, retypes, or restructures something **shared** — a data-model field, an enum value, a numeric bound, a public method signature, an external origin — load the `module-propagation` skill, walk its categories, and enumerate **every mirror site** in the plan's **Files to Modify** list, one per line, followed by the verification line that module names for this change's shape.

A plan that touches shared shape and lists one file is the most common way a plan is wrong, and it is the section that most reliably pays for the planning stage.

---

## Procedure (4 Phases)

### Phase 1 — Reconnaissance
- Read the Deep-Dive Execution Prompt; extract objectives.
- **Resolve the Project Profile** (Guidelines §5): gate commands, design system, test layers, doc targets, known blind spots, recurring propagation sites.
- **Read the project's changelog / recent history** (path from the profile) for the area you're about to touch. It surfaces prior decisions, hidden logic, and removed features that constrain the plan or reveal reuse. Cite anything that changes the approach; if nothing is relevant, say nothing.
- **Read the relevant contract doc** if the feature touches an integration (API doc, schema, protobuf, OpenAPI spec). Plan against the real contract, and fold any doc drift the plan introduces into Files to Modify.
- Map the codebase areas the prompt touches.
- **Reuse hunt** — enumerate existing services, components, utilities, and styles the feature could extend or compose. Record each with a path and a one-line "what it does".
- Identify the design-system components that fit; note their names.
- Note conventions already constraining the area (established patterns, guards, change-detection or rendering strategy).

### Phase 2 — Design
- **Recommended approach** — one paragraph. Cite reused artifacts.
- **One credible alternative** — one paragraph.
- **Tradeoff** — one paragraph. Why the recommendation wins *for this case*.
- If the recommendation departs from a project convention, justify it in writing.
- **Model routing pass** — pre-assign the cheapest viable tier to each anticipated step; note any step genuinely needing thinking mode and why.

### Phase 3 — Plan Document

Produce markdown in the **fixed shape** at `${CLAUDE_SKILL_DIR}/references/plan-template.md`, so any downstream implementer can parse it. Replace `<lint>`/`<test>`/etc. with the project's real commands; a placeholder left unresolved is a defect, not a template.

Omit a section only where the template says it may be omitted — and say in one line that it does not apply, rather than deleting the heading silently.

### Phase 4 — Confirmation Gate
End the plan with the literal line:

> **Awaiting approval before implementation. Do not proceed until the user confirms.**

Do **not** invoke the Implementing Skill. Do **not** start writing code. Wait.

---

## Quality Checklist (before claiming "Plan complete")

- [ ] All cited file paths verified to exist (or marked `[NEW]`).
- [ ] Every command in the plan resolved from the profile or a manifest — none invented, absent gates written `n-a`.
- [ ] Reused utilities enumerated with paths.
- [ ] Plan honors YAGNI and flags one-liner-solvable steps rather than over-scaffolding them.
- [ ] Project conventions and design system addressed explicitly; departures justified.
- [ ] Every code-change step paired with a tests-required item.
- [ ] Grey paths (loading / empty / error / offline / permission) planned with their own tests.
- [ ] `[VISUAL]` tags applied wherever rendered output changes.
- [ ] `[SEC]` tags applied wherever untrusted input, authorization, secrets, storage, or a new dependency is touched; Trust Boundaries section present or an explicit "crosses none".
- [ ] `[A11Y]` tags applied to every interactive surface; Accessibility Contract names focus destination on open **and** on close.
- [ ] Manual Final Stage present and explicit about no auto-updates.
- [ ] Inherited guards restated.
- [ ] Goal trace verifiable — each step maps to an objective.
- [ ] Out of Scope section non-empty (forces explicit boundary-setting).
- [ ] If anything shared changes: every propagation category walked, mirror sites enumerated, verification line stated (re-grep for identifiers; semantic sites for bounds/enums; `<build>` for templates).
- [ ] Confirmation gate line present verbatim.
- [ ] Every step has a justified `Model:` line; routing summary matches; `[SWITCH MODEL → …]` markers and stop instructions on every tier boundary.
- [ ] Default-downward respected — heavy tiers are the exception, each justified in writing.

---

## When to Use This Skill

- After Brainstorming Planner has emitted a Deep-Dive Execution Prompt.
- Before invoking Implementing Architect (the `implementing-architect` skill).
- When you need a project-aware plan that won't skip tests, conventions, or propagation sites.

---

_v2.0 — version history in CHANGELOG.md_
