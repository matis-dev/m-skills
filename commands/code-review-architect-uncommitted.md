---
description: Review only what is uncommitted — staged and unstaged, nothing from history. Gates off by default for a mid-work read.
argument-hint: "[optional: a path to narrow to, within the uncommitted set]"
---

Run `code-review-architect` in **working tree** mode. The scope is already chosen — do not re-open it, and do not widen the change set to a branch or a PR. This run is **read-only** and writes no code.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/code-review-architect/SKILL.md` — its Operational Constraints, Mandatory Considerations, and scoring apply in full.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/code-review-architect/references/quality-pass.md` for Phase 3, and `references/output-format.md` when assembling the review.
3. Load `module-findings` before writing a single finding, `module-threat-model` for the Phase 4 sweep, `module-propagation` when a shape, an API, or an origin changed, and `guidelines-meta`.

**The change set is `git diff HEAD` and nothing else.** Staged plus unstaged, no commits. Do not resolve a base branch, do not run `git diff <base>...HEAD`, do not read `git log`. If the argument names a branch or a PR, that is a different review — say so in one line and point at `/m-skills:code-review-architect` rather than running it here.

**Name the untracked files.** Run `git status --porcelain` and list any `??` paths in the Scope line as present but **not reviewed** — this mode reads tracked changes only, and a review that quietly omits a new file is a dishonest one (Guidelines §15).

**Phase 2 is pre-skipped.** A mid-work read of the working tree is not a merge gate, so this command starts in the `skip gates` modifier (Guidelines §19). Say it in the output — "gates not run (mid-work review); type `run gates` for the full battery" — and never print a ✅ you did not observe. A trailing `run gates` restores the full `module-gate-battery` pass. Because the gates did not run, **Correctness & Tests** is scored on the diff alone; state that beside the number rather than scoring it as if a suite had passed.

Working-tree scope has no commit messages, so the stated intent for Phase 1 comes from this session. If there is none, the Phase 5 goal trace falls back to "no stated goals — inferred from the diff". Say which one applied.

Target: $ARGUMENTS

If a path was given, it filters *within* the uncommitted set (`git diff HEAD -- <path>`) — it never selects a different change set. If nothing was given, review the whole working tree. If `git diff HEAD` is empty, say there is nothing uncommitted to review and stop.
