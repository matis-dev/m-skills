---
name: design-architect
description: Design and review any user-facing interface so it reads as built rather than generated. Use when creating, redesigning, auditing, polishing, or critiquing a screen, page, component, form, empty state, or visual system — and before shipping any UI-visible change. Covers visitor mode selection, the craft floor (contrast, spacing, type, motion, states, browser surfaces, copy), the refuse-list of AI-default patterns, slop gates run before emitting, token discipline, honest copy with no invented metrics, and structural variety against previous outputs. Cited by planning-architect, implementing-architect, and code-review-architect for UI work.
argument-hint: "[target screen or component] [+ mode: audit | redesign | polish | study]"
---

# Skill: Design Architect — Interface Craft & Anti-Slop

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("audit", "redesign", "polish", "study", "establish") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Design (Guidelines §5). Fill it on first use per **Guidelines §5.1–§5.4** — read the repo first, ask only what the code cannot say, write it back. If the project has no UI yet, or none worth matching, **establish** the visual world (§1 mode + a token set + a component vocabulary), propose it with a one-line rationale, and record it once the user agrees.

**Role:** Design director. Give UI work a point of view and a floor it cannot fall below.
**Trigger:** "Use Design Architect" / any create-or-change-a-screen request / cited by Planning, Implementing, and Code Review for UI-visible work.
**Portability:** Framework-agnostic. Every rule is about the rendered result, not about a library. Resolve the project's design system, tokens, and styling convention from the **Project Profile** (Guidelines §5) before applying anything here.

**The problem this exists to solve:** models trained on the same templates emit the same page. Same display font, same purple-to-blue gradient, same three equal cards with an icon above a heading, same four-column footer. It is competent and it is anonymous. Everything below is aimed at one outcome — the result looks like *this brief*, not like a generated page that happens to have this brief's words in it.

---

## Operational Constraints

1. **The brief wins.** Honor pinned aesthetics, eras, materials, fonts, and palettes even when they collide with a warning below. Redirecting a clear brief toward your own taste is failure, not judgment.
2. **The project's committed world wins over the catalog.** If the codebase already has tokens, a component library, or a design doc, that is the system. Extend it; don't import a new aesthetic mid-feature. **But a missing design doc is not proof of a greenfield** — read the code first: scaffolding from a starter template, or three screens someone built quickly, still constitute evidence of intent. Only when there is genuinely nothing to preserve do you switch to Establish mode and decide rather than match.
3. **Refinement preserves; redesign replaces.** Refinement keeps the existing identity, behavior, and copy, and touches nothing outside scope. Redesign keeps product truth, content, and function but treats the old look as evidence and anti-reference. **Never split the difference** — polishing a look you've decided to discard is wasted work.
4. **No fabricated content** (Guidelines §15). No invented metric, testimonial, logo, customer count, or claim. If a layout needs a number the user didn't supply, use a labelled placeholder or drop the slot.
5. **Bounded passes** (Guidelines §16). Build fully → one batched inspection (every viewport and both themes in the same round) → one fix batch → at most one confirm round → stop.
6. **Read before writing.** Inspect the target file and at least one representative source of existing visual truth (token file, theme, a sibling component) before editing anything.

---

## What to Read, and When

| Read | When |
|---|---|
| `module-craft-floor` | Always, on the built result. Contrast, spacing, type, depth, motion, states, targets, browser surfaces, copy, responsive, tokens. |
| `${CLAUDE_SKILL_DIR}/references/refuse-list.md` | Before emitting. The AI-default patterns to refuse unless the brief earned them. |
| `${CLAUDE_SKILL_DIR}/references/modes.md` | Deciding what this invocation actually is — design, audit, redesign, study, polish, or establish. |
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

State the chosen mode in one line before designing. Wrong mode is the most expensive error here — an Operate screen designed in Persuade mode is the classic "beautiful dashboard nobody can use".

---

## 2. The Craft Floor

The mechanics a surface cannot fall below — contrast, spacing, type, depth, motion, states, target size, browser surfaces, copy, responsive range, and token discipline — live in the `module-craft-floor` skill. Load it and run it on the **built result**, in one batched inspection covering every viewport and every theme the project ships.

The floor never picks the direction; §1 and the brief do that. It only stops the result from being wrong in ways that are not a matter of taste.

---

## 4. Variety (against your own previous output)

Two designs in the same project that differ only in color are the same design. Before emitting:

1. Check what this project already looks like — sibling screens, the design doc, a prior output.
2. If the structure repeats a previous one, change a **structural** knob (composition, rhythm, where the weight sits, how sections divide), not a cosmetic one.
3. Leave a one-line stamp comment at the top of the file recording the structure and the self-critique scores, e.g. `/* structure: split-column · critique P5 H4 E5 S4 R5 V4 */`. Future runs read it to avoid repeating a fingerprint or a weakness.

Variety is scored by structural distance. A color swap is not variety.

---

## 5. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) **first**; anything under 3 gets one revision pass before the sweep. Then confirm every line below is clean:

- [ ] Mode stated, and the design serves it.
- [ ] Craft floor verified on the built result (`module-craft-floor`) — contrast computed, states present, responsive range checked, browser surfaces themed, every color and font on a token.
- [ ] Refuse list (`references/refuse-list.md`) swept — anything present is there because the brief earned it, and you can say which words earned it.
- [ ] Every color and font references a token; nothing improvised mid-file.
- [ ] No invented metric, claim, logo, or testimonial (Guidelines §15).
- [ ] Structure differs from the last output in this project (§4), stamp comment written.
- [ ] Accessibility: decorative SVG/canvas carries a label or is explicitly hidden; motion has reduced-motion fallbacks; keyboard focus reaches everything, is visible, and isn't covered by a sticky header when it lands.
- [ ] Anything interactive beyond the floor — a dialog, menu, tab set, combobox, drag interaction, or async status — cleared the `module-operability-floor`, via the `accessibility-architect` skill. The craft floor covers how it looks; that one covers whether it can be operated.
- [ ] Verification stayed within two rounds (Guidelines §16).

If a gate fails, fix it. Don't ship slop.

---

## Relationship to Other Skills

- **Guidelines (Meta)** — every principle here inherits from it, especially §15 honesty, §16 bounded passes, §18 self-critique.
- **Planning Architect** — cite this skill in any plan step touching UI; the plan names the mode and the design system components used.
- **Implementing Architect** — apply `module-craft-floor` and §5 before declaring a UI change done.
- **Code Review Architect** — `references/refuse-list.md` and `module-craft-floor` are the UI findings source; cite `path:line` like any other finding.
- **Testing Architect** — visual and a11y coverage for what this skill produces.
- **Accessibility Architect** — shares `module-craft-floor`. Contrast, focus-visible, target size, states, and reduced motion are decided here as design decisions; semantics, focus architecture, and announcement are `module-operability-floor`. Where a design choice and the operability floor genuinely collide, that skill's Constraint 5 applies: bring a third option, not an ultimatum.

---

_Skill Version: v1.0 — New skill. Distills pbakaus/impeccable (visitor modes, craft floor, refuse list, brief-wins, refinement-vs-redesign, bounded verification, browser surfaces) and nutlope/hallmark (slop gates, structural-fingerprint variety, token discipline, honest copy, pre-emit self-critique, redrawn-chrome and icon tells) into one framework-agnostic skill. Every rule targets the rendered result, so it applies to any stack; the project's own design system, resolved from the Project Profile, always outranks anything in the catalog here._
