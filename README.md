# m-skills

**A plugin for full-stack developers who use Claude to do their actual work.** It gives the everyday loop (brainstorm, plan, implement, review, document) a fixed shape, so the model stops improvising the process and you stop re-typing the same instructions.

Nothing is tied to one project. Every command, framework, and convention is resolved per repository, from the repo itself or from a `.claude/PROJECT-PROFILE.md` the plugin helps you write, so the same skills work in any codebase.

## Before you install

The hooks are bash scripts that parse their input with `jq` or `python3`, so one of the two must be on your PATH. Without either, the guards deny the call rather than let it through unchecked, and the advisories stay silent.

## Install it

Add it from the Claude directory, or run these in Claude Code:

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

The rest wait until you need them: design, testing, documentation, product slicing, debugging, deployment, maintenance, security, accessibility, marketing, and search visibility, plus 16 route commands such as `/m-skills:threat-model` and `/m-skills:rollback` that open an architect in one mode.

## Know what the hooks enforce

The strictest rules are checked by hooks that deny the call, not by text the model has to remember:

- **No git writes.** Staging, committing, pushing, branching, and every other git write are denied, as are `gh` commands that publish. You get the exact command to paste instead.
- **No auto-accepted golden files.** Snapshot and visual-baseline updates are yours to run after you inspect the diff.
- **No secret files in the conversation.** Reads and writes of real `.env` files and private keys are denied; example files such as `.env.example` stay open.
- **No outward actions.** Deploys, package publishes, and migrations of shared state are denied and handed back to you as a runbook.

To turn the guards off for one project, create an empty file named `.claude/.m-skills-no-guards` in it.

## See what runs on your machine

Every hook is a bash script inside the plugin. None of them makes a network call, downloads a package, or sends data anywhere.

**What the hooks read:** the tool call they are checking; your project's manifests, lockfiles, CI config, and `.claude` folder, to resolve commands; your Claude Code settings files, to see whether the Bash sandbox is on; and the names git reports for `.env` files, never their contents.

**What the hooks write:**

- `m-skills/picks.log` in your Claude config folder (`~/.claude` by default): one line each time you pick a gated skill in the picker, with the time, session, project path, skill, and whether it loaded.
- Once-per-session markers in an `m-skills` folder under your system temp directory, so an advisory or the gate preamble fires once.
- `.claude/PROJECT-PROFILE.md`, only when you say yes to writing it, or when the `M_SKILLS_AUTOPROFILE` environment variable is set to 1.

**What they never change: your settings.** When real `.env` files sit on disk and the Bash sandbox is off, Claude offers a deny rule and a sandbox block once, and merges nothing unless you agree.

**Where the hooks run:** Claude Code and Cowork. claude.ai chat loads the skills and commands but runs no hooks, so there the rules above are followed by the model rather than enforced.

## License

MIT. See `LICENSE`, and `THIRD-PARTY-NOTICES.md` for the material this plugin adapts. The full documentation and the commented, multi-file sources are in the matis-dev/m-skills repository on GitHub.
