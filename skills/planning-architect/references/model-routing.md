# Reference: Model Tier Routing

*`planning-architect` reference — read when the run needs it.*

## Model Tier Routing (Mandatory per Step)

The plan exists so the user can **switch models between steps**. Each step carries a `Model:` line.

| Tier | When to assign | Typical work |
|---|---|---|
| **Light** (e.g. Haiku) | Mechanical, low-ambiguity, single-file edits; rote scaffolding; renames; importing an existing pattern; obvious test boilerplate; running verification commands. | "Move this method into that service", "rename symbol", "create the spec mirroring existing pattern X". |
| **Standard** (e.g. Sonnet) | Multi-file but well-scoped changes with a clear blueprint; a new component composed of known primitives; standard wiring; typical test authoring. | "Build this component from the existing `Foo` service and design-system card", "wire route + guard + resolver per existing pattern". |
| **Standard + thinking** | Non-trivial design decisions inside a step; tricky async/state interactions; subtle a11y or focus management; refactors that must preserve behavior exactly. | "Restructure the event orchestration without breaking subscribers", "focus-trap interacting with the existing modal stack". |
| **Heavy** (e.g. Opus) | Cross-cutting reasoning across many files; architectural tradeoffs; novel algorithms; deep ambiguous debugging. | "Design a sync layer spanning 6+ services", "resolve a flake whose root cause is unclear". |
| **Heavy + thinking** | The hardest reasoning the plan admits — usually 0–1 per plan, often none. Justify in writing. | "Reconcile competing constraints across module boundaries with no obvious answer". |

Rules:
- **Default downward.** Borderline Standard → drop to Light and trust the implementer to escalate.
- **Group adjacent same-tier steps** so the user switches once, not six times.
- **Flag every tier change** with `[SWITCH MODEL → <tier>]` at the top of the step.
- **Insert an explicit stop** at the end of any step preceding a tier change: *"Implement step N, then STOP. Do not proceed — the user will switch models first."*
- **No silent escalation.** If a Light-tagged step turns out to need Heavy reasoning, the implementer stops and surfaces it.

---
