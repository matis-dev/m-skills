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
**Output:** A markdown plan document with a fixed shape (§Phase 3).
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
12. **The accessible contract decided with the interaction** — keyboard map, focus destination on open and on close, and what gets announced (`accessibility-architect` §3). Focus architecture and route announcements produce **zero** automated violations, so a plan is the only place they get caught.

---

## The Change-Propagation Surface (mandatory when it applies)

**Triggers on the *shape* of the change, not on which project you're in.** Whenever the plan renames, removes, retypes, or restructures something **shared** — a data-model field, an enum value, a numeric bound, a public method signature, an external origin — the **Files to Modify** list must enumerate **every mirror site**, one per line, not just the obvious one.

Walk these categories. They are categories, not a checklist of one project's files — substitute what exists here:

| Category | What to look for |
|---|---|
| **Type / model definition** | The declaration itself. |
| **Construction sites** | Factories, builders, form groups, constructors, fixtures — there is usually **more than one** (a primary and a variant/array-item/parallel one). |
| **Both directions of mapping** | Serialize *and* hydrate, encode *and* decode, to-DTO *and* from-DTO. |
| **Validation, stated twice** | The framework's declarative validators **and** any hand-written validation service. The same bound is frequently hardcoded in two places. |
| **Sanitizers / normalizers** | Schema sanitizer, import coercion, migration code. |
| **Boundaries** | Export and import paths, API payloads, storage schemas, query params. |
| **Templates / views** | Bindings referencing the field by name. **These often fail only at build/AOT/runtime, never at type-check.** |
| **Parallel subsystems** | The secondary UI that mirrors the primary one, a template service's flat interface, an admin form. **The easiest miss.** |
| **Test doubles** | Spy/mock method lists, hand-written mock classes, inline stub objects. A double built from a hand-maintained name list silently returns nothing for a new method. |
| **Fixtures** | Old-shape mocks cast to satisfy the compiler still pass green. |
| **User-facing strings** | Removing a field orphans its label/placeholder keys — in **all** locales. Strings that bake a bound into prose ("must be between X and Y") go stale while their key stays used. |
| **Comments / docs** | Stale bounds and behavior descriptions quoting the old value. |

**Verification line the plan must include:**
- **Identifier renames/removals** — re-grep the old identifier across the source tree; expect zero hits outside changelog/migration docs.
- **Numeric bounds and enum values** — grep is unreliable (a bare `90` drowns in noise). The plan lists the **semantic sites by name** instead, because the value is *re-expressed*, not just referenced.
- **Templates** — confirm via the `<build>` gate, not `<typecheck>`. A green type-check does not prove templates are clean.

---

## Model Tier Routing (Mandatory per Step)

The plan exists so the user can **switch models between steps**. Each step carries a `Model:` line.

| Tier | When to assign | Typical work |
|---|---|---|
| **Light** (e.g. Haiku) | Mechanical, low-ambiguity, single-file edits; rote scaffolding; renames; importing an existing pattern; obvious test boilerplate; running verification commands. | "Move this method into that service", "rename symbol", "create the spec mirroring existing pattern X". |
| **Standard** (e.g. Sonnet) | Multi-file but well-scoped changes with a clear blueprint; a new component composed of known primitives; standard wiring; typical test authoring. | "Build this component from the existing `Foo` service and design-system card", "wire route + guard + resolver per existing pattern". |
| **Standard + thinking** | Non-trivial design decisions inside a step; tricky async/state interactions; subtle a11y or focus management; refactors that must preserve behavior exactly. | "Restructure the event orchestration without breaking subscribers", "focus-trap interacting with the existing modal stack". |
| **Heavy** (e.g. Opus) | Cross-cutting reasoning across many files; architectural tradeoffs; novel algorithms; deep ambiguous debugging. | "Design a sync layer spanning 6+ services", "resolve a flake whose root cause is unclear". |
| **Heavy + thinking** | The hardest reasoning the plan admits — usually 0–1 per plan, often none. Justify in writing. | "Reconcile competing constraints across module boundaries with no obvious answer". |

Rules:
- **Default downward.** Borderline Standard → drop to Light and trust the implementer to escalate.
- **Group adjacent same-tier steps** so the user switches once, not six times.
- **Flag every tier change** with `[SWITCH MODEL → <tier>]` at the top of the step.
- **Insert an explicit stop** at the end of any step preceding a tier change: *"Implement step N, then STOP. Do not proceed — the user will switch models first."*
- **No silent escalation.** If a Light-tagged step turns out to need Heavy reasoning, the implementer stops and surfaces it.

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

