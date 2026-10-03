# Reference: Model Tier Routing

*`planning-architect` reference — read when the run needs it.*

## Model Tier Routing (Mandatory per Step)

The plan exists so the user can **switch models between steps**. Each step carries a `Model:` line.

| Tier | When to assign | Typical work |
|---|---|---|
| **Light** (e.g. Haiku) | Mechanical, low-ambiguity, single-file edits; rote scaffolding; renames; importing an existing pattern; obvious test boilerplate; running verification commands. | "Move this method into that service", "rename symbol", "create the spec mirroring existing pattern X". |
| **Standard** (e.g. Sonnet) | Multi-file but well-scoped changes with a clear blueprint; a new component composed of known primitives; standard wiring; typical test authoring. | "Build this component from the existing `Foo` service and design-system card", "wire route + guard + resolver per existing pattern". |
| **Heavy** (e.g. Opus) | Cross-cutting reasoning across many files; architectural tradeoffs; novel algorithms; deep ambiguous debugging. | "Design a sync layer spanning 6+ services", "resolve a flake whose root cause is unclear". |

Rules:
- **Default downward.** Borderline Standard → drop to Light and trust the implementer to escalate.
- **Group adjacent same-tier steps** so the user switches once, not six times.
- **Flag every tier change** with `[SWITCH MODEL → <tier>]` at the top of the step.
- **Insert an explicit stop** at the end of any step preceding a tier change: *"Implement step N, then STOP. Do not proceed — the user will switch models first."*
- **No silent escalation.** If a Light-tagged step turns out to need Heavy reasoning, the implementer stops and surfaces it.

## Effort (per step, alongside the tier)

Current models think adaptively on every turn; the effort setting sets how much. So the plan routes **effort**, not a thinking switch — and never writes "think carefully" into a step, which adds nothing effort doesn't.

| Effort | Assign when |
|---|---|
| **low** | Running verification commands, pure boilerplate. |
| **medium** | The default. Every step until it earns more. |
| **high** | Subtle async/state interaction, focus management, a behavior-preserving refactor, a cross-cutting design call. One clause saying why. |

Higher effort costs tokens and time; a rename at high effort is waste. What a hard step needs from the plan is a **specific** instruction — "check the empty and concurrent-edit cases" — not a louder one.

---
