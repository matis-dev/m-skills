# Reference: The Rot Sweep

*`maintenance-architect` reference — read when the run needs it.*

## Phase 5 — The Rot Sweep

Findings no gate reports, because nothing fails. Run it periodically, report per `module-findings`, and **fix only what the user approves** — this phase generates a list, not a rewrite.

- **Suppressions** — lint-ignores, type-ignores, skipped tests. Each is a debt with no due date. Count them; a growing count is the signal. Any without a reason comment is a finding.
- **Skipped and flaky tests** — a permanently skipped test is worse than a deleted one, because it looks like coverage. Hand flakes to the `debugging-architect` skill; delete or fix the skips.
- **Unused dependencies** — in the manifest, imported nowhere. Removal is the cheapest possible upgrade.
- **Dead code** — unreferenced exports, unreachable branches, files nothing imports. "Unreferenced" means searched past imports too — tests, fixtures, config, string-keyed and dynamic references (`module-findings` §2). Propose removal; do not delete pre-existing dead code unasked (Guidelines §3).
- **Shortcut ledger** — every `shortcut:` comment (Guidelines §2), one row each: `<file>:<line> · ceiling: <limit> · upgrade: <trigger>`. Find them with `git grep -nE '(#|//|/[*]|--) ?shortcut:'`, plus the stack's other comment prefixes. Tag a row naming no upgrade trigger `no-trigger` — those are the deferrals that rot. Flag any whose ceiling the project's current load already crosses. End with `<N> shortcuts, <M> no-trigger`.
- **Stale TODO/FIXME** — with no ticket and no date. Either it matters and gets tracked, or it doesn't and goes.
- **Doc drift** — the profile's doc targets describing a version of the system that no longer exists. `rolling-history` owns the fix.
- **Config drift** — settings for tools no longer used, env vars nothing reads.
- **Duplicate transitive versions** — three copies of the same library is a bundle-size and correctness hazard.

---
