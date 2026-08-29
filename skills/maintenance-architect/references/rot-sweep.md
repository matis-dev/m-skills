# Reference: The Rot Sweep

*`maintenance-architect` reference — read when the run needs it.*

## Phase 5 — The Rot Sweep

Findings no gate reports, because nothing fails. Run it periodically, report per `module-findings`, and **fix only what the user approves** — this phase generates a list, not a rewrite.

- **Suppressions** — lint-ignores, type-ignores, skipped tests. Each is a debt with no due date. Count them; a growing count is the signal. Any without a reason comment is a finding.
- **Skipped and flaky tests** — a permanently skipped test is worse than a deleted one, because it looks like coverage. Hand flakes to the `debugging-architect` skill; delete or fix the skips.
- **Unused dependencies** — in the manifest, imported nowhere. Removal is the cheapest possible upgrade.
- **Dead code** — unreferenced exports, unreachable branches, files nothing imports. Propose removal; do not delete pre-existing dead code unasked (Guidelines §3).
- **Stale TODO/FIXME** — with no ticket and no date. Either it matters and gets tracked, or it doesn't and goes.
- **Doc drift** — the profile's doc targets describing a version of the system that no longer exists. `rolling-history` owns the fix.
- **Config drift** — settings for tools no longer used, env vars nothing reads.
- **Duplicate transitive versions** — three copies of the same library is a bundle-size and correctness hazard.

---
