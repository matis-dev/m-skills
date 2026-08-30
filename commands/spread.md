---
description: Work out where a finished project goes and what each place demands of a newcomer — drafted posts, none of them sent.
argument-hint: "[the project, repo, or product]"
---

Run `marketing-architect` in **spread** mode — the default depth. The mode is already chosen — do not re-open the mode question, and do not escalate into `campaign` or `launch`.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/marketing-architect/SKILL.md` — its eight constraints apply in full.
2. Resolve the audience (§1), then walk the funnel floor (§2) and **stop at the first failure**. Constraint 7 is not negotiable here: if the landing surface fails the first-screen test in `${CLAUDE_PLUGIN_ROOT}/skills/marketing-architect/references/positioning.md` §2, that is the finding — emit no channel list.
3. If the funnel holds, read `${CLAUDE_PLUGIN_ROOT}/skills/marketing-architect/references/placement.md`: the evergreen directory layer first, then a short ranked channel list.
4. Load `module-writing-floor` for the drafted posts, `module-handover` for delivering them, and `guidelines-meta`.

Two constraints this command cannot loosen: **rules of entry are read live this run, never recalled** (Constraint 3 — a ban is permanent), and the **baseline is recorded before anything ships** (Constraint 2). This skill drafts and publishes nothing; `guard-outward.sh` enforces that at the runtime.

Target: $ARGUMENTS

If no target was given, ask what is being spread and who it is for.
