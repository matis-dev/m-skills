# Reference: The Maintenance Report Format

*`maintenance-architect` reference — read when the run needs it.*

## Output Format (Fixed)

```markdown
# Maintenance Report — <date>

**Status:** <N now · N soon · N routine · N held>
**Next action:** <the single thing the user does now>

## Now — reachable advisories
- **<package> <cur> → <fix>** — <advisory id>, <severity>
  Reachable: <yes — called at `path:LN` on an untrusted-input path>
  Fix: <upgrade | override + expiry condition>

## Soon
- **<package>** — <why, and the deadline that makes it soon>

## Routine — batched
| Batch | Contents | Revert |
|---|---|---|
| 1 | dev tooling + types | `git checkout <lockfile> <manifest>` |
| 2 | patch bumps (N packages) | `…` |
| 3 | `<pkg>` major — alone | `…` |

## Deliberate holds (recorded in the profile)
- **<package>** — held at `<version>` because <reason>. Revisit when <condition>.

## Rot Sweep
- Suppressions: <N> (<M> without a reason comment) — `<paths>`
- Skipped tests: <N> — `<paths>`
- Unused dependencies: `<names>`
- Stale TODOs: <N>
- Doc drift: <files whose claims no longer hold>

## Verification
- Baseline before: <gate results>
- After batch N: <gate results, bundle delta, visual diffs awaiting review>

## Guards
- No `git add`, `commit`, or `push` — lockfile changes left unstaged.
- Nothing was suppressed, skipped, or pinned back to force a pass.
```

---
