---
name: design-architect
description: Design and review any user-facing interface so it reads as built rather than generated. Use when creating, redesigning, auditing, polishing, or critiquing a screen, page, component, form, empty state, or visual system — and before shipping any UI-visible change. Covers visitor mode selection, the craft floor (contrast, spacing, type, motion, states, browser surfaces, copy), the refuse-list of AI-default patterns, slop gates run before emitting, token discipline, honest copy with no invented metrics, and structural variety against previous outputs. Cited by planning-architect, implementing-architect, and code-review-architect for UI work.
argument-hint: "[target screen or component] [+ mode: audit | redesign | polish | study]"
---

# Skill: Design Architect — Interface Craft & Anti-Slop

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("audit", "redesign", "polish", "study", "establish") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Design (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo for the answers first** — then ask at most 3–4 questions covering only what the code cannot say, and write it back. A question the repo already answers is a defect (Guidelines §5.3); so is deferring a row whose answer sits in a file you didn't open. If the project has no UI yet, or none worth matching, **establish** the visual world (§1 mode + a token set + a component vocabulary), propose it with a one-line rationale, and record it once the user agrees.

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

Checks on the **built result**, not on intentions. Run them together in the batched inspection round — they share one render. The floor holds the mechanics; it never picks the direction.

- **Contrast** — body and placeholder text ≥ 4.5:1, large text / icons / focus rings ≥ 3:1, against the *computed* background. The failures that actually ship: text inheriting a color after its container switched surface; muted text on a tinted surface; **button text within a hair of its own fill** (the black-on-black bug); a dark section that swapped its background but not its text color. Any surface that takes an accent fill needs a defined, verified ink color for text on it.
- **Spacing** — tight within groups, generous between them; more space above a heading than below it. Every value on the named scale — an arbitrary `17px` is a tell. Read the computed values; don't trust the source.
- **Type** — body measure 45–75ch. Three font families is the hard ceiling (display + body + at most one outlier used in no more than two slots); same family at different weights counts once. Obvious scale and weight steps. Headings are roman — italic display type is a top tell. All-caps display keeps `line-height ≥ 1.0` or the cap-tops collide on wrap. Run the **real** copy at every breakpoint and fix what overflows.
- **Depth** — shadows carry an offset *and* a soft blur. A zero-offset colored halo is decoration, not depth. Declare elevation once: border **or** shadow, not a hairline border under a wide soft shadow.
- **Motion** — one authored moment, not scattered effects, and not one identical entrance on every section. Never `transition: all`. Never animate layout properties (`width`, `height`, `top`, `left`, `margin`, `padding`). Focus rings appear instantly — never fade in. One hover effect per element, not four. Every keyframe needs a reduced-motion fallback.
- **States** — default, hover, focus-visible, active, disabled, loading, error, empty. Inputs are where almost-right UIs lose: border-width must not change between states (it shifts layout), the focus ring is an outline not a border, input height matches the button beside it, the helper-text slot reserves its space so an error doesn't shove the page down, and disabled needs three channels (dimmed + cursor + the real disabled attribute).
- **Targets** — every interactive element is at least **24×24**, or spaced so 24px circles around adjacent targets don't overlap. The hit area may exceed the visual box, so this is usually invisible padding rather than a bigger button. Icon-only controls in dense tables are where this fails, and the adjacent control is often destructive.
- **Browser surfaces** — the parts you didn't draw still carry the design: text selection, caret, scrollbars, focus rings, underline offset, tabular numerals. They ship with defaults belonging to no design system. Theme them from the palette. **This is the cheapest signal that a page was built rather than assembled, and the one most reliably skipped.**
- **Copy** — the product's own language. Controls name their action; errors name the problem *and* the recovery.
- **Responsive** — no horizontal scroll at any width from 320px to 1920px. Clickable text (buttons, nav links, CTAs) **never wraps to two lines** — shorten the label or prevent the wrap. Image-bearing flex/grid tracks need an explicit zero minimum or the intrinsic image width blows past the viewport. Display headings need a last-resort break-inside-word rule for long compound words.
- **Coverage** — every brief requirement present and findable within seconds.

---

## 3. The Refuse List

These are the category's defaults — the shape that appears when nobody decided. **The brief's own words can earn any of them back.** Reaching for one when the axis was free means you weren't deciding.

**Page scaffolds**
- Three-or-more equal cards of icon + heading + text as the page's structure. Cards are the lazy container; a card inside a card is always wrong.
- The generic template: hero → three features → CTA → footer.
- The default nav (wordmark left, four inline links, button right, hairline border) and the default footer (four link columns + social row + tiny copyright).
- Hero with everything on one centred axis at full viewport height. Pick at most two centred elements; break alignment for the rest.
- The hero-metric template: giant number, small label, supporting stats. A bare figure is never the hero's only headline.
- A modal for a task needing neither interruption nor protected focus.
- Sections separated only by equal whitespace — identical rhythm, no rule, no shift, no ornament.

**Surface habits**
- Gradient text, and purple-to-blue / cyan-to-magenta gradients generally. Emphasis comes from weight, size, or accent color.
- Accent color covering more than ~5% of a viewport. Accent is emphasis, not fill.
- Pure `#000` / `#fff` as base colors, and zero-chroma greys — tint neutrals toward the anchor hue.
- Glass and blur as decoration rather than as a specific effect.
- Colored side-stripe borders above 1px on cards, list items, callouts, alerts.
- Hard zero-blur offset shadows outside a world that actually chose neobrutalism.
- Emoji or unicode glyphs standing in for icons; mixing two icon libraries on one page. Pick one library or draw the SVG.
- Sketchy/doodle SVG imitating illustration, decorative grain, repeating-stripe and grid-overlay backgrounds with nothing under them. (This bans SVG imitating *pictures*, never SVG doing *geometry* — diagrams, linework, and shader effects stay first-class.)
- Monospace as a costume for "technical" rather than for code, data, or measurement.
- The system display face (Impact, Arial Black, the platform sans) as the display voice. The closest installed font is a failure, not a fallback.
- Redrawn UI chrome — a fake browser bar with traffic lights, a fake phone frame, a fake terminal or IDE window. Use a real screenshot or let the content stand alone. This is one of the strongest "looks generated" tells.
- Decoration with no semantic anchor: a floating cursor, a number in the corner meaning nothing, an ornament that names nothing. Decoration must be motivated by the content.
- Placeholder names (Jane Doe, Acme, Nexus) and startup-cliché verbs (Unleash, Seamless, Supercharge).
- Light or dark chosen by category habit rather than from the actual use scene — who, where, under what ambient light.

**Token discipline**
- Any color or font declared outside the token block. Pick the system at the top of the run and consume it; a one-off hex halfway down is the model forgetting its own decision. Lift the value into a named token or replace it with an existing one.

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
- [ ] Craft floor (§2) verified on the built result — contrast computed, states present, responsive range checked, browser surfaces themed.
- [ ] Refuse list (§3) swept — anything present is there because the brief earned it, and you can say which words earned it.
- [ ] Every color and font references a token; nothing improvised mid-file.
- [ ] No invented metric, claim, logo, or testimonial (Guidelines §15).
- [ ] Structure differs from the last output in this project (§4), stamp comment written.
- [ ] Accessibility: decorative SVG/canvas carries a label or is explicitly hidden; motion has reduced-motion fallbacks; keyboard focus reaches everything, is visible, and isn't covered by a sticky header when it lands.
- [ ] Anything interactive beyond the floor — a dialog, menu, tab set, combobox, drag interaction, or async status — went through the `accessibility-architect` skill. The floor covers how it looks; that one covers whether it can be operated.
- [ ] Verification stayed within two rounds (Guidelines §16).

If a gate fails, fix it. Don't ship slop.

---

## 6. Modes of Invocation

| Ask | What this skill does |
|---|---|
| **Design / build** a surface | Mode → direction → build → §5 sweep. |
| **Audit** existing UI | Run §2 and §3 over the target read-only; report findings with `path:line`, severity, and the concrete fix. Write nothing. |
| **Redesign** | Constraint 3 applies: keep product truth, replace the visual world outright, update the project's design doc to match. |
| **Study** a reference the user admires | Extract the DNA — palette, type pairing, structural rhythm, what it refuses — into tokens and a named structure. Once extracted, that DNA **is** the system for this project; don't drift back to a generic default later in the same session. |
| **Polish** | The floor only. No new direction, no scope growth. |
| **Establish** *(greenfield)* | No UI exists yet, or what exists is placeholder scaffolding. Don't match it — **decide** the world: mode, palette and tokens, type pairing, component vocabulary, and what this project refuses. Propose it in one short block with a rationale, get agreement, then write it to the profile's §Design. From then on it is the committed world and constraint 2 applies to it like any other. |

---

## Relationship to Other Skills

- **Guidelines (Meta)** — every principle here inherits from it, especially §15 honesty, §16 bounded passes, §18 self-critique.
- **Planning Architect** — cite this skill in any plan step touching UI; the plan names the mode and the design system components used.
- **Implementing Architect** — apply §2 and §5 before declaring a UI change done.
- **Code Review Architect** — the §3 refuse list and §2 floor are the UI findings source; cite `path:line` like any other finding.
- **Testing Architect** — visual and a11y coverage for what this skill produces.
- **Accessibility Architect** — shares this floor. Contrast, focus-visible, target size, states, and reduced motion stay here as design decisions; semantics, focus architecture, and announcement live there. Where a design choice and the operability floor genuinely collide, that skill's Constraint 5 applies: bring a third option, not an ultimatum.

---

_Skill Version: v1.0 — New skill. Distills pbakaus/impeccable (visitor modes, craft floor, refuse list, brief-wins, refinement-vs-redesign, bounded verification, browser surfaces) and nutlope/hallmark (slop gates, structural-fingerprint variety, token discipline, honest copy, pre-emit self-critique, redrawn-chrome and icon tells) into one framework-agnostic skill. Every rule targets the rendered result, so it applies to any stack; the project's own design system, resolved from the Project Profile, always outranks anything in the catalog here._
