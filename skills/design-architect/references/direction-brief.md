# Reference: The Direction Brief

*`design-architect` reference — read at §2 step 5. Emitted before any code. Establish writes it to the profile's §Design; Study fills it from a reference.*

Ten lines. Every field is filled, or the run stops and asks. A blank `world:` means step 1 was skipped; an empty `signature:` means the design has no point of view yet.

## Template

```
/* direction
surface:   <page/component> · mode: <Persuade|Operate|Read|Experience>
visitor:   <who arrives, in what state> · task: <the one primary thing>
world:     <material world — industry, objects, era; 3–5 nouns>
structure: <name from structures.md> · weight: <where> · divides: <rule|shift|ornament|space>
palette:   anchor <hue> · paper <light|dim|dark, by use scene> · accent owns <one region>
type:      <display> / <body> · tone: <one of 7 families>
signature: <the one thing a visitor describes afterwards>
refuses:   <2–3 defaults this brief does not earn>
source:    <profile §Design | reference <url/file> | established this run>
*/
```

## Filled example *(fictional product — an illustration, carrying no figures)*

Brief: "Landing page for Kettle & Crane, a two-person coffee roaster selling subscriptions. They roast in a former boatyard."

```
/* direction
surface:   landing page · mode: Persuade
visitor:   someone who already buys good coffee, on a phone, deciding whether to switch · task: start a subscription
world:     copper kettle, burlap, chalk board, boatyard timber, tide tables
structure: split-column · weight: left third, the roast-date claim in display type · divides: hairline rule + paper shift per section
palette:   anchor copper (oklch 62% 0.14 55) · paper light, tinted warm — read outdoors · accent owns the one "Start a subscription" action
type:      Fraunces / Inter · tone: editorial
signature: this week's roast date and origin set in the largest type on the page, changing per batch
refuses:   three equal feature cards · a hero metric · a testimonial carousel
source:    established this run
*/
```

The generic test on this example: swap "Kettle & Crane" for any other roaster and the `world:` and `signature:` lines break. That is what makes it this brief rather than the category's.

## How each mode uses it

- **Design / build** — emit, then build to it. The stamp comment at the top of the file is the brief's short form.
- **Establish** — emit, ask one question ("keep, or adjust?"), then write the block into the profile's §Design. From then on it is the committed world.
- **Study** — fill every field from the reference; set `source:` to the URL or file. Structure and type come from what the reference *does*, not what it says about itself.
- **Redesign** — a new brief; the old stamp is the anti-reference. It must differ on `structure:` and on at least one of `palette:` / `type:`.
- **Audit / Polish** — read the existing brief or stamp first; a missing one is the first finding.
