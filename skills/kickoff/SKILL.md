---
name: kickoff
disable-model-invocation: true
description: Start here, new project or existing — works out which, then plans the first slice of a new one or onboards the repo already there and steers to the next run.
argument-hint: "[what you want to build]"
---

Run `brainstorming-planner` in **Kickoff** mode — but only once the repo turns out to be new. This is the one door for a project the pack has not seen, so look before you route: Kickoff mode decides the stack, the test layers, and the visual world, and on an existing codebase those are already decided in the files.

**0. Find out what this is.** Run `bash <m-skills>/scripts/profile-bootstrap.sh --shape` — it prints `greenfield` or `brownfield` by the same rule as the session nudge. Take the first row that matches and say the route in one line:

| Found | Route |
|---|---|
| The user says they are starting over or rebuilding from scratch | Greenfield, whatever `--shape` printed — steps 1–3. |
| `greenfield` | Steps 1–3. |
| `brownfield`, no `.claude/PROJECT-PROFILE.md` | Onboard first: load the `documentation-architect` skill and run `<m-skills>/skills/documentation-architect/references/onboard.md` in full, then step 4. |
| `brownfield`, a profile exists | Step 4. |

1. Read `<m-skills>/skills/brainstorming-planner/SKILL.md` — the Active Discovery protocol and its guardrails apply in full.
2. Read `<m-skills>/skills/brainstorming-planner/references/kickoff.md`.
3. Load the `guidelines-meta` skill, and `module-threat-model` → `references/trust-boundaries.md` once the idea is real enough to have a trust boundary.
4. **Existing codebase: steer to the next run.** Ask with ask_question, recommendation first; each option that starts a skill carries its exact name:
   - `Shape a feature → brainstorming-planner` — recommended when the target names something to build; carry it over as the idea.
   - `Plan a known change → planning-architect`
   - `Something is broken → debugging-architect`
   - `Nothing yet` — stop here; the profile is in place for whichever skill runs next.

   A pick starts that skill (Guidelines §17): read its SKILL.md and run it on the target, with no paste line and no second confirm.

Target: the text the user typed after the command

If nothing was given and the route is greenfield, ask what is being built before anything else.
