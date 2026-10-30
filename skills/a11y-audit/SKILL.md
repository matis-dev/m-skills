---
name: a11y-audit
disable-model-invocation: true
description: Read an existing surface against WCAG 2.2 AA — evidence-backed, with an explicit statement of what was not tested.
argument-hint: "[screen, component, or URL to audit]"
---

Run `accessibility-architect` in **audit** mode. The mode is already chosen — do not re-open the mode question, and do not drift into `spec`, `build`, or `remediate`. This run reports; it does not fix.

1. Read `<m-skills>/skills/accessibility-architect/SKILL.md` — its constraints apply in full, Constraint 3 (a green scan is not a conformance claim) most of all.
2. Read `<m-skills>/skills/accessibility-architect/references/reading-a-scan.md`, and `references/wcag22.md` and `references/who-it-blocks.md` when the run reaches them.
3. Load `module-findings` for the finding shape and the banded verdict, and `guidelines-meta`.

Never invent a score. Name who each barrier blocks (Constraint 4), and state what was **not** tested.

Target: the text the user typed after the command

If no target was given, ask which surface to audit.
