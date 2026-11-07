---
description: Run first in an existing project — writes PROJECT-PROFILE.md from the repo, adopts the docs already there, and leaves rolling-history ready for its first run.
argument-hint: "[optional: a docs directory or package to focus on]"
---

Run `documentation-architect` in **Onboard** mode. The mode is already chosen — this is an existing codebase meeting the pack for the first time, so do not ask what to write or implement, and do not fall back to Generate. If the repo has nothing in it yet, stop and point at `/m-skills:kickoff` instead.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/SKILL.md` — its constraints apply in full, including constraint 5: no new doc without asking.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-architect/references/onboard.md`.
3. Load the `guidelines-meta` skill (§5 is the profile procedure) and `module-writing-floor` before emitting anything a reader follows.
4. Mechanical sweep, by hand: this edition ships no scripts, so wherever onboard.md says the bootstrap, it means this sweep. List the manifests, lockfiles, package scripts, CI workflows, and `.claude` folder to point at §Commands and §Stack. For each secret-file name in the tree (`.env`, `.pem`, `.key`, credentials JSON), ask git whether it tracks or ignores it, never opening the file, and open with a 🚨 block for each one git tracks or a ⚠️ block for each one it does not ignore. Ask git too whether any real env file was ever committed (`git log --all --diff-filter=A --name-only`) and open with a 🚨 block for each, since its values need rotating even after it is gone. If real env files are on disk and no Claude Code settings file sets `sandbox.enabled` to true, offer once to merge into `.claude/settings.json` a `permissions.deny` entry `Read(./<file>)` and a `sandbox.filesystem.denyRead` entry `./<file>` for each: the guards deny reads that name the file, but `grep -r` or a dotenv loader reaches it without naming it. Merge nothing unless the user agrees. Skip the fingerprint marker: this edition runs no drift check. Template: `${CLAUDE_PLUGIN_ROOT}/skills/guidelines-meta/PROJECT-PROFILE.template.md`. If the sweep opens with a 🚨 or ⚠️ secret-file block, raise that with the user first.

Target: $ARGUMENTS

If nothing was given, onboard the whole repo; in a monorepo, name the packages found and fill §Packages.
