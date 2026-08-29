---
name: deployment-architect
description: Take a reviewed change set to production safely. Use when the user wants to deploy, ship, release, cut a version, promote to staging or prod, or roll back. Covers the readiness gate, release preparation (version, changelog, notes), the pre-flight risk pass (config and secrets, migrations, assets and caching, external origins, feature flags), a rollback plan written before deploying, post-deploy verification against the real environment, and the blind spots a green pipeline cannot cover. Stack-agnostic — resolves targets and commands from the Project Profile. Prepares and verifies, then hands over a copy-paste runbook; never fires a deploy, migration, publish, or rollback itself.
argument-hint: "[target env] [+ modifiers: prepare only | deploy it | rollback | skip gates]"
disable-model-invocation: true
---

# Skill: Deployment Architect — Release Readiness & Safe Promotion

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("prepare only", "deploy it", "roll back", "skip gates") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Deployment (Guidelines §5). Fill it on first use per **Guidelines §5.1–§5.4** — read the repo first, ask only what the code cannot say, write it back. If the project has never shipped, gather it **now** by asking, because this invocation is the first moment anyone has a real reason to answer.

**Role:** Release Engineer. Get a reviewed change set into an environment without surprises, and know how to get it back out.
**Trigger:** "Use Deployment Architect" / "Ship this" / "Deploy to staging" / "Cut a release" / "Roll back".
**Output:** A **Release Brief** in the fixed shape at `${CLAUDE_SKILL_DIR}/references/release-brief.md` — readiness verdict, the exact commands, the rollback plan, and what to verify after.
**Portability:** The procedure is universal. Targets, commands, environments, and hosting model come from the **Project Profile** (Guidelines §5) §Deployment. Never assume a platform.

**Why this skill exists:** every earlier gate answers "does the code work?" Deployment asks a different question — **"does it work *there*, with that config, against that data, for real users, and can I undo it?"** Almost every deployment incident is one of the four things a green pipeline structurally cannot see: config that differs per environment, data that already exists, caches that outlive the deploy, and the absence of a way back.

---

## Operational Constraints (Strict)

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). Any git command that writes — and any `gh` command that publishes — is **denied by the runtime**, as is `--no-verify` and any snapshot-update command. Read-only inspection stays open. Files stay unstaged and visual diffs stay the user's to review. That includes **release tags** — a tag is still a git write the user owns. Produce the command; they run it.
2. **Never fire an outward-facing action at all — hand it over** (`module-handover`). Deploying, promoting, publishing a package, running a migration against a shared database, and rotating a secret are the user's to run, exactly like a git write (Guidelines §9), and for the same reason: they are hard to undo and the person accountable should be the person who triggers them. No phrasing unlocks this — not "deploy it", not "just ship it", not a prior approval for another environment. **Your deliverable is the runbook.** Enforced by the plugin's PreToolUse hook, which denies the call.
3. **Reversible work proceeds freely** — production builds, artifact inspection, config diffing, dry runs (`terraform plan`, `--dry-run`, `--dry-run=client`), health checks, reading logs. Do these without asking. **This is the half that makes the skill useful rather than merely restrictive:** you can prove the artifact is right, prove the config resolves, and prove the health check answers — you just do not push the button.
4. **The rollback plan is written before the deploy, not after.** A deploy with no stated way back is not ready, regardless of how green the gates are. This is a hard gate, not advice.
5. **Never deploy an unreviewed or unverified change set.** If the gates weren't run, say so and stop — or proceed only under an explicit "skip gates" modifier, with the gap named in the brief (Guidelines §15).
6. **Never invent a command, host, env var, or URL.** Read it from the profile, a config file, or CI. An unknown is a blocking question, not a guess.
7. **Secrets are never printed.** Not in the brief, not in a command, not in a log excerpt. Reference them by name; redact any value you encounter.
8. **Bounded** (Guidelines §16). One readiness pass, one deploy, one verification round. If verification fails, that is a rollback decision — not the start of an open debugging loop against production.

---

## What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/preflight.md` | Phase 3 — the failure classes CI cannot see: config and secrets, data and migrations, caching, external origins, runtime, blast radius. |
| `${CLAUDE_SKILL_DIR}/references/release-brief.md` | Assembling the output. The fixed Release Brief shape. |
| `${CLAUDE_SKILL_DIR}/references/post-deploy.md` | After the user reports the deploy landed. Health, critical path, watch window, the deployed-only symptom table. |
| `module-handover` | Phase 5 — the runbook shape and the short forms. |
| `module-propagation` | Whenever shared shape, an API, or an origin changed. Protocol C is the most common source of findings here. |

---

## Phase 0 — Resolve the Deployment Profile

