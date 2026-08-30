---
description: Replace a surface's visual world outright while keeping its product truth, content, and function.
argument-hint: "[screen, page, or component to redesign]"
---

Run `design-architect` in **Redesign** mode. The mode is already chosen — do not re-open the mode question, and do not offer audit or polish instead.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/design-architect/SKILL.md`, including §1 — name the visitor mode before designing.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/design-architect/references/modes.md` for what redesign commits to, and `references/refuse-list.md` before emitting.
3. Load `module-craft-floor`, and `module-operability-floor` if the surface is interactive.

Constraint 3 governs this run: keep product truth, content, and function; treat the old look as evidence and anti-reference; **never split the difference** by polishing a look you have decided to discard. Update the project's design doc to match.

Target: $ARGUMENTS

If no target was given, ask which surface to redesign.
