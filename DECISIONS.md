# Decisions

Why this project is built the way it is, including what was considered and rejected. The changelog records what shipped; this file records what was chosen.

## Adding an entry

- **Log a choice a person made**: a question put to the user and answered, or a call the team made. A detail an agent picked on its own is not an entry.
- **Append only**, in this shape:

  ```markdown
  ### YYYY-MM-DD — <the decision, as a statement>
  Why: <the reason, one or two lines>
  Rejected: <the alternatives, briefly — or "none considered">
  By: <skill or person> · revisit if: <the trigger that would reopen it | never>
  ```

- **Reversing one:** add a new entry with a `Supersedes: YYYY-MM-DD — <title>` line, and add one line, `Superseded by YYYY-MM-DD`, to the old entry. Change nothing else in it.
- **Check before appending.** A decision already logged is not logged twice.

## Entries

### 2026-10-21 — No Agensi edition
Why: the user does not want to send this repo to Agensi. The work was reverted: the build script was never committed, `dist/agensi/` was deleted, and the profile no longer lists Agensi as a surface.
Rejected: a fourth build target on Agensi with 16 free single-skill zips (decided 2026-10-16, then reverted).
By: Matis.dev · revisit if: never

### 2026-11-06 — The directory edition ships prompt hooks only
Why: the directory refused 5.4.0. Since 2026-11 it rejects every hook of type `command` from an organization that is not Verified, and accepts hooks of type `prompt`. The self-hosted install keeps its command hooks on `main`.
Rejected: none recorded.
By: Matis.dev · revisit if: the organization is Verified, or the directory accepts command hooks again

### 2026-11-06 — Decisions get their own file beside the changelog
Why: the changelog records only what shipped, so rejected and dropped directions were lost, or kept only in one person's private memory.
Rejected: changelog only, with a "rejected" line per entry (unshipped choices still have no home); an ADR folder, one file per decision (too heavy for most projects the pack serves).
By: brainstorming-planner · revisit if: never

### 2026-11-06 — Kickoff sets the log up; brainstorming and planning write to it; rolling-history catches the rest
Why: the user's decisions are made in question rounds, so the skills that ask write them down. A choice made elsewhere (an implementing *Ask Before* stop, a debugging fix, a deployment pick) reaches the file through rolling-history at session end.
Rejected: rolling-history as the only writer (day-one rationale is forgotten by then); every skill that asks appends its own entries (the rule spreads across many files).
By: brainstorming-planner · revisit if: decisions made outside brainstorming and planning keep going unlogged

### 2026-11-06 — Entries are written at the close of the run, whatever is picked next
Why: a decision stands even when the user stops; a direction dropped at `Stop here` is the one most worth keeping.
Rejected: only when the plan is approved (rejected directions lost again); an extra "log these?" choice in every closing picker.
By: brainstorming-planner · revisit if: never

### 2026-11-06 — The log is offered once and the answer is recorded in the profile
Why: a file nobody asked for is scope creep. Kickoff (new repos) or onboard (existing ones) asks once; a project onboarded earlier is asked by the first run with a decision to log. The answer, a path or `n-a — declined`, becomes a §Documentation Targets row, so nobody is asked twice.
Rejected: created by default in kickoff; asked only at the first real decision; offered by onboard alone, or by kickoff alone.
By: brainstorming-planner · revisit if: never

### 2026-11-06 — Five skills read the log before judging new work
Why: brainstorming, planning, code-review, maintenance, and debugging each make calls a logged decision can overturn.
Rejected: none considered.
By: brainstorming-planner · revisit if: never

### 2026-11-06 — An entry is a dated heading with Why, Rejected, and By lines
Why: readable months later, greppable by date, with room for what was rejected and when to reopen it.
Rejected: one bullet line (the rejected alternative and the trigger get squeezed out); a table row (long reasons wrap badly, and appends conflict in diffs).
By: brainstorming-planner · revisit if: never

### 2026-11-06 — The rules live in a template and in the log's own header
Why: `skills/guidelines-meta/DECISIONS.template.md` sits beside the profile template, and each skill needs one line pointing at the file. `guidelines-meta` was ruled out: its Antigravity body has 269 bytes left under the 24,000-byte cap.
Rejected: a new `module-decisions` (bumps counts in README, SKILLS_INDEX, tests, and both builds); a `documentation-architect` reference (readers would load that whole skill first).
By: brainstorming-planner · revisit if: never

### 2026-11-06 — The default path is DECISIONS.md at the repo root
Why: it sits beside `CHANGELOG.md`, where people reading the repo see the pair, not only agents.
Rejected: `docs/decisions.md`; `.claude/decisions.md` (mostly invisible to people reading on GitHub).
By: brainstorming-planner · revisit if: never

### 2026-11-06 — Review reports a diff that contradicts a logged decision as Medium
Why: the fix is the user's call (revert, or log a superseding entry), so it should raise the question without blocking on its own.
Rejected: High (treats a decision like a broken contract); "worth a second look" (outside the score, easy to ignore).
By: brainstorming-planner · revisit if: contradictions keep merging unnoticed

### 2026-11-06 — This repo adopts the log, seeded from this session and back-filled
Why: the pack uses what it ships. Back-filled entries are quoted from their sources and written only once the user approves each one.
Rejected: seeding from this session only; shipping the mechanism without adopting it here.
By: brainstorming-planner · revisit if: never

### 2026-11-07 — The directory edition ships no scripts
Why: since 2026-11 the directory accepts, from an organization that is not Verified, only Markdown, text, JSON, YAML, and images, and no `allowed-tools` entry beyond Read, Grep, Glob, and LS. Steps that ran a plugin script become steps Claude does by hand; `main` keeps every script.
Rejected: none recorded.
By: Matis.dev · revisit if: the organization is Verified, or the directory accepts scripts again

### 2026-11-07 — The by-hand onboard sweep keeps the bootstrap's secret checks
Why: the release README promises the deny-rule offer, and it is the fallback for the prompt hooks' Grep gap. Env files once committed still need rotating.
Rejected: dropping the promise from `README.release.md` and leaving the Grep gap uncovered in this edition.
By: code-review-architect (fix pick) · revisit if: an `if` rule can match Grep paths
