---
name: design-architect
description: Load before creating, redesigning, auditing, polishing, or studying any user-facing surface — a screen, page, component, form, empty state, or visual system — and before shipping a UI-visible change. Produces a direction brief before code (structure, palette, type pairing, signature moment), then holds the built result to the craft floor and the refuse list.
argument-hint: "[target screen or component] [+ mode: audit | redesign | polish | study | establish]"
---

# Skill: Design Architect — Interface Craft & Anti-Slop

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Profile section owned:** §Design (Guidelines §5.1–§5.4). If the project has no UI yet, or none worth matching, **establish** the visual world: run §2, propose the brief, and record it once the user agrees.

**The problem this exists to solve:** models trained on the same templates emit the same page — same display font, same purple-to-blue gradient, same three equal cards, same four-column footer. Competent and anonymous. Everything below aims at one outcome: the result looks like *this brief*, not like a generated page that happens to carry this brief's words.

---

## Operational Constraints

1. **The brief wins.** Honor pinned aesthetics, eras, materials, fonts, and palettes even when they collide with a warning below. Redirecting a clear brief toward your own taste is failure, not judgment.
2. **The project's committed world wins over the catalog.** If the codebase already has tokens, a component library, or a design doc, that is the system. Extend it; don't import a new aesthetic mid-feature. **A missing design doc is not proof of a greenfield** — scaffolding from a starter template, or three screens someone built quickly, is still evidence of intent. Only when there is genuinely nothing to preserve do you switch to Establish mode and decide rather than match.
3. **Refinement preserves; redesign replaces.** Refinement keeps identity, behavior, and copy, and touches nothing outside scope. Redesign keeps product truth, content, and function but treats the old look as evidence and anti-reference. **Never split the difference.**
4. **No fabricated content** (Guidelines §15). No invented metric, testimonial, logo, customer count, or claim. If a layout needs a number the user didn't supply, use a labelled placeholder or drop the slot.
5. **Bounded passes** (Guidelines §16). Build fully → one batched inspection (every viewport and theme in one round) → one fix batch → at most one confirm round → stop.
6. **Read before writing.** Inspect the target file and at least one source of existing visual truth (token file, theme, a sibling component) before editing anything.
7. **Direction before code.** No markup or styles are written until the §2 brief exists. A stamp with no brief behind it is a defect.

---

## What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/modes.md` | First — deciding what this invocation is: design, audit, redesign, study, polish, or establish. |
| `${CLAUDE_SKILL_DIR}/references/structures.md` | §2 step 2 — picking the page or screen shape by name. |
| `${CLAUDE_SKILL_DIR}/references/palette-and-type.md` | §2 step 3 — deriving the palette and choosing the type pairing. |
| `${CLAUDE_SKILL_DIR}/references/direction-brief.md` | §2 step 5 — the ten-line brief template and a filled example. |
| `module-craft-floor` | §3, always, on the built result. |
| `${CLAUDE_SKILL_DIR}/references/refuse-list.md` | Before emitting. The AI-default patterns, each with what to do instead. |
| `module-operability-floor` | Anything interactive: a dialog, menu, tab set, combobox, drag, or async status. |

---

## 1. Pick the Mode First

The mode names what success looks like **for the visitor on this surface** — not for the product overall. A developer tool's landing page is still Persuade; a fashion house's docs are still Read.

| Mode | Visitor's success | Surfaces | What outranks what |
|---|---|---|---|
| **Persuade** | Decides and acts | Landing, marketing, pricing, campaign | Design *is* the product. Earn attention, then action. |
| **Operate** | Completes a task | App UI, dashboards, editors, admin, settings | Scanability, consistency, platform expectations. Brand lives in precise details, not expression. |
| **Read** | Understands something | Docs, articles, guides, changelogs | Structure for comprehension first, then make the reading worth staying in. |
| **Experience** | Is inside the work | Portfolios, galleries, showcases | The artifact leads from the first viewport; the interface recedes. |

State the mode in one line: `mode: Operate — a settings screen; scanability outranks expression.` Wrong mode is the most expensive error here — an Operate screen designed in Persuade mode is the classic "beautiful dashboard nobody can use".

---

## 2. Direction — the brief before the code

The mode says what wins; this says what the page *is*. Six steps, in order, producing a ten-line brief that is emitted before any markup.

1. **Ground in the subject.** From the brief and the codebase: who arrives, in what state; the one primary task; and the product's **material world** — its industry, its objects, its era — in three to five nouns. The aesthetic comes from those nouns, never from the category's habit.
2. **Pick a structure by name** from `references/structures.md`. Say where the weight sits and what divides sections. It must differ from the last stamp in this project.
3. **Derive the palette and choose the type pairing** per `references/palette-and-type.md`: anchor hue from the material world, paper lightness from the use scene, roles not swatches; a display face chosen by tone, a body face chosen by measure.
4. **Name the signature moment** — the one thing a visitor would describe afterwards. One per surface. Motion, accent, and the largest type are spent on it and nowhere else.
5. **Emit the brief** in the template at `references/direction-brief.md`. Establish writes it to the profile's §Design; Study fills it from the reference.
6. **Run the generic test.** Could this brief serve a competitor's product unchanged? If yes, step 1 was skipped — redo it before building.

---

## 3. The Craft Floor

The mechanics a surface cannot fall below — contrast, spacing, type, depth, motion, states, target size, browser surfaces, copy, responsive range, token discipline — live in the `module-craft-floor` skill. Load it and run it on the **built result**, in one batched inspection covering every viewport and every theme the project ships.

The floor never picks the direction; §1 and §2 do that. It only stops the result from being wrong in ways that are not a matter of taste.

---

## 4. Variety (against your own previous output)

Two designs in the same project that differ only in color are the same design. Before emitting:

1. Read what this project already looks like — sibling screens, the design doc, the last stamp.
2. If the structure repeats a previous one, change the **structure**, not a cosmetic; then change at least one of palette or type.
3. Leave the stamp at the top of the file, recording the brief's short form and the self-critique scores:
   `/* structure: split-column · palette: copper/light · type: Fraunces/Inter · signature: roast-date display · critique P5 H4 E5 S4 R5 V4 */`
   Future runs read it to avoid repeating a fingerprint or a weakness.

Variety is scored on structure first, then palette and type. A color swap alone is not variety.

---

## 5. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) **first**; anything under 3 gets one revision pass. Then confirm every line below is clean:

- [ ] Mode stated, and the design serves it (§1).
- [ ] Direction brief emitted before code; every field filled; generic test passed (§2).
- [ ] Craft floor verified on the built result (`module-craft-floor`) — contrast computed, states present, responsive range checked, browser surfaces themed.
- [ ] Refuse list swept — anything present is there because the brief earned it, and you can say which words earned it.
- [ ] Every color and font references a token; nothing improvised mid-file.
- [ ] No invented metric, claim, logo, or testimonial (Guidelines §15).
- [ ] Structure differs from the last output in this project; stamp written (§4).
- [ ] Decorative SVG/canvas labelled or hidden; motion has reduced-motion fallbacks; keyboard focus reaches everything, is visible, and is not covered by a sticky header when it lands.
- [ ] Anything interactive — dialog, menu, tab set, combobox, drag, async status — cleared `module-operability-floor` via the `accessibility-architect` skill. The craft floor covers how it looks; that one covers whether it can be operated.
- [ ] Verification stayed within two rounds (Guidelines §16).

If a gate fails, fix it. Don't ship slop.

---

_v2.0 — direction step added; history in CHANGELOG.md. Distills pbakaus/impeccable (Apache 2.0) and nutlope/hallmark (MIT)._
