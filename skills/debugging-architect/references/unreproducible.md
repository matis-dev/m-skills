# Reference: Unreproducible Reports

*`debugging-architect` reference — read when the run needs it.*

## Unreproducible

If it can't be reproduced, stop guessing and improve observability instead:

- Say plainly that it is not reproduced, and that anything below is a theory.
- Collect what exists: logs, traces, error reports, the exact environment, the user's steps.
- **Add the instrumentation that would identify it next time**, and say what signal to look for. Shipping a diagnostic is a legitimate outcome.
- Note the conditions under which it was seen; a pattern across reports is often the diagnosis.
- Do **not** ship a speculative fix for an unreproduced bug (§5). It creates the illusion of resolution and destroys the evidence trail.

---
