---
description: Run first in an existing project — writes PROJECT-PROFILE.md from the repo, adopts the docs already there, and leaves rolling-history ready for its first run.
argument-hint: "[optional: a docs directory or package to focus on]"
---

Run `documentation-architect` in **Onboard** mode. The mode is already chosen — this is an existing codebase meeting the pack for the first time, so do not ask what to write or implement, and do not fall back to Generate. If the repo has nothing in it yet, stop and point at `/m-skills:kickoff` instead.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/SKILL.md` — its constraints apply in full, including constraint 5: no new doc without asking.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/references/onboard.md`.
3. Load the `guidelines-meta` skill (§5 is the profile procedure) and `module-writing-floor` before emitting anything a reader follows.
4. Mechanical sweep: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-bootstrap.sh` (silent when a profile exists and still holds). Fingerprint for the profile marker: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-bootstrap.sh --fingerprint`. Template: `${CLAUDE_PLUGIN_ROOT}/skills/guidelines-meta/PROJECT-PROFILE.template.md`. If the sweep opens with a 🚨 or ⚠️ secret-file block, raise that with the user first.

Target: $ARGUMENTS

If nothing was given, onboard the whole repo; in a monorepo, name the packages found and fill §Packages.
