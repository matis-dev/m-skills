---
name: rolling-history
description: Use at the end of a session to update the changelog and produce a commit brief as text. Assesses whether README, architecture, deployment, API, or test docs need a surgical edit and hands the writing to documentation-architect. Runs after gates pass and visual diffs are approved. Never executes git.
argument-hint: "[what shipped, if not obvious from the diff] [+ modifiers: skip gates]"
disable-model-invocation: true

---

# Skill: Rolling History (Continuous Documentation)

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Profile section owned:** §Documentation Targets and §Commit Convention (Guidelines §5). §Documentation Standards belongs to `documentation-architect` — read it, don't fill it. Fill it on first use per **Guidelines §5.1–§5.4** — read the repo first, ask only what the code cannot say, write it back. If the repo has no changelog or no commit history to infer from, ask which convention to adopt rather than picking one silently.

**Run only after:** the Implementing Skill's gates have passed **and** the user has manually reviewed (and approved or updated) any failed visual baselines. This skill records what **shipped** — never what's still in flight.

---

## Step 0 — Resolve Targets

From the profile's **Documentation Targets** table, note the changelog path and which other docs exist. From **Commit Convention**, note the allowed types, subject case, and header limit — and the config file that enforces them.

If the profile is absent: find the changelog by looking (`CHANGELOG.md`, `docs/`, `Documentation/`), read the commit convention from the repo's own commitlint/husky config or from `git log --oneline -20`, and **match what the repo already does**. If there is genuinely no changelog, ask before creating one — an unrequested new file at the repo root is scope creep.

> **One changelog.** Whatever the project's canonical file is, that is the only one. Never create a second at a different path because it was easier to find.

---

## Step 1 — Analyze the Context (Content-First)

- **Diff scan** — `git diff HEAD` (uncommitted) or `git diff HEAD~1` (last commit). Read-only; never mutate.
- **Identify key changes** — which modules, services, components, or models were added, modified, removed.
- **Determine the "why"** — from session context, or inferred from the code. If a change is genuinely obscure, **ask** rather than guessing (Guidelines §15 — no invented history).

---

## Step 2 — Update the Changelog

**Match the file's existing structure exactly.** Read it before writing. If it has a technical-baseline section, a table, a diagram, or a specific heading format, mirror it — don't impose a new one.

**Baseline sync (if the file carries a current-state section):**
- Feature **removed** → delete its bullet.
- Feature or hidden logic **added** → add a concise bullet to the right subsection.
- Bump any `last synced <date>` marker to today.
- **The baseline must always describe the current app**, not the history of how it got there. That's what makes it worth reading.

**Diagram check:** if the file carries an architecture diagram and core relationships changed, update it.

**Append the entry** in the file's own format — a table row, a dated section, or a bullet under an `Unreleased` heading, whichever it already uses. Content, regardless of format:
- **Date** and **type** (matching the commit convention's type vocabulary).
- **Title**, then **in-the-trenches technical depth** — the operators, migrations, validation rules, and decisions a future maintainer needs.
- **One line of business value** — why it mattered, in a manager's language.
- **Affected components** — the file/module names, in the file's own markup convention.

New entries go where the file's existing entries go (bottom of a chronological table, top of a reverse-chronological list — check).

---

## Step 3 — Assess Broader Doc Impact

The changelog is always updated. The other docs are **not** — only when the change actually reaches them. For each doc the profile lists, judge whether this session shifts what the file *claims*. **Most sessions touch none of them, and that is the expected outcome.**

| Doc | Reaches it when |
|---|---|
| **README** | User-facing setup, feature list, scripts, or usage changed — a new env var, a new command, a changed run step, a feature a reader would expect listed. |
| **Architecture** | A structural fact changed — new layer or service, altered data flow, a relationship the diagram no longer matches, a new cross-cutting pattern. |
| **Deployment** | How it builds, ships, or runs in production changed — build step, headers/policy, env config, hosting, a migration a deployer must run. |
| **API / contract** | An integration contract changed — endpoint, parameter, payload shape, auth, cache or offline behavior. |
| **Tests** | Test **tooling or strategy** changed — a new layer or command, a changed coverage bar, a new device project, a moved helper, an altered scan scope. |

Rules:
- **Multi-language or duplicated docs:** a surgical edit must update **every** copy. Updating one language block is itself a defect.
- **Output a one-line verdict per doc** — either the specific edit needed, or `no change`.
- **Never rewrite a doc wholesale.** Propose the surgical edit and let the user confirm scope.
- **This skill produces the verdict; `documentation-architect` produces the prose.** When a verdict is anything other than `no change`, hand that doc to the `documentation-architect` skill — it carries the reader-and-type selection, the ground-truth check that every cited command and path is real, and the drift rules. The changelog is the exception and stays here: it is this skill's file alone.
- If every doc is `no change`, say so in one line and move on.
- Docs the profile doesn't list don't exist here — don't propose edits to them.

---

## Step 4 — Generate the Commit Brief

Display in chat. **Never run any git command.** This is text the user copies.

- **Suggested commit message**, valid against the project's own convention:
  - Only the types the project's config allows.
  - **Subject case exactly as enforced** — read the rule from the config rather than assuming. Sentence-case and lower-case projects both exist, and the hook rejects the wrong one. Verify the subject before presenting it; if it violates the rule, rewrite it before showing the user.
  - Header within the project's length limit.
  - Scope included only if the project uses scopes.
- **Detailed summary** — 3–5 bullets on the technical "how".
- **Command to copy** — render the `git commit -m "…"` line in a fenced block per `module-handover` §4. Do **not** execute it.

*Example shape (substitute the project's actual rules):*
> Convention: `<type>: <Sentence case subject>`, types `feat|fix|docs|style|refactor|perf|test|chore|ci`, ≤ 160 chars.
> ✅ `feat: Add offline retry to the sync queue`
> ❌ `feat: add offline retry to the sync queue` — first letter after the colon must be capital under this project's rule.

---

## Guardrails

- **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open. Read-only inspection (`diff`, `log`, `status`) is fine and is what this skill runs. It produces commit text; the user runs the command.
- **Never invent history.** If a change's purpose is unclear, ask. Fabricated rationale in a changelog outlives everyone who could correct it (Guidelines §15).
- **Never let the baseline drift.** It is a current-state summary, not an archive.
- **Never pad the doc-impact assessment.** Most sessions reach no secondary doc; saying so is the correct answer, not a lazy one.
- **Never create a doc the project doesn't have** without asking.
- **Match the file's existing format** rather than improving it mid-session. Format changes are their own task.
- **Keep the markdown clean.** This file is read by humans, often months later.

---

_v2.0 — version history in CHANGELOG.md_
