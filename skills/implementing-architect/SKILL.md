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
> **Profile section owned:** §Conventions and §Guardrails (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo for the answers first** — then ask at most 3–4 questions covering only what the code cannot say, and write it back. A question the repo already answers is a defect (Guidelines §5.3); so is deferring a row whose answer sits in a file you didn't open. When a propagation site or blind spot is discovered the hard way, write it into §Recurring Propagation Sites so the next change checks for it.

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

1. **No Staging** — never `git add`, `git stage`, `git commit -a`, or an IDE "stage hunk". Changes stay **unstaged**.
2. **No Commits** — never `git commit` in any form.
3. **No Pushes** — never `git push` or any remote sync.
4. **No Branching** — never `git checkout`, `git switch`, or branch creation.
5. **No Skipping Hooks** — never `--no-verify` or equivalent. Fix the root cause.
6. **No Auto Golden/Snapshot Updates** — the update command is user-only (§Manual Visual Review).
7. **Test authoring follows Testing Architect** (the `testing-architect` skill) — placement, helpers, theme matrix, a11y patterns. No ad-hoc test setups.
8. **UI work follows Design Architect** (the `design-architect` skill) — the craft floor and refuse list apply before a UI change is called done.
9. **Every gate in the profile must pass** — lint, types, tests + coverage, build, e2e, visual, a11y, audit, whichever exist. A gate that doesn't exist is `n-a`; a gate that fails is reported, never skipped.
10. **Bounded passes** (Guidelines §16) — implement fully, run the gates once as a batch, fix in one batch, re-run once. Not an open loop.

> The git constraints (1–4) are absolute. Even when the user says "ship it" or "looks good", they still drive `git add`, `git commit`, and `git push` themselves.

---

## Change Propagation Protocols

**Why these exist:** a green pipeline is *not* proof the change fully landed. Each protocol below covers mirror sites the automated gates structurally cannot catch. They trigger on the **shape** of the change, not on the project.

> Every concrete example below is an **illustration of a category**, not a rule. Substitute what exists in the project you're in. Categories are what survive; a catalogue of last month's field names is what rots.

### A. Shared Data Shape

Applies when a shared field is **renamed, removed, retyped, restructured** (object↔array, string↔object), an **enum value changed**, or a **numeric bound moved**.

**Known gate blind spots:**
- **Type-checking usually doesn't cover markup/template bindings.** A stale binding compiles clean and fails only at build/AOT or runtime. The **build gate** is the one that catches template drift — a green type-check is necessary and never sufficient.
- **Compiler-silenced fixtures** (`as any`, `as unknown as T`, `# type: ignore`) keep old shapes passing green. Green tests do not prove fixtures match the schema.

**The sweep** — grep the OLD identifier and OLD value project-wide, then confirm each category:

1. **Type / model definition** — the declaration itself.
2. **Every construction site** — factories, builders, form groups, default objects. There is almost always **more than one** (a primary plus a variant, array-item, or parallel builder).
3. **Both mapping directions** — serialize *and* hydrate, encode *and* decode.
4. **Validation stated twice** — the declarative validators **and** any hand-written validation service. The same bound is routinely hardcoded in two places.
5. **Sanitizers / normalizers / migrations.**
6. **Boundaries** — export and import paths, API payloads, storage schemas, query params.
7. **Templates / views** — bindings referencing the name. *(Build-gate-only failures.)*
8. **Parallel subsystems** — the secondary UI mirroring the primary one, a flat-field interface, an admin form. **The easiest miss.**
9. **User-facing strings** — a removed field **orphans its label/placeholder keys**; remove them from **all** locales. Grep each key across source before deleting to confirm zero references.
10. **Fixtures and test doubles** — old-shape mocks pass green; update them anyway.
11. **Comments and doc-comments** quoting the old bound or behavior.

**Numeric bounds and enum values — do NOT rely on grep.** A renamed identifier greps cleanly; a moved bound does not (a bare number drowns in false positives), so "grep found nothing" is not proof. Walk a **semantic site list** instead, because the value gets *re-expressed*, not just referenced — wherever the app **states** the constraint a second time: declarative validators in *every* factory (including any per-branch re-wiring helper), the hand-written validation check, markup `min`/`max`/`maxlength` attributes and client-side clamps, parallel/secondary field configs, **user-facing strings baking the value into prose** (the key is still used — only its value is stale; update all locales), spec boundary assertions pinned to the old edge, and comments.

**Closing check:** re-grep the old identifier/value — expect zero hits outside changelog and migration docs. For bounds/enums, confirm each semantic site by name. Then run `<build>`, not just `<typecheck>`, before claiming the change is done.

### B. Public API & Test Doubles

Applies when a service, module, or class's **public surface changes** — a method added, renamed, removed, or re-signed. A green `<typecheck>`/`<build>` does **not** prove consumer *tests* survive: test doubles are built from hand-maintained name lists and silently return nothing for anything not on them.

Grep the type name **and** the method name across the source:

1. **Real callers** — the type checker catches these. It does not catch anything below.
2. **Spy/mock object name lists** — every consumer test that spies this type must add the new method, or the call returns undefined → *"is not a function"* or a misleading *"never called"*.
3. **Hand-written mock classes** — tests substituting a fake implementation need the new method stubbed.
4. **Inline stub objects** passed as providers/config by value.
5. **Tests asserting the OLD collaborator** — if the implementation swapped which collaborator it calls, the test must stub the new one, not the old.

**Closing check:** grep the new method name across test files — every consumer test exercising the changed path should reference it. Then run `<test>`; an *"is not a function"* or a surprise *"never called"* is this protocol, not a product bug.

### C. External Origins & Configuration

Applies when a change makes the app load a **new external origin** (tiles, an API host, a font, an image CDN, a third-party script) or otherwise depends on runtime configuration.

- Update **every** place the policy is declared. Security policies are commonly duplicated — a markup meta tag *and* a server header, a dev config *and* a prod config, a manifest *and* a deployment env. Update all copies or the resource is silently blocked in one environment and works in another.
- Pick the directive by sink: images, network calls, fonts, scripts, frames each have their own.
- **Blind spot:** a blocked resource renders *consistently* broken, so its visual baseline still matches and the visual gate **passes**. Verify in a real served build, not by green tests.
- Same logic for env vars, feature flags, and build-time constants: enumerate every environment that declares them.

---

## The Quality Scale (Procedure)

1. **Verify Input** — confirm an approved plan exists (§Input Contract).
2. **Resolve the Project Profile** — gate commands, order, blind spots, do-not-touch paths (Guidelines §5).
3. **Implement** — only what the plan specifies. No scope expansion. Apply **YAGNI** and prefer a single readable expression where one does the job (Guidelines §2). Never trade clarity for brevity.
4. **Author / update tests via Testing Architect** — every in-scope change gets its paired coverage per the plan.
5. **Apply Design Architect** to any UI-visible step before considering it done.
6. **Run the gates in the profile's order**, as one batch — record every result, don't stop at the first failure unless it blocks the rest:
   `<lint>` → `<typecheck>` → `<test>` → `<build>` → `<e2e>` → `<visual>` → `<a11y>` → `<audit>`
7. **Run the propagation protocols** that apply (A / B / C above). This is the step the gates can't do for you.
8. **Manual Visual Review** — §below.
9. **Summarize** — the Implementation Summary template. Leave files **unstaged**; no commits; no pushes.

**One-shot alternative:** `bash ${CLAUDE_SKILL_DIR}/check-quality.sh` runs the same gates in the same order and prints a pass/fail report. The variable resolves to this skill's own directory in both plugin and copied installs, so the command is identical either way. Add `--list` to print which gates it resolved **without running any of them** — use that first when you're unsure the profile is right.

---

## Manual Visual Review

If the visual gate reports diffs:

1. **STOP** — do not run the update command.
2. Surface the failures literally:
   > "Visual diffs detected — review the report at `<report path>`; if intended, run `<update-command>` manually."
3. Wait for inspection and an explicit go-ahead before any further action on baselines.

Non-negotiable inherited guard (Guidelines §10). Baselines tell the user what changed visually; auto-updating erases that signal.

---

## Task Completion Summary Template

Lead with status, not narration (Guidelines §17).

```markdown
## 🏁 Implementation Summary

**Status:** <all gates green | N failing | awaiting visual review>
**Next action:** <the one thing the user does now>

- **Plan reference:** <link or filename>
- **Files Affected:** <list>
- **Functions Created/Modified:** <list>

| Gate | Result |
|---|---|
| `<lint>` | ✅ / ❌ <one-line summary if ❌> |
| `<typecheck>` | ✅ / ❌ |
| `<test>` | ✅ / ❌ — coverage: <n>% branches |
| `<build>` | ✅ / ❌ |
| `<e2e>` | ✅ / ⚠️ diffs awaiting manual review / ❌ |
| `<a11y>` | ✅ / ❌ <violations, themes affected> |
| `<audit>` | <advisories by severity> |

**Propagation protocols run:** <A shared-shape / B public-API / C external-origin / none applied>
**Known gaps:** <uncovered branches, deferred items — or "none">
```

---

## Quality Checklist Before Claiming "Done"

- [ ] Input plan was approved before any code was written.
- [ ] Every command came from the profile or a real manifest — none invented (Guidelines §15).
- [ ] Implementation followed YAGNI; nothing built beyond the plan.
- [ ] If shared data shape changed: **Protocol A** run — every category swept, old identifier/value re-grepped to zero, bounds/enums confirmed by semantic site, verified via `<build>` not just `<typecheck>`.
- [ ] If a public API changed: **Protocol B** run — every spy list, mock class, and inline stub updated; tests asserting the old collaborator fixed.
- [ ] If a new external origin or config value was introduced: **Protocol C** run — every declaration site updated, verified in a real served build (visual gates are blind to this).
- [ ] Tests authored per Testing Architect; green-but-lying traps checked.
- [ ] UI-visible changes cleared the Design Architect craft floor and refuse list.
- [ ] Every gate in the profile run and recorded; no gate skipped, no failure hidden.
- [ ] Visual diffs surfaced for manual review — **not** auto-updated.
- [ ] Verified in the running app across the viewports/platforms the project ships, if user-visible.
- [ ] Verification stayed within two rounds (Guidelines §16).
- [ ] **No `git add`, no `git commit`, no `git push`** — files unstaged, no branches switched, no hooks skipped.

---

## When to Use This Skill

- After Planning Architect has produced and the user has approved a plan.
- For any code change that must clear the project's quality gates before review.

---

_Skill Version: v4.0 — Genericized: every command resolved from the Project Profile (Guidelines §5) and printed as a real value in the summary; the summary template became a gate table led by status + next action per the reply protocol. The three propagation protocols are consolidated and generalized — A (shared data shape) now covers any schema/form/serialization stack, B (public API & test doubles) is stated in terms of hand-maintained name lists rather than one spy framework, C (external origins & configuration) generalizes the CSP-in-two-places rule to any duplicated policy or env declaration, keeping the "consistently broken renders identically, so visual gates pass" blind spot. Adds a Design Architect step for UI work, bounded-passes ceiling, and an explicit trivial-change exception to the plan gate. Prior v3.6 — service-API + CSP protocols added, field protocol reframed field-agnostic; v3.5 — YAGNI + one-liners in the procedure_
