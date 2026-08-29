# Reference: Reading an Automated Log

*`accessibility-architect` reference — read when the run needs it.*

## 4. Reading an Automated Log

`audit` mode, and the correct response whenever someone says "axe is clean".

1. **A violation count is not a conformance level.** Automated rules evaluate a minority of the criteria; the remainder require a human. Report what was run, against which rule tags, on which routes and states, in which themes.
2. **Group by cause, not by node.** Forty "button has no accessible name" findings are usually one icon-button component. Fix the component and the count collapses — a per-node fix list is how remediation becomes a month of work that should have been an hour.
3. **Scan the states, not just the initial render.** Modal open, menu expanded, error shown, list empty, list loading. Most components are only accessible in the state the scan happened to catch.
4. **Every theme the project ships** — contrast findings routinely appear in exactly one (`testing-architect` §4 says the same for visual coverage, and for the same reason).
5. **Then do the manual half**, without which no conformance statement is available: tab the whole flow start to finish with the mouse untouched, confirm focus is always visible and never trapped, test at 200% zoom and 320px width, and — where anyone on the team can — listen to it in a real screen reader.
6. **Verdict shape:** what was tested · what was found, grouped by cause · what was **not** tested · and a banded verdict against the target level with the evidence for it. Shape each finding per `module-findings`; never a number out of 100 with no published method.

---
