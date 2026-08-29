# Reference: The Quality Pass: Maintainability, Performance, Craft

*`code-review-architect` reference — read when the run needs it.*

**Maintainability**
- Is naming intent-revealing and consistent with local convention?
- Duplication of an existing artifact (cite paths)? Should this extend rather than duplicate?
- Is the abstraction level right — premature generalization with one caller, or copy-paste avoiding a needed extraction (3+ near-identical sites)?
- **YAGNI + one-liners** (Guidelines §2): flag scope built for a future the task didn't ask for (unused params, speculative config, single-caller generalized helpers). Flag multi-line scaffolding where one readable expression fits — but never push a one-liner that hurts readability; that's the opposite finding.
- Dead code, orphaned imports, leftover debug logging, commented-out blocks, TODO/FIXME without a ticket?
- Comments only where the *why* is non-obvious? No what-comments, no task-reference comments?
- Typing discipline: escape hatches justified in one line, or not?
- **User-facing text** (Guidelines §14): raw `error.message` shown to a user? If the project is localized, raw literals instead of keys, or a new key missing from a locale? Cite each offender.
- **Doc drift**: if the diff changes something a profile-listed doc describes (an integration contract, an architecture fact, a deployment step), that doc is now stale — a **Low–Medium** finding. If a doc is multi-language or duplicated, updating only one copy is itself a finding.

**Change-Propagation Audit** — if the diff changes shared shape, a public API, or an external origin, load the `module-propagation` skill and run its review-time audit against the diff. Findings of this class are the highest-value output of the whole review, because every one of them passes the gates that were supposed to catch it.

**Performance**
- Hot-path complexity; work repeated per item that could be hoisted.
- N+1 network/database/storage calls; writes that should be batched.
- Subscriptions, listeners, timers, file handles: cleaned up on teardown?
- Rendering: memoization/change-detection strategy appropriate; stable keys on dynamic lists?
- New dependencies: bundle/binary cost vs. value; tree-shakeable; duplicating something already present?
- Assets added: weight, format, compression.
- Lazy boundaries for non-trivial new routes/modules.

**Design craft & accessibility** *(UI-visible diffs only)*
- Load `module-craft-floor` and check the rendered result against it: computed contrast, full state set on interactive elements and inputs, spacing on the scale, responsive range clean, reduced-motion fallbacks, focus-visible present, colors and fonts on tokens.
- Load `module-operability-floor` and check the same diff against it: native element used where one exists or the ARIA role's full contract supplied; every control keyboard-reachable and named; new overlays move focus in, close on Escape, and **return focus to the trigger**; route or status changes announced; targets meet 24×24 or the spacing exception. **If the plan carried `[A11Y]` tags, verify those specific commitments landed** — and note that a green `<a11y>` gate is evidence about the scan, not about focus architecture.
- Refuse list: any AI-default pattern present that the brief didn't earn.
- Token discipline: colors and fonts referencing tokens, not improvised values.
- Honest content: no invented metric, testimonial, or claim (Guidelines §15).
