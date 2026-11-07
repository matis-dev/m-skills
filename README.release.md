# m-skills

**A plugin for full-stack developers who use Claude to do their actual work.** It gives the everyday loop (brainstorm, plan, implement, review, document) a fixed shape, so the model stops improvising the process and you stop re-typing the same instructions.

Nothing is tied to one project. Every command, framework, and convention is resolved per repository, from the repo itself or from a `.claude/PROJECT-PROFILE.md` the plugin helps you write, so the same skills work in any codebase.

## Before you install

There is nothing to install first. This edition ships no scripts: the guards are prompt hooks that Claude Code runs itself, and everything else is Markdown that Claude reads.

## Install it

Add it from the Claude directory. That is this edition: the skills, the commands, and the guards as prompt hooks.

The self-hosted edition adds script-based hooks: guards that need no model call, the gate table handed to each skill as it starts, skill suggestions, a check that a skill picked in the question sheet was really loaded, and advisories on skipped tests and shared-shape edits. Run these in Claude Code to install it instead:

```text
/plugin marketplace add matis-dev/m-skills
/plugin install m-skills@m-skills
```

In a project that already exists, start with `/m-skills:onboard`. It writes the project profile from what the repo shows and adopts the docs already there.

## Run the five everyday commands

One feature at a time, in this order:

| Stage | Command |
|---|---|
| Brainstorm it | `/m-skills:brainstorming-planner` |
| Plan it | `/m-skills:planning-architect` |
| Implement it | `/m-skills:implementing-architect` |
| Review it | `/m-skills:code-review-architect` |
| Document it | `/m-skills:rolling-history` |

Then you run git yourself. The plugin never does.

The rest wait until you need them: design, testing, documentation, product slicing, debugging, deployment, maintenance, security, accessibility, marketing, and search visibility, plus 17 route commands such as `/m-skills:threat-model` and `/m-skills:rollback` that open an architect in one mode.

## Know what the guards deny

The strictest rules are checked by hooks that deny the call, not by text the model has to remember:

- **No git writes.** Staging, committing, pushing, branching, and every other git write are denied, as are `gh` commands that publish. You get the exact command to paste instead.
- **No auto-accepted golden files.** Snapshot and visual-baseline updates are yours to run after you inspect the diff.
- **No secret files in the conversation.** Reads and writes of real `.env` files and private keys are denied; example files such as `.env.example` stay open.
- **No outward actions.** Deploys, package publishes, and migrations of shared state are denied and handed back to you as a runbook.

**How they decide.** Each guard is a prompt hook: Claude Code's background model reads the tool call and answers allow or deny. A pattern filter first narrows the calls it is asked about to the ones that could break a rule, such as commands that start with `git` or `gh` and files named like `.env`, so ordinary calls skip the check. A model's judgment is a tripwire, not a boundary: it can misread a call, and a Grep that names a secret file is not checked at all. For a hard stop, add deny rules to your Claude Code settings. When real `.env` files sit in a project, `/m-skills:onboard` offers the rules.

To turn a guard off, remove the plugin or disable it for that project. These hooks cannot read an opt-out file.

## See what runs on your machine

**What the hooks send:** each guarded tool call goes to the model Claude Code already uses for background work, in the same session and under the same account. Nothing goes anywhere else.

**What the profile sweep reads:** `/m-skills:onboard` and `/m-skills:kickoff` have Claude look through your project's manifests, lockfiles, CI config, and `.claude` folder to resolve commands, your Claude Code settings files to see whether the Bash sandbox is on, and the names git reports for `.env` files, now or in its history, never their contents. Nothing is downloaded and no network call is made.

**What the plugin writes:** `.claude/PROJECT-PROFILE.md`, only when you say yes to writing it.

**What the skills fetch:** two skills have Claude request a web page, and only one you point them at. `search-optimization-architect` fetches the pages it audits, the way a crawler sees them; `deployment-architect` checks your deployed app's health endpoint after you report that a deploy landed. Both are read-only requests that send none of your code or project data.

**What they never change: your settings.** When real `.env` files sit on disk and the Bash sandbox is off, Claude offers a deny rule and a sandbox block once, and merges nothing unless you agree.

**Where the guards run:** Claude Code and Cowork. claude.ai chat loads the skills and commands but runs no hooks, so there the rules above are followed by the model rather than enforced.

## License

MIT. See `LICENSE`, and `THIRD-PARTY-NOTICES.md` for the material this plugin adapts. The full documentation and the commented, multi-file sources are in the matis-dev/m-skills repository on GitHub.
