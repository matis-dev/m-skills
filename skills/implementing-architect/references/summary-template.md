# Reference: The Implementation Summary Template

*`implementing-architect` reference — read when the run needs it.*

## Task Completion Summary Template

Lead with status, not narration (Guidelines §17).

```markdown
## 🏁 Implementation Summary

**Status:** <all gates green | N failing | awaiting visual review>
**Next action:** <the one thing the user does now>

- **Plan reference:** <link or filename>
- **Files Affected:** <list>
- **Functions Created/Modified:** <list>

<the gate result table — shape in `module-gate-battery` §2, one row per gate this project has>

**Could not check:** <check — what it needed (access, credentials, a device) — or "none">  ← read this first
**Verified by running:** <Done When behaviors confirmed in the app, tests, or commands>
**Inferred from reading only:** <behavior concluded from code, not exercised — or "none">
**Blocked:** <step — blocker — what it needs from the user — or "none">

**Propagation protocols run:** <A shared-shape / B public-API / C external-origin / none applied>
**Known gaps:** <uncovered branches, deferred items — or "none">
```

---
