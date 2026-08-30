---
description: Read existing docs against the code they describe — a friction log with path:line, read-only.
argument-hint: "[doc, directory, or the whole doc set]"
---

Run `documentation-architect` in **Audit** mode. The mode is already chosen — do not re-open the mode question, and do not start rewriting. This run is **read-only**.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/SKILL.md` — its constraints apply in full, including §2's rule that the manifest is the authority on commands, not the old README.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/references/audit-mode.md`.
3. Load `module-writing-floor` for the floor and the refuse list, `module-findings` for the finding shape and banded verdict, and `guidelines-meta`.

The friction log comes first, and every finding carries `path:line`. Drift between a doc and the code is a finding, not a rewrite you perform mid-audit.

Target: $ARGUMENTS

If no target was given, audit the docs the repo actually ships and say which ones those are.
