---
description: Start a project that does not exist yet — what to build, the first slice, and each foundational decision routed to its owner.
argument-hint: "[what you want to build]"
---

Run `brainstorming-planner` in **Kickoff** mode. The mode is already chosen — this is a greenfield run, so do not check for a codebase to brainstorm against and do not fall back to ordinary feature brainstorming.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/brainstorming-planner/SKILL.md` — the Active Discovery protocol and its guardrails apply in full.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/brainstorming-planner/references/kickoff.md`.
3. Load the `guidelines-meta` skill, and `module-threat-model` §2 once the idea is real enough to have a trust boundary.

Target: $ARGUMENTS

If nothing was given, ask what is being built before anything else.
