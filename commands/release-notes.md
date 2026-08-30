---
description: Turn what shipped into user-facing release notes — features, fixes, breaking changes, with a migration guide for each break.
argument-hint: "[the release or version, if not obvious from the changelog]"
---

Run `documentation-architect` in **Release notes** mode. The mode is already chosen — do not re-open the mode question.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/SKILL.md` — its constraints apply in full, Constraint 1 (document what exists, not what is planned) most of all.
2. Load `module-writing-floor` and `guidelines-meta`.

Three rules this mode lives or dies by:

- **Translate, don't transcribe.** "Fixed a crash when creating a profile", never "fix NPE in UserSvc".
- **Group as features / fixes / breaking**, with a migration guide for every breaking item, stated as steps the reader performs.
- **Never invent a version number or a date.** The changelog itself belongs to `rolling-history`; this produces the human-facing notes *from* it. If no changelog entry exists yet, say so and stop rather than reconstructing one from the diff.

Target: $ARGUMENTS

If nothing was given, read the changelog and ask which release to write up.
