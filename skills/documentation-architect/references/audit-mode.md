# Reference: Audit Mode

*`documentation-architect` reference — read when the run needs it.*

## 6. Audit Mode — Produce a Friction Log, Not a Verdict

Triggered by "audit", "review the docs", or a report that someone got stuck. **Read-only: write nothing.** The output is evidence, not opinion.

1. **Walk the path as the reader.** Start at the entry point they would start at, follow the instructions *literally*, and record every place the document stopped being sufficient — a missing prerequisite, a command that failed, a term never defined, a link that 404s, a choice with no guidance. This is the friction log, and it is the most valuable thing in the report because it is reproducible.
2. **Sweep `module-writing-floor`** over each target file, with `path:line` for every finding.
3. **Check truth against the code** — every command against the manifest, every path against the tree, every flag against the CLI, every documented symbol against the exports. Report drift as its own class; it is the highest-severity finding here because it is confidently wrong.
4. **Find the gaps by audience** (§1). Which reader has no page? A project with three reference pages and no quick start is failing its most numerous reader.

Report shape — cap each list at five, highest severity first (Guidelines §17):

- **Verdict** — one of `Blocked` (a reader following the docs cannot succeed) / `Rough` (they succeed after guessing) / `Usable` (succeeds, gaps are additive) / `Good` (nothing found above cosmetic). **Name the evidence that set it**, not a feeling. No letter grades and no invented score — an unmeasured number is a fabrication (Guidelines §15).
- **Friction log** — numbered, in the order the reader hits them, each with the concrete fix.
- **Drift** — statements the code contradicts, with both locations.
- **Missing artifacts** — the doc that should exist, and which reader is stranded without it.
- **Top rewrites** — at most three, in `current → improved` form so the user can judge the voice before you touch anything.

---
