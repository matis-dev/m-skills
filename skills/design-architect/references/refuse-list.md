# Reference: The Refuse List

*`design-architect` reference — read before emitting.*

These are the category's defaults — the shape that appears when nobody decided. **The brief's own words can earn any of them back.** Reaching for one when the axis was free means you weren't deciding. Each line names the default, then what to do instead.

**Page scaffolds**
- Three-or-more equal cards of icon + heading + text as the page's structure → pick a structure from `structures.md` where the weight sits somewhere. A card inside a card is always wrong.
- The generic template, hero → three features → CTA → footer → let the §2 structure dictate the sequence; the first fold carries the signature moment, not a summary of the page.
- The default nav (wordmark left, four inline links, button right, hairline border) and the default footer (four link columns + social row + tiny copyright) → give the nav one deliberate move (a rail, a single link, the wordmark as type) and let the footer carry one thing that matters (colophon, contact, the next step).
- Hero with everything on one centred axis at full viewport height → pick at most two centred elements; break alignment for the rest.
- The hero-metric template: giant number, small label, supporting stats → lead with the most characteristic element (headline, image, interaction); a bare figure is never the hero's only headline.
- A modal for a task needing neither interruption nor protected focus → inline disclosure, a side panel, or a new route.
- A page stripped of ornament and given nothing in its place — thin sections, empty screens → removing ornament leaves space; fill it with scale (the main thing larger), the full content, or a real picture of the subject's world. One deliberate rest per page.
- The stock close: an email sign-up as the last section on a page whose job is not subscribing → end on the page's own next step (book, buy, visit, install).
- The echo: one fact (a price, a date, a count) printed in section after section, or a section's last line restating its heading → state each fact once, where it decides something.
- Sections separated only by equal whitespace → divide with a rule, a paper shift, an ornament that names something, or a change of rhythm — and vary which.

**Surface habits**
- Gradient text, and purple-to-blue / cyan-to-magenta gradients generally → emphasis comes from weight, size, or the accent colour.
- Accent color covering more than ~5% of a viewport → the accent owns one region (the primary action, the live figure); it is emphasis, not fill.
- Pure `#000` / `#fff` as base colors, and zero-chroma greys → tint every neutral toward the anchor hue (`palette-and-type.md` steps 2–4).
- Glass and blur as decoration → blur only where something specific sits behind the surface and must stay legible.
- Colored side-stripe borders above 1px on cards, list items, callouts, alerts → a 1px rule, a tinted surface, or an icon with a label.
- Hard zero-blur offset shadows outside a world that actually chose neobrutalism → shadows carry an offset and a soft blur; declare elevation once.
- Emoji or unicode glyphs standing in for icons; two icon libraries on one page → pick one library or draw the SVG.
- Sketchy/doodle SVG imitating illustration, decorative grain, repeating-stripe and grid-overlay backgrounds with nothing under them → real imagery, or none. (This bans SVG imitating *pictures*, never SVG doing *geometry* — diagrams, linework, and shader effects stay first-class.)
- Monospace as a costume for "technical" → monospace for code, data, and measurement only.
- The system display face (Impact, Arial Black, the platform sans) as the display voice → choose a display face by tone from `palette-and-type.md` and load it; the closest installed font is a failure, not a fallback.
- Redrawn UI chrome — a fake browser bar with traffic lights, a fake phone frame, a fake terminal — and a built mock of a product that exists and can be run → a real screenshot of the running product, or let the content stand alone. One of the strongest "looks generated" tells.
- Loaded symbols as decoration — emblems tied to militarism, supremacy, or hate movements (the Rising Sun rays, the Confederate battle flag, Nazi-era insignia and their stylised variants) taken from a subject's world as motif or badge → that world's neutral forms. Content documenting such a symbol as fact stays as it is. The brief cannot earn this one back.
- The eyebrow — short inert type above a heading that announces it — and labels, tags, captions, or nav links in tracked capitals or small caps → the heading carries itself; labels take the body face a step smaller, sentence case, untracked.
- Template punctuation: meta strings joined by middle dots (`A · B · C`), an arrow glued to link text (`Learn more →`), decorative status dots before labels → a plain sentence or a real list; the link names where it goes.
- The accented word: one word in a heading set apart by italic, colour, a highlight, or an underline → set the whole heading one way; the emphasis is in what it says.
- A form or control that confirms success ("Sent", "You're on the list") with no request behind it → wire the real request, or leave the endpoint visibly unset. The brief cannot earn this one back.
- Decoration with no semantic anchor: a floating cursor, a corner number meaning nothing, an ornament naming nothing → decoration is motivated by the content, or removed.
- Placeholder names (Jane Doe, Acme, Nexus) and startup-cliché verbs (Unleash, Seamless, Supercharge) → the product's own names and the visitor's own verbs; a labelled placeholder where the user supplied none.
- Light or dark chosen by category habit → choose from the actual use scene — who, where, under what ambient light (`palette-and-type.md` step 2).
