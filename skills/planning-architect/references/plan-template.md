# Reference: The Plan Document Format

*`planning-architect` reference — read when the run needs it.*

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
