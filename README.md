# m-skills

**A plugin for full-stack developers who use Google Antigravity to do their actual work.** It gives the everyday loop (brainstorm, plan, implement, review, document) a fixed shape, so the agent stops improvising the process and you stop re-typing the same instructions.

Nothing is tied to one project. Every command, framework, and convention is resolved per repository, from the repo itself or from a `.claude/PROJECT-PROFILE.md` the plugin helps you write, so the same skills work in any codebase.

## Before you install

- **macOS and Linux:** nothing to install first. Every hook is a bash script with its own portable JSON reader, so `jq` and Python are optional.
- **Windows:** Git for Windows (Git Bash) is used to run the `PreToolUse` guard hooks via `bash.cmd` at the plugin root (`Program Files\Git`, `%LOCALAPPDATA%\Programs\Git`, or `M_SKILLS_BASH`). When Git Bash is absent, `bash.cmd` steps aside cleanly so tools are never blocked, and the always-on rule remains active.

## Install it

Add **m-skills** from the Antigravity Plugins panel, or install a built checkout with the `agy` CLI:

```bash
agy plugin install ./dist/antigravity/m-skills
```

In an existing repository, start with `/onboard` (App/IDE) or `/m-skills:onboard` (`agy` CLI). It writes `.claude/PROJECT-PROFILE.md` from what the repo shows and adopts the documentation already there.

## Run the five everyday commands

Run one feature at a time, in this order:

| Stage | App / IDE | `agy` CLI |
|---|---|---|
| Brainstorm it | `/brainstorming-planner` | `/m-skills:brainstorming-planner` |
| Plan it | `/planning-architect` | `/m-skills:planning-architect` |
| Implement it | `/implementing-architect` | `/m-skills:implementing-architect` |
| Review it | `/code-review-architect` | `/m-skills:code-review-architect` |
| Document it | `/rolling-history` | `/m-skills:rolling-history` |

Then you run git yourself. The plugin never does.

The remaining skills stay ready until needed: design, testing, documentation, product slicing, debugging, deployment, maintenance, security, accessibility, marketing, and search visibility, plus 17 focused route skills such as `/threat-model`, `/security-audit`, `/a11y-audit`, and `/rollback` (`/m-skills:<name>` in the `agy` CLI).

## Know what the hooks and rule enforce

The hardest rules ship twice — enforced by `PreToolUse` hooks wherever Antigravity runs them, and loaded in `rules/m-skills-guards.md` (`always_on`) everywhere:

- **No git writes.** Staging, committing, pushing, branching, and every other git write are denied, as are `gh` commands that publish. You receive the exact command to paste instead.
- **No auto-accepted golden files.** Snapshot and visual-baseline updates stay yours to run after inspecting the diff.
- **No secret files in the conversation.** Reads, writes, edits, and filtered `grep_search` queries targeting real `.env` files or private keys are denied; example templates such as `.env.example` stay open.
- **No outward actions.** Deploys, package publishes, and migrations of shared state are denied and handed back to you as a copy-ready runbook.

To turn the hook guards off for one project, create an empty file named `.claude/.m-skills-no-guards` inside that workspace.

## See what runs on your machine

Every hook is a local bash script inside the plugin (`scripts/antigravity-adapt.sh` calling `guard-mutations.sh`, `guard-outward.sh`, and `guard-secrets.sh`). None of them makes a network call, downloads a package, or sends data anywhere.

- **What the hooks read:** the `PreToolUse` payload for the tool call being checked (`run_command`, file read/write/edit tools, and `grep_search`), plus whether `.m-skills-no-guards` is present in the workspace or `~/.claude/`.
- **What the hooks write:** nothing during normal operation. If a future Antigravity update renames a tool argument the adapter checks, one diagnostic line naming the tool (never the command or file path) is appended to `~/.claude/m-skills/guards.log` and the call proceeds.
- **What `/onboard` runs:** `scripts/profile-bootstrap.sh` inspects your repository's manifests, lockfiles, CI config, and `.gitignore` locally to draft `.claude/PROJECT-PROFILE.md`, writing nothing until you confirm.

## License

MIT. See `LICENSE`, and `THIRD-PARTY-NOTICES.md` for the material this plugin adapts. Full source, tests, and multi-host build scripts live at https://github.com/matis-dev/m-skills.

