# Reference: The Release Brief Format

*`deployment-architect` reference — read when the run needs it.*

## Output Format (Fixed)

```markdown
# Release Brief: <version> → <environment>

**Readiness:** ✅ ready / ⚠️ ready with caveats / ❌ blocked
**Next action:** <the single thing the user does now>

## Shipping
- Version: <old> → <new>
- Change set: <N commits / PR range>, reviewed <yes/no>
- Highlights: <2–4 bullets from the changelog — no invented items>
- Breaking changes: <named, with migration path — or "none">

## Readiness Gate
| Check | Result |
|---|---|
| Gates green on this change set | ✅ / ❌ <which failed> |
| Reviewed, Criticals/Highs resolved | ✅ / ❌ |
| Propagation protocols (A/B/C) | ✅ / n-a / ❌ |
| Production build verified | ✅ / ❌ |
| Changelog + version current | ✅ / ❌ |
| Rollback plan written | ✅ / ❌ |

## Pre-Flight Findings
- 🔴 / 🟠 / 🟡 **[Config|Data|Cache|Policy|Runtime|Blast radius] <title>** — <why it matters> → <fix>
- *(state "no findings" per clean category rather than omitting it)*

## Before you start — config and prerequisites
<the config table and prerequisite line — shape in `module-handover` §2>

## Runbook — you run these
<one numbered block per command, each with its *Verify* and *If it fails* line — shape in `module-handover` §2. Nothing here has been executed (Constraint 2).>

## Rollback Plan

*Read this before step 1, not after step 4.*

- **Trigger:** <signal + threshold — decided now, before the pressure>
- **Time to recover:** <realistic estimate from decision to restored service>

```bash
<the exact rollback command, copy-ready>
```

- **Does NOT undo:** <migrations, sent mail, charges, client-side caches — or "nothing, fully reversible">

## Post-Deploy Verification
1. <health check>
2. <critical user path>
3. <the change itself>
4. <watch window: what and how long>

## Guards
- No git command that writes was run — staging, committing, pushing, and release tagging are user-only.
- Nothing above was executed. Deploys, migrations, publishes, and rollbacks are yours to fire (Constraint 2).
- <reversible checks actually run: production build / config diff / dry run / health check — or "none yet">
```

---