Produce markdown with this **fixed shape** so any downstream implementer can parse it. Replace `<lint>`/`<test>`/etc. with the project's real commands.

```markdown
# Plan: <feature name>

## Context
<why this is being built — from the brainstorming prompt>

## Goals (traced from the prompt)
- <goal 1>
- <goal 2>

## Files to Modify
- `<path>` — <what changes here, one line>

## Files to Create
- `<path>` — <purpose, one line>

## Reused Utilities (do not duplicate)
- `<path>` — <existing artifact being extended>

## Design Notes  *(omit if no user-facing surface)*
- Visitor mode: <Persuade | Operate | Read | Experience>
- Design-system components used: <names>
- Custom styling justification (if any): <reason>
- Grey paths designed: <loading / empty / error / offline / permission>

## Trust Boundaries  *(omit only if the change crosses none — and say so in one line rather than deleting the heading)*
| Boundary | Untrusted input | Control | Enforced at |
|---|---|---|---|
| `<endpoint / form / import>` | `<what arrives>` | `<validation, limit, ownership check>` | `<file:symbol>` |
- Privilege changes: `<none | what widens, and where>`
- Data leaving: `<responses / logs / exports / emails>` — `<what is redacted>`

## Accessibility Contract  *(omit if no interactive surface)*
- Pattern: `<native element | ARIA pattern + the full contract it owes>`
- Accessible name/role for each new control: `<name — role>`
- Keyboard map: `<Tab / arrows / Enter / Escape behaviour>`
- Focus on open → `<destination>`; on close → `<returned to trigger>`
- Announced: `<what, via role=status | role=alert | focus move>` — one mechanism, not both
- Target size: `<meets 24×24 or the spacing exception>`

## Change-Propagation Surface  *(omit if nothing shared changes)*
- <category> → `<path>` — <what must change>
- Verification: <re-grep the old identifier | semantic sites listed by name | confirm via `<build>`>

## Model Routing Summary
| Step | Tier | Thinking? | One-line reason |
|---|---|---|---|
| 1 | Light | no | <mechanical rename> |
| 2 | Light | no | <continuation, no switch> |
| 3 | Standard | no | <multi-file scaffold from known pattern> |
| 4 | Standard | yes | <subtle async coordination> |
| 5 | Heavy | yes | <cross-cutting design call> |
| 6 | Light | no | <verification commands> |

Group adjacent same-tier rows so the user switches only when the tier changes.

## Step-by-Step Changes
Each step: model tier, action, files, **tests required**, any of the `[VISUAL]` / `[SEC]` / `[A11Y]` tags that apply, and an explicit stop before any tier change. A step can carry more than one tag — an upload field is both.

1. `[SWITCH MODEL → Light]` **<action>** — files: `<paths>`
   - Model: **Light** — <one-clause reason>
   - Tests: <unit test names / specs to add or update>
2. **<action>** — files: `<paths>` `[VISUAL]` `[A11Y]`
   - Model: **Light** *(same tier — no switch needed)*
   - Tests: <unit + visual spec + a11y scan and keyboard walk>
   - **Stop after this step.** The next step uses a different model.
3. `[SWITCH MODEL → Standard]` **<action>** — files: `<paths>` `[SEC]`
   - Model: **Standard** — <one-clause reason>
   - Tests: <… + the security-regression case that fails without the fix>

> Implementer rule: never upgrade your own tier silently. If a Light-tagged step needs Heavy reasoning, stop and tell the user.

## Verification Steps (commands, in order)
1. `<lint>`
2. `<typecheck>`
3. `<test>`
4. `<build>`
5. `<e2e>`
6. `<a11y>`
*(list only gates this project actually has)*

## Manual Final Stage (NOT automated)
- Review failed visual diffs at `<report path>`.
- If diffs are intended, the **user** runs `<update-command>` manually and re-runs `<visual>`.
- Implementer never runs `git add`, `git commit`, or `git push`. Staging, committing, and pushing are **user-only**.

## Out of Scope
- <explicit non-goals>

## Risks & Open Questions
- <risk or question for the user>
```

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
