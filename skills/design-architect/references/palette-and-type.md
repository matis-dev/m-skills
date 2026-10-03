# Reference: Palette and Type

*`design-architect` reference — read at §2 step 3. A construction method, not a catalog: the anchor comes from the product; everything else is derived from it.*

## Palette — build roles, not a bag of swatches

Build in this order. Each step derives from the one before, so the palette is decided once and reads as one system.

1. **Anchor hue** — from the material world named in §2 step 1 (a roaster's copper, a ledger's slate, a clinic's linen), never from the category's habit. One chromatic anchor, OKLCH chroma roughly 0.12–0.20.
2. **Paper** — canvas lightness, chosen by the use scene (who, where, under what light): bright L 95–98 for daylight marketing; archival L 92–95 for long reading; technical L 98–100 for dense operate surfaces; dark L 12–18 for dim rooms, media, night-use tools. Tint paper toward the anchor (chroma 0.005–0.02). Never pure `#fff` or `#000`.
3. **Ink** — stepped from paper, not picked: light paper → ink near L 15–25; dark paper → ink near L 90–96. Tinted toward the anchor like paper.
4. **Two or three greys** — steps of 6–10 L between paper and ink, for secondary text, borders, disabled. Every one carries chroma > 0.
5. **Accent** — the anchor at full chroma. It owns **one deliberate region** per surface (the primary action, the one live figure, the current item), never a scatter of highlights. Under ~5% of any viewport.
6. **Accent-ink** — the text colour on accent, chosen (paper or ink) and **verified** ≥ 4.5:1 before anything is built. Deciding this up front is what prevents button text vanishing into its own fill.
7. **Focus** — the anchor hue at chroma 0.18–0.22, visible on both paper and accent.
8. **Semantic four** — success, warning, danger, info. Distinct in lightness as well as hue, so colour is never the only channel; each with its own verified ink.

Roles the token block must name: `canvas`, `surface`, `text`, `text-muted`, `text-faint`, `action`, `action-ink`, `border`, `focus`, `success`, `warning`, `danger`, `info`. A dark theme is built in the same order, never inverted from the light one.

Prefer OKLCH; convert to hex only where the stack requires it. Every value lives in the token block — a colour declared elsewhere is a defect.

## Type — a pairing chosen for this brief

**The 2+1 rule:** one display face, one body face, at most one outlier in no more than two slots (code, data, a label). Same family at two weights counts once. **The closest installed font is a failure, not a fallback** — pick a face, load it, and give it a metric-compatible fallback.

Pick the display face by **tone**, from the material world; pick the body face by **measure and density**. Mixing tones across the pair is where character comes from.

| Tone | Display faces (free) | Pairs with (body) | Reads as |
|---|---|---|---|
| **Editorial** | Fraunces · Newsreader · Playfair Display | Source Serif 4 · Inter · IBM Plex Sans | considered, written, unhurried |
| **Technical** | Space Grotesk · IBM Plex Sans · Geist | IBM Plex Sans · Inter · Geist Mono for data | precise, instrumented |
| **Brutalist** | Archivo Black · Bricolage Grotesque · Syne | Archivo · Work Sans | blunt, loud, unpolished on purpose |
| **Soft** | Nunito · Quicksand · DM Sans | DM Sans · Nunito Sans | friendly, rounded, low-stakes |
| **Luxury** | Cormorant Garamond · Bodoni Moda · Libre Caslon Display | Libre Caslon Text · EB Garamond | restrained, expensive, high-contrast |
| **Playful** | Bricolage Grotesque · Gloock · Rubik | Rubik · Karla | energetic, irregular |
| **Austere** | Instrument Sans · Manrope · Schibsted Grotesk | Manrope · Inter | quiet, gridded, Swiss |

Rules that decide the rest:

- **Headings are roman.** Emphasis comes from weight, size, or accent — never italic display type, never one accented word inside a headline.
- **Hero size by headline length:** up to 50 characters at the largest step; 51–90 one step down; over 90, rewrite it shorter.
- **Body measure 45–75ch**; line-height rises as the measure widens and again on dark paper.
- **A scale of five or six steps** with obvious jumps (ratio 1.25–1.333). Every size sits on the scale; none is improvised.
- **Section labels default off.** A tracked all-caps eyebrow above every heading is a tell; use one only where the content is genuinely a category.
- **Monospace is for code, data, and measurement** — never a costume for "technical".

The stamp records the pair: `type: Fraunces / Inter · tone: editorial`.
