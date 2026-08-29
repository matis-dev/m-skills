# Reference: Test Plan Output

*`testing-architect` reference — read when the run needs it.*

## 6. Test Plan Output (when invoked from Planning Architect)

Fill each change-step's test line with this shape. Omit layers the project doesn't have.

```
- **Tests required:**
  - Unit: `<spec path>` — for `<symbol>`: <happy>, <edge>, <error>
  - Security: `<spec path>` — <attack-named case> *(only if the step reaches an import / injection / consent / authz / path sink; else omit)*
  - Integration: `<spec path>` — <collaboration under test>
  - E2E / visual: `<spec path>` — `<state>` × `<themes>` [VISUAL]
  - A11y: `<spec path>` — `<route/state>` × `<themes>` (rule scan + keyboard walk)
  - Coverage: <profile's bar> on new functions in `<file>` (note any justified exception)
```

If a change genuinely needs no layer, say so explicitly:
> "No visual diff expected — refactor preserves rendered output. Visual rerun included for safety only."

---
