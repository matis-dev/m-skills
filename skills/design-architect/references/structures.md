# Reference: Structures

*`design-architect` reference — read at §2 step 2, before any code. One name per surface; the stamp records it.*

A structure is where the weight sits and how the page divides — chosen before palette or type, because it is the axis a visitor recognises from across the room. Pick by mode and by the material world named in §2 step 1, never by which one you used last. **Two consecutive outputs in one project never share a structure.** When a brief is vague, choose from the first six of its mode.

The Persuade/Experience shapes are adapted from nutlope/hallmark's macrostructure catalog (MIT). The Operate and Read shapes are this pack's own; hallmark has none for app UI.

## Persuade · Experience

| Name | Weight sits | Suits | Refuses |
|---|---|---|---|
| **split-column** | Left third carries the claim in display type; right two-thirds carries the proof (product, image, data). Sides alternate per section. | Products that can be shown; anything with one strong screenshot | centred hero · equal cards |
| **editorial-measure** | A single 60–70ch column; headings hang in the left margin; hairline rules divide | Long-form marketing, founder letters, story-shaped changelogs | full-bleed imagery · sidebars |
| **poster** | One statement fills the first viewport at display size; everything below is small and dense | A single strong claim, launch moments | multiple centred elements · stat rows |
| **asymmetric-grid** | Irregular modular blocks of unequal size on a strict grid; rhythm comes from size variation | Feature-rich products, mixed media (quote + image + spec) | uniform three-up · icon-heading-text triads |
| **spec-sheet** | Dense tabular facts first, prose demoted; numbered left margin | Hardware, APIs, pricing, anything a buyer compares | hero metric · testimonials |
| **cinematic-scroll** | Sticky left pane of text; right pane swaps real screens on scroll | Guided tours with 3–6 real screenshots | fake device frames · autoplay video |
| **broadsheet** | Multi-column newspaper grid, mixed type sizes, rules between columns | Publications, releases, digests, programmes | glass · gradients · card shadows |
| **gallery-wall** | An image leads each fold; text is a small caption | Portfolios, photography, fashion, architecture | text-heavy hero · icon rows |
| **rail-and-canvas** | Narrow persistent rail (nav, index, meta) beside a wide canvas that changes | Showcases with many items, docs-flavoured marketing | footer link columns · centred nav |
| **manifesto** | Numbered declarations in large roman type, one per fold | Belief-first products, communities, campaigns | feature bullets · pricing above the fold |
| **catalog-index** | Uniform grid of many equal items behind a strong filter/sort bar | Marketplaces, template galleries, type foundries | one-item hero · carousel |
| **chaptered-scroller** | Numbered chapters with a sticky progress index; each chapter changes rhythm | Explainers, annual reports, onboarding stories | equal-height sections · one entrance animation everywhere |

## Operate

| Name | Weight sits | Suits | Refuses |
|---|---|---|---|
| **master-detail** | List pane left, detail pane right; selection is the primary action | Inboxes, CRMs, tickets, file browsers | a modal for the detail · cards for the list |
| **command-first** | A command palette or search input is the first focusable element; results replace chrome | Power tools, admin consoles, search-heavy apps | deep nav trees · icon-only sidebars |
| **table-with-inspector** | A dense data table fills the width; a slide-in inspector edits one row without leaving the table | Finance, ops, catalog management, bulk edit | one form per page · pagination where virtualisation fits |
| **wizard** | One decision per step, progress visible, back always available | Setup, checkout, imports, anything with an irreversible last step | every field on one page · a hidden step count |
| **settings-ledger** | Two columns — label and help left, control right — grouped by rule, saved per group | Preferences, account, billing, permissions | tabs inside tabs · toggles with no state text |
| **board** | Columns of movable cards; status is position | Kanban, pipelines, triage | nested cards · colour as the only status signal |

## Read

| Name | Weight sits | Suits | Refuses |
|---|---|---|---|
| **document-with-sticky-rail** | Prose at reading measure; a sticky table of contents in the rail | Guides, tutorials, specs, policies | hero image · centred titles |
| **reference-two-pane** | Symbol index left, one symbol's full contract right, code samples in their own rhythm | API and CLI reference, token docs | prose introductions · marketing headers |
| **changelog-ledger** | Reverse-chronological entries with a date gutter and version tags | Release notes, changelogs, incident histories | a card per release · an icon per change type |

The stamp names the structure: `/* structure: master-detail · … */`. A structure not in this table is allowed when the brief earns it — name it anyway, and add it here once it has been used twice.
