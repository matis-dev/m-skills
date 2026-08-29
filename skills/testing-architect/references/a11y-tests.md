# Reference: Accessibility Tests

*`testing-architect` reference — read when the run needs it.*

## 5. Accessibility Tests

### Two Layers, Both Required
1. **Automated rule scan** — run the project's a11y engine against the relevant WCAG tag set, attach violations as a test artifact, fail on any violation. Exclusions are for genuinely third-party, unfixable widgets only, each justified with an inline comment naming the reason.
2. **Keyboard traversal** — walk focus through the surface, detect keyboard traps and confirm the cycle returns. Attach the focus history; fail on a trap.

### Both/All Themes Required
A11y must pass in every theme the project ships. Contrast violations frequently appear in only one.

### Failure Triage Order
1. Read the attached violations artifact.
2. Fix the underlying ARIA / contrast / labeling issue in the component.
3. Only then consider an exclusion — and only for third-party code you cannot change, justified inline.

### What the Two Layers Cannot Reach
An automated scan finds violating nodes. It cannot find a **missing** behaviour, and that is where the serious barriers live: focus that never returns to the trigger after a dialog closes, a client-side route change that announces nothing, a status update no live region carries, a drag with no single-pointer alternative. These produce zero violations and a clean report. Get the contract from `module-operability-floor` (§2–§3) and assert it explicitly — focus destination after open and after close, and the announcement — because nothing else will.

Cross-reference `module-craft-floor`: focus-visible on every interactive element, reduced-motion fallbacks, and labels-or-hidden on decorative graphics are design-floor items an automated scan may not flag.

---
