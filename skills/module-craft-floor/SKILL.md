---
name: module-craft-floor
description: "Module — loaded by name from an m-skills architect, not an entry point. The craft floor for any rendered interface: contrast, spacing, type, depth, motion, states, target size, browser surfaces, copy, and the responsive range — checked on the built result, not on intentions."
user-invocable: false
---

# Module: The Craft Floor

**Loaded by:** `design-architect` · `code-review-architect` · `accessibility-architect` · `maintenance-architect` · `search-optimization-architect`. Read it whenever a run judges a rendered surface; do not restate its content in a skill file.

**What this is:** the floor a user-facing surface cannot fall below, regardless of direction, brief, or framework. It holds the *mechanics*; it never picks the direction — that is `design-architect`'s §1 mode selection and the brief.

**How to run it:** on the **built result**, in one batched inspection round covering every viewport and every theme the project ships. Read the *computed* values; do not trust the source. Two rounds maximum (Guidelines §16).

---

- **Contrast** — body and placeholder text ≥ 4.5:1, large text / icons / focus rings ≥ 3:1, against the *computed* background. The failures that actually ship: text inheriting a color after its container switched surface; muted text on a tinted surface; **button text within a hair of its own fill** (the black-on-black bug); a dark section that swapped its background but not its text color. Any surface that takes an accent fill needs a defined, verified ink color for text on it.
- **Spacing** — tight within groups, generous between them; more space above a heading than below it. Every value on the named scale — an arbitrary `17px` is a tell.
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

## Token discipline

Any color or font declared outside the token block is a defect. Pick the system at the top of the run and consume it; a one-off hex halfway down is the model forgetting its own decision. Lift the value into a named token, or replace it with an existing one.

## Where the floor ends

The floor covers **how a surface looks and behaves**. Whether it can be *operated at all* — semantics, focus architecture, announcement — is the operability floor, and the two share their edges: contrast, focus-visible, target size, states, and reduced motion are decided here as design decisions, then relied on there. Where a visual decision and operability genuinely collide, the answer is a third option, not an ultimatum.
