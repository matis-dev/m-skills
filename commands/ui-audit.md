---
description: Read an existing interface against the craft floor and the refuse list — findings with path:line, writing nothing.
argument-hint: "[screen, page, or component to audit]"
---

Run `design-architect` in **Audit** mode. The mode is already chosen — do not re-open the mode question, and do not drift into redesign, polish, study, or establish. **Write nothing**: this run reports.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/design-architect/SKILL.md`, including §1 visitor-mode selection — the audit is run *against the mode the surface is actually in*, which still has to be named.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/design-architect/references/modes.md` for the audit definition and `references/refuse-list.md` for the AI-default patterns.
3. Load `module-craft-floor` — this is the substance of the audit. Load `module-operability-floor` too if the target is interactive.

Every finding carries `path:line`, a severity, and the concrete fix. The project's committed design system outranks anything in the catalog.

Target: $ARGUMENTS

If no target was given, ask which screen or component to audit.
