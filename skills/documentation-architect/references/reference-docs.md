# Reference: The Public Surface: Reference and Docstrings

*`documentation-architect` reference — read when the run needs it.*

## 5. The Public Surface — Reference and Docstrings

Reference documentation covers the **contract**, not the implementation. It is exempt from Guidelines §13's minimal-comments rule for exactly one reason: §13 governs inline comments aimed at a maintainer reading the body, while a docstring on an exported symbol is the interface's own documentation, aimed at a caller who will never open the file. Inside a function body, §13 still applies in full.

Document **every exported symbol**, and nothing that isn't. For each, in the project's own docstring convention:

1. **What it does and when to reach for it** — one sentence, task-framed. "Persists user preferences to local storage" beats "saves data".
2. **Parameters** — name, type, whether it is required, the default, and what the value *means*. A table when there are more than about three, matching the project's existing reference layout.
3. **Return value** — type and meaning, including the empty, null, and partial cases.
4. **Failure behaviour** — what it throws or returns on invalid input, on a missing dependency, on a timeout. **This is the half that is always missing and always needed**, and it is what separates a reference from a signature dump.
5. **Side effects** — I/O, global or shared state, cache writes, network calls, anything that makes the call non-obvious to reason about. Silence here reads as "pure"; say so if it isn't.
6. **One realistic example** — a call in the shape a real caller would write, using this project's own types and names.

For an HTTP or RPC contract, the same six with auth requirements, status codes (including the error ones), and pagination or rate-limit behaviour where they apply. Generate from the schema where the project has one; hand-written payload examples drift.

---
