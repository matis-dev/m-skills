# <Project Name>

> Copy this file to the repo root as `CLAUDE.md`. It loads in **every** session, so it carries only the
> non-negotiables. Everything else lives in the skills and in `.claude/PROJECT-PROFILE.md`.
> Fill the `<…>` slots and delete this block.

## What this is

<One or two lines: what the project does, who uses it.>

## Stack & commands

Resolve commands from `.claude/PROJECT-PROFILE.md`. Never assume a package manager or script name —
read it. A gate that doesn't exist is `n-a`, never invented.

| Role | Command |
|---|---|
| lint | `<…>` |
| typecheck | `<…>` |
| test | `<…>` |
| build | `<…>` |
| e2e / visual | `<…>` |
| a11y | `<…>` |
| run | `<…>` |

## Non-negotiable guards

1. **No git automation.** Never `git add`, `git commit`, `git push`, `git tag`, `git checkout`, `git switch`,
   `--no-verify`, or any force op. Changes stay **unstaged**. This holds even when I say "ship it" — I run the
   git command myself after reviewing.
2. **Stay on the active branch.** No branch creation, no switching.
3. **Never auto-update golden files or visual baselines.** Surface the diff and the report path; the update
   command is mine to run.
4. **Tests ship with the code.** No "tests TBD".
5. **Surgical changes only.** Every changed line traces to what I asked for. No drive-by refactors.
6. **YAGNI.** Build what the task demands. No speculative abstractions, config, or future-proofing.
7. **No fabricated facts.** Every number, path, command, and API in your output is one you read or ran.
   A placeholder beats a plausible invention.
8. **Never weaken a test to get it green.** Fix the code or surface the disagreement. The same holds for a
   security check or an accessibility rule — never fix a finding by disabling the thing that found it.
9. **Every security decision fails closed.** A permission, token, or signature check that errors denies and
   logs. A `catch` never swallows one and continues.
10. **Never invent an OWASP category, a CWE, or a WCAG success criterion.** Describe the weakness and leave it
   unnumbered if you aren't certain — these get quoted into tickets and compliance answers.

## Conventions

- **Design system / UI vocabulary:** `<…>` — survey it before proposing anything custom.
- **Architecture:** match the existing topology; don't introduce a new pattern sideways.
- **Reuse before create:** extend what exists and cite the path.
- **User-facing text:** `<localized via … | plain strings in …>`. Never surface a raw `error.message`.
- **Comments:** only where the *why* is non-obvious.
- **Commits:** `<type>: <subject>` — types `<…>`, subject case `<…>`, enforced by `<config>`.
- **Do not touch:** `<generated dirs, vendored code, lockfiles, migrations>`

## Known blind spots (a green pipeline does not prove these)

- `<e.g. type-check doesn't cover template bindings — only the build does>`
- `<e.g. a blocked external origin renders consistently broken, so visual baselines still pass>`

## How to work here

Skills live in `.claude/skills/`. The pipeline:

```
/brainstorming-planner → /planning-architect → /implementing-architect → /code-review-architect
                       → /rolling-history → /deployment-architect
        ⬑ /design-architect (UI) · /testing-architect (tests) · guidelines-meta (always)
          /security-architect (input, auth, secrets) · /accessibility-architect (interactive) ⬏
```

- Non-trivial change → plan first, get it approved, then implement.
- UI-visible change → `/design-architect` before calling it done.
- Untrusted input, an auth change, a secret, or an advisory → `/security-architect`. At plan time it maps the
  trust boundary; on a finding it writes the fix *and* the regression test that fails without it.
- Modal, menu, drag, async status, or a client-side route change → `/accessibility-architect`. Focus
  destination on open **and** on close is decided with the interaction; no scanner reports it.
- Before I stage anything → `/code-review-architect`.
- End of session → `/rolling-history` for the changelog and a commit brief.
- Shipping → `/deployment-architect <env>`. It prepares and verifies; it never fires a deploy without
  my explicit go-ahead for that environment, and it writes the rollback plan before deploying.
- Something broken → `/debugging-architect <symptom>`. Reproduce first, one hypothesis at a time,
  stop and reassess at three dead ends rather than guessing a fourth time.
- Upkeep and advisories → `/maintenance-architect`. Never bundles an upgrade with a refactor.

## Reply style

Lead with the action or the answer. Numbered steps for sequences. Cap lists at five. End with one concrete
next step. No preamble, no recap of what I just said, no closing pleasantries. Code, commit briefs, and
security warnings are written normally — don't compress those.

This is `guidelines-meta` §17, which applies whenever a pack skill runs. To apply it to everything —
including work that touches no skill — create `.claude/.m-skills-adhd-on` here, or
`~/.claude/.m-skills-adhd-always` for all projects.
