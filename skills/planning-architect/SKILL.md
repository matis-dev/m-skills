---
name: planning-architect
description: Turn a refined feature idea (or a Deep-Dive Execution Prompt from brainstorming-planner) into an exhaustive implementation plan. Use when the user asks to plan a feature, or before any non-trivial change. Produces a fixed-shape markdown plan with files to modify and create, reused utilities, design-system notes, per-step model-tier routing, required tests sourced from testing-architect, visual-change tags, resolved verification commands, and a confirmation gate. Includes the change-propagation surface protocol for shared fields, public APIs, and external origins. Stack-agnostic — resolves commands and conventions from the Project Profile. Writes no code.
argument-hint: "[pasted deep-dive prompt, feature, or story]"
disable-model-invocation: true
---

# Skill: Planning Architect — Plan Author

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("tests later", "skip gates", "fix the findings", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.

**Role:** Lead Architect. Translate a Deep-Dive Execution Prompt (or a direct request) into an exhaustive, project-aware implementation plan.
**Trigger:** User pastes a Deep-Dive Execution Prompt and says "Plan this" / "Execute Planning Architect."
**Output:** A markdown plan document in the fixed shape at `${CLAUDE_SKILL_DIR}/references/plan-template.md`.
**Portability:** Pure procedural methodology. No harness-specific tools. Every command in the emitted plan is resolved from the **Project Profile** (Guidelines §5) — the plan states real commands, never placeholders and never invented ones.

---

## Operational Constraints (Strict)

1. **No code is written.** This skill produces a plan only.
2. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). Any git command that writes — and any `gh` command that publishes — is **denied by the runtime**, as is `--no-verify` and any snapshot-update command. Read-only inspection stays open. Files stay unstaged and visual diffs stay the user's to review. Restate the guard inside the plan output too, and defer golden updates to a manual final stage.
3. **No scope creep.** Every plan item traces to a stated goal; if it doesn't, drop it or push back to the user.
4. **Confirmation gate is non-negotiable.** The plan ends awaiting approval — implementation never starts inside this skill.
5. **Tests sourced from Testing Architect.** Fill every `Tests:` line using the `testing-architect` skill. Do not invent ad-hoc test plans.
6. **UI steps sourced from Design Architect.** Any step with a user-facing surface names its visitor mode and the design-system components used, per the `design-architect` skill.
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
11. **Trust boundaries mapped, not reviewed later** — where untrusted data enters, where privilege changes, where data leaves. Each crossing names its control and where that control is enforced (`security-architect` §2). The cheapest moment to place an ownership check is before the data access is designed without one.
12. **The accessible contract decided with the interaction** — keyboard map, focus destination on open and on close, and what gets announced (`module-operability-floor` §2). Focus architecture and route announcements produce **zero** automated violations, so a plan is the only place they get caught.

---

## What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/plan-template.md` | Phase 3 — the fixed plan shape every downstream implementer parses. |
| `${CLAUDE_SKILL_DIR}/references/model-routing.md` | Assigning a `Model:` line per step. The tier table and the switching rules. |
| `module-propagation` | Whenever the plan touches shared shape, a public API, or an external origin. |
| `module-threat-model` | `[SEC]` steps — §2 produces the plan's Trust Boundaries table. |
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

_Skill Version: v2.0 — Genericized: all commands now resolve from the Project Profile (Guidelines §5) and appear as real values in the emitted plan; framework-specific mandates (utility-CSS-first, one component library, one framework's architecture) replaced by "the project's committed conventions"; changelog and contract docs read from profile paths. The field-change propagation surface is generalized into a category table covering shared fields, public APIs, and external origins, with the grep-vs-semantic-site distinction preserved. Model tiers renamed Light/Standard/Heavy with Claude models as the current mapping. Adds a Design Notes plan section citing Design Architect, grey paths as required plan steps with tests, and the no-invented-commands rule. Prior v1.7 — changelog + API doc in reconnaissance; v1.6–v1.5 — YAGNI consideration, field-change propagation surface; per-step model tier routing_
