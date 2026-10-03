# Reference: The Review Output Format

*`code-review-architect` reference — read when the run needs it.*

## Output Format (Fixed)

```markdown
# Code Review: <branch / PR# / change-set>

**Verdict:** 🟢/🟡/🟠/🔴 **<band>** — <n>/100
**Next action:** <the single thing the user does now>

## Scope
- Base `<ref>` → Head `<ref>` (<N> commits, <F> files, +<add>/-<del>)
- Stated goals (from commits / PR):
  - <goal>

## Static Gates
<the gate result table — shape in `module-gate-battery` §2>

## Findings

### 🔴 Critical
- **[Security] <title>** — `path/to/file.ts:42`
  Why it matters: <one paragraph>
  Fix: <concrete pointer; no code written here>

### 🟠 High
### 🟡 Medium
### 🔵 Low
### ⚪ Nit

> Out-of-diff findings tagged `[OUT-OF-DIFF]` with a one-line justification.

### Worth a second look (unverified)
- <severe-if-true item below the confidence bar, with what would confirm it>

## Convention Audit
- Project conventions / design system respected? <yes / no — cite>
- Reuse mandate respected? <yes / no — cite>
- User-facing text handled per convention? <yes / no — cite raw `error.message`, raw literals, missing locale keys>
- Change propagation complete? <n-a / yes / no — cite unswept mirror sites>
- External origin / policy declarations complete? <n-a / yes / no>
- Design craft floor cleared? <n-a / yes / no — cite>
- Guards clean in scripts/CI? <no `--no-verify`, no auto golden update, no force ops>
- Tests paired with code changes? <yes / no — cite Testing Architect findings>

## Score
| Dimension | Score | Notes |
|---|---|---|
| Maintainability | <x> / 25 | |
| Performance | <x> / 15 | |
| Security | <x> / 30 | |
| Correctness & Tests | <x> / 20 | |
| Design Craft | <x> / 10 | |
| **Total** | **<x> / 100** | |

## Manual Final Stage (NOT automated)
- Review failed visual diffs at `<report path>` if any.
- If intended, the **user** runs `<update-command>` manually and re-runs `<visual>`.
- Reviewer never runs `git add`, `git commit`, or `git push`. Staging, committing, and pushing are **user-only**.
```

---