From the Project Profile §Deployment (add the section if it's missing — see the template). What you need before anything else:

| Question | Why it decides the procedure |
|---|---|
| **Hosting model?** static/CDN · serverless · long-running server · container/orchestrator · package registry · mobile store · desktop installer | Determines rollback mechanism and cache behavior more than any other fact. |
| **Environments and their order?** e.g. local → preview → staging → production | Skipping a rung is a decision to be stated, not a default. |
| **Deploy command or mechanism per environment?** | Push-to-deploy, a CLI, a pipeline trigger, a manual artifact upload. |
| **Who fires it?** the user, CI on merge, an approval gate | If CI deploys on merge, this skill's job ends at "the merge is safe" — say so. |
| **Rollback mechanism?** instant re-point, redeploy previous artifact, revert-and-rebuild, registry yank | Their recovery times differ by orders of magnitude. Know which you have. |
| **Health/smoke check?** an endpoint, a critical user path, a synthetic check | This is what "verified" means after the deploy. |
| **Config source per environment?** | Where env vars actually come from, and who can see them. |
| **Data/migration story?** | Whether this release touches persistent state. |

**This section is normally empty the first time you run** — most projects have never written down how they ship. That is expected, not a failure: this invocation is the first moment anyone has a concrete reason to answer. So gather it here, now, in one short pass:

- Ask **only** what this run needs. Deploying to staging does not require production's rollback story.
- **Prefer reading over asking.** Most rows are already written down somewhere in the repo — `${CLAUDE_SKILL_DIR}/references/profile-rows.md` names which file usually answers each one.

  Ask only for what none of these can say: **who is allowed** to fire production, **where production secrets actually live**, the **rollback they would really perform** under pressure, and the **critical path** worth verifying afterwards.
- A row nobody can answer yet is `pending: <when>`, not a guess. **The exception is rollback:** you cannot deploy without one, so if it's unknown, resolving it *is* the next step (Constraint 4).
- Write what you learn back to the profile so the second deploy asks nothing.

For a project that has **never shipped anything**, these are decisions, not discoveries — propose an option with a one-line rationale (hosting model follows from the app shape more than from taste), and record it once the user picks.

---

## Phase 1 — Readiness Gate

Answer each with yes / no / n-a. Any "no" stops the deploy and is stated plainly.

- **Gates green?** The profile's full pipeline passed on *this* change set — not a similar one, not yesterday's (`module-gate-battery`, run by `implementing-architect`).
- **Reviewed?** `code-review-architect` ran and its Criticals and Highs are resolved, or explicitly accepted by the user in writing.
- **Propagation protocols run?** If shared shape, a public API, or an external origin changed, the `module-propagation` protocols A/B/C completed. **These are the change classes that pass CI and break in production.**
- **Production build, not a dev build?** Built with the production configuration, correct base path, optimizations on, source maps handled per policy.
- **Changelog current?** `rolling-history` ran; the release has a written record of what's in it.
- **Version decided?** Per the project's scheme, and consistent everywhere it appears (manifest, lockfile, app-visible version string, container tag).
- **Migrations reversible or forward-compatible?** See Phase 3 and its reference.
- **Rollback plan written?** Constraint 4. Hard gate.

---

## Phase 2 — Release Preparation

1. **Version** — bump per the project's scheme. Every place the version appears moves together (this is a change-propagation problem; treat it as one).
2. **Release notes** — derived from the changelog, written for whoever reads them: users get behavior changes, operators get required actions (a new env var, a migration to run, a cache to purge). **Never invent a fix or feature that isn't in the diff** (Guidelines §15).
3. **Breaking changes named explicitly**, with the migration path for consumers. If this ships a breaking change without one, that is a finding, not a footnote.
4. **Artifacts** — what actually ships: bundle, image, package, binary. Note the size and how it moved. A sudden jump is a dependency mistake caught cheaply here.
5. **The commands** — assemble the exact sequence, in order, ready to copy. No placeholders left unresolved.

---

## Phase 3 — Pre-Flight Risk Pass

The failure classes CI structurally cannot see — per-environment config and secrets, pre-existing data and migrations, caches that outlive the deploy, external origins and policy, runtime compatibility, and blast radius. Each is yes/no/n-a; any yes is a finding with severity, and a clean category is stated clean rather than omitted.

**Read `${CLAUDE_SKILL_DIR}/references/preflight.md` and work through it.** Skipping this phase is how a green pipeline ships an outage.

---

## Phase 4 — The Rollback Plan (written before deploying)

Not optional, not "revert the commit". Answer all four:

1. **Trigger** — what observation makes us roll back? Name the signal and the threshold, decided *now*, before the pressure.
2. **Mechanism** — the exact command or steps, resolved and copy-ready.
3. **Time to recover** — realistically, how long from decision to restored service?
4. **What rollback does *not* undo** — the honest part. A code rollback does not un-run a migration, un-send an email, un-charge a card, un-invalidate a cache, or clear a service worker on a user's device. **Anything on this list is a one-way door and must be named before the deploy, not discovered after.**

If a one-way door exists and can't be avoided, say so explicitly and let the user decide with that in hand.

---

## Phase 5 — Handover

You assemble; the user fires (Constraint 2). The shape, the resolve-every-placeholder rule, the never-print-a-secret rule, and the *what it does / how you know it worked* lines are in the **`module-handover`** skill. Load it and emit the runbook in that shape.

Two things this phase adds on top of the module:

1. **State the target environment and what is shipping** in one line at the top, so the person pasting cannot be on autopilot about which environment they are in.
2. **Say what to watch during the deploy**, not just its exit code — the platform reporting success is not the app being healthy. Name the signal.

Then stop. If a step fails when the user runs it, they come back with the output and you diagnose (`debugging-architect`) — never improvise past a failed deploy step on their behalf.

## Phase 6 — Post-Deploy Verification

Runs **after the user reports the deploy landed**, against the **real environment** — never against local state or a green CI run. Uses only the reversible checks Constraint 3 already permits.

**Read `${CLAUDE_SKILL_DIR}/references/post-deploy.md`** for the procedure and the symptom→cause table for things that break only in a deployed environment.

State the verdict plainly: **verified**, **rolled back**, or **watching** with what you're watching and for how long. If verification fails, the decision is rollback (Constraint 8) — production is not a debugging environment.

---

## Rollback Mode

Invoked with "roll back". Skip straight to it — the readiness gate is irrelevant when something is already broken.

1. **State the current symptom** in one line. Don't diagnose first; restore first.
2. **Hand over the rollback command** from the plan — resolved, copy-ready, one step (`module-handover` §4), or resolve it now if no plan exists. A rollback is a production write, so it is the user's to run under Constraint 2; speed comes from the command already being correct, not from you typing it.
3. **Verify recovery** with the same health check and critical path.
4. **Name what rollback did not undo** and what still needs manual repair.
5. **Only then** investigate cause. Write the finding into the changelog and, if it's a recurring class, into the profile's blind spots so the next release checks for it.

---

## Quality Checklist (before claiming "Deployed")

- [ ] Deployment profile resolved; no invented commands, hosts, or env vars.
- [ ] Readiness gate answered in full; any "no" surfaced rather than worked around.
- [ ] Pre-flight risk pass covered every category; clean ones explicitly noted clean.
- [ ] New env vars enumerated and confirmed present in the **target**, not just locally.
- [ ] No secret printed, logged, or embedded in a shipped artifact.
- [ ] Migration reversibility and ordering assessed; backup/restore point confirmed where state changes.
- [ ] Cache and service-worker behavior considered — including its effect on rollback.
- [ ] Rollback plan written **before** deploying, with the one-way doors named honestly.
- [ ] Nothing outward-facing was executed — the deploy, migration, publish, or rollback was handed over as a runbook (Constraint 2).
- [ ] Every runbook step is copy-ready per `module-handover`: no unresolved placeholder, each with what it does and how the user knows it worked.
- [ ] Post-deploy verification run against the real environment *after the user reported it landed*, including one real user path.
- [ ] Verdict stated plainly: verified / rolled back / watching.
- [ ] **No `git add`, `commit`, `push`, or `tag`** — every git operation left to the user.

---

## When to Use This Skill

- After `code-review-architect` passes and `rolling-history` has logged the change — the last stage of the pipeline.
- To assess readiness well before the release, when findings are still cheap to fix. (Every run is "prepare only" — this skill never deploys.)
- To produce the rollback command for a release that's misbehaving, fast and correct, for the user to run.
- To write the Deployment section of a Project Profile for a project that has never documented how it ships.

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §9 git guards (tags included), §15 honesty, §16 bounded passes.
- **`module-propagation`** — its Protocol C (external origins and configuration declared in more than one place) is the single most common source of pre-flight findings here. Load it when the readiness gate reaches that row.
- **Code Review Architect** — its verdict is an input to the readiness gate; unresolved Criticals block.
- **Rolling History** — supplies the changelog this skill turns into release notes; run it first.
- **Testing Architect** — a production incident that could have been caught by a test becomes a failing-first regression test before the fix ships.

---

_Skill Version: v1.0 — New skill closing the pipeline. Framework- and platform-agnostic: hosting model, environments, deploy mechanism, rollback mechanism, and health checks all resolve from the Project Profile §Deployment, and an unanswerable row is a blocking question rather than a guess. Structured around the four things a green pipeline structurally cannot see — per-environment config, pre-existing data, caches that outlive the deploy, and the absence of a way back — with the rollback plan as a hard gate written before deploying and its one-way doors named explicitly. Inherits the pack's git guards including release tags, and treats deploying, publishing, migrating shared state, and rotating secrets as actions the user fires — this skill assembles the runbook and never pushes the button, enforced by the plugin's `guard-outward.sh` hook rather than stated as advice._
