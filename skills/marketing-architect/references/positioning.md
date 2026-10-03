# Reference: Positioning

*`marketing-architect` reference. Read for `position`, and before any other mode emits — Constraint 7 gates on §2.*

## Positioning

### 1. The One Sentence

Everything else in this skill is downstream of one sentence a stranger can repeat back. Write it in this shape and resist decorating it:

> **`<name>`** is a **`<category the reader already has a slot for>`** for **`<the specific person>`** who **`<the situation they are in>`**. Instead of **`<what they do today>`**, it **`<the one thing it does differently>`**.

Four rules that do most of the work:

1. **The category is borrowed, not invented.** A reader with no slot for your category files you under "unclear" and leaves. Pick the nearest existing one and be the interesting thing *inside* it. Inventing a category is a strategy for a company with a budget to teach the market one; it is not a strategy for a launch.
2. **"Instead of" is mandatory, and it is usually not a competitor.** The real alternative is a manual process, a spreadsheet, a script they already wrote, or doing nothing. Naming it is what makes the value concrete, and getting it wrong is the most common positioning error.
3. **The specific person, not the addressable market.** "Teams shipping a mobile app on a two-week cadence" is a position. "Developers" is a demographic, and it converts like one.
4. **No adjective carries meaning here.** Fast, simple, powerful, modern, seamless, and intuitive are claims the reader discounts on sight. Replace each with the fact that made you write it, or delete it.

### 2. The First-Screen Test *(the gate)*

Open the actual landing surface — the README's rendered top, the site above the fold, the store listing's visible portion, whatever a stranger genuinely hits first. Then answer, from **only what is visible there**, without scrolling and without prior knowledge:

- [ ] **What is this?** — the category, in the reader's vocabulary.
- [ ] **Who is it for?** — specific enough that some readers correctly conclude "not me".
- [ ] **What does it replace?** — the alternative, named.
- [ ] **What does it look like working?** — a command, a screenshot, a short clip, an example of the real output. Not an architecture diagram.
- [ ] **What do I do next?** — one action, unambiguous, with nothing between the reader and seeing it work.
- [ ] **Why trust it?** — maintained, licensed, and someone is visibly home.

**Any unchecked box is a finding, and it outranks every channel question in the run** (`SKILL.md` Constraint 7). Report it in the shape `module-findings` gives you, naming the surface and the missing element, and emit the rewrite rather than a critique of it.

**Why this is a gate and not advice:** traffic multiplies whatever the surface converts at. A launch spent on a first screen that fails three of these does not merely underperform — it consumes the one look that audience will give the project, and the same people do not come back when it is fixed.

### 3. Reading Your Own Surface Honestly

You cannot un-know the project, and neither can the user. Three techniques that work anyway:

- **The stranger constraint.** Judge only the visible region. The sentence that explains everything, three screens down, does not exist.
- **The substitution test.** Replace the project's name with a competitor's throughout the first screen. If it still reads as true, the copy describes the category rather than this thing, and it is not positioning.
- **The "so what" pass.** Ask it once after each opening claim. A claim that cannot answer is a feature listed too early — it belongs below, once the reader has a reason to care.

### 4. What Positioning Cannot Fix

Say this plainly when it applies, instead of producing copy that papers over it. If the thing does not work, is not maintained, or solves a problem the named person does not actually have, the sentence will be accurate and will not help. A positioning run that concludes *the problem is upstream of this* is finished work, and the honest handoff is to `product-architect`.

---
