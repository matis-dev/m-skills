---
name: module-handover
description: "Module — loaded by name from an m-skills architect, not an entry point. How to hand an action to the user instead of performing it: the runbook shape, one step per command with what it does and how you know it worked, and the copy-paste forms for commits, reverts, and rollbacks."
user-invocable: false
---

# Module: The Handover

**Loaded by:** `deployment-architect` · `security-architect` · `product-architect` · `rolling-history` · `maintenance-architect` · `debugging-architect` · `marketing-architect`. Read it whenever a run stops at an action it must not perform; do not restate its content in a skill file.

**The rule.** Some actions are the user's to fire, always: anything that writes to version control, deploys, publishes, migrates shared state, rotates a secret, changes a production access rule, or notifies other people. Not because they are forbidden in principle, but because the person accountable for them should be the person who triggers them — and because they are hard to undo. The plugin's `guard-mutations.sh` and `guard-outward.sh` hooks deny these at the runtime, so this is not a rule you can forget your way past.

**The deliverable is the handover, not a consolation prize.** "I can't run that" is a failure. A resolved, copy-ready sequence with what each step does and how the user knows it worked is the finished work. Getting this right is what makes the constraint useful rather than merely restrictive.

**Reversible work proceeds freely** — production builds, artifact inspection, config diffing, dry runs, health checks, reading logs, every read-only `git` and `gh` command. Do those without asking. You can prove the artifact is right, prove the config resolves, and prove the health check answers. You just do not push the button.

---

## 1. Before Handing Anything Over

1. **Resolve every placeholder.** A runbook with `<your-project-id>` still in it is not finished work. Read the real value from the profile, a config file, or CI — or mark it as a blocking question. Never guess a command, host, env var, or URL.
2. **Never print a secret.** Not in the brief, not in a command, not in a log excerpt. Reference secrets by name and redact any value you encounter.
3. **State the target in one line at the top** — which environment, what is shipping — so the person pasting cannot be on autopilot about where they are.

## 2. The Runbook Shape

Config and prerequisites first, then one numbered, copy-paste block per command:

```markdown
## Before you start — config and prerequisites

| Variable | Where it is set | Why this needs it |
|---|---|---|
| `<NAME>` | `<platform dashboard / CI secret / .env>` | `<one line>` |

Other prerequisites: `<migration to run, cache to purge, quota raise — or "none">`

## Runbook — you run these

*Nothing here has been executed for you.*

**1. `<what this step does, in the user's words>`**
```bash
<exact command, no placeholders left>
```
*Verify:* `<the observable that says it worked>` · *If it fails:* `<stop / rerun / go to rollback>`
```

Two lines carry most of the value and are the ones most often missing:

- ***What it does*, in the user's words** — not the command restated. Someone pasting a command they do not understand cannot tell a partial success from a total one.
- ***Verify*** — the observable, not the exit code. A platform reporting success is not the app being healthy.

## 3. Then Stop

Do not run the sequence. If a step fails when the user runs it, they come back with the output and you diagnose (`debugging-architect`) — never improvise past a failed step on their behalf, in an environment you cannot see.

## 4. The Short Forms

Not everything needs a full runbook. The same rules apply at smaller scale:

| Situation | The handover |
|---|---|
| Changes are ready to commit | The commit message as **text**, valid against the project's own convention (types, subject case, header limit — read from its config, not assumed), plus the `git commit -m "…"` line in a fenced block. Files stay unstaged. |
| A batch needs reverting | The exact restore command — for a dependency batch, the lockfile *is* the rollback: `git checkout <lockfile> <manifest>`. |
| A release is misbehaving | The resolved rollback command, one step, plus **what rollback does not undo**: migrations, sent mail, charges, client-side caches, service workers. Anything on that list is a one-way door and is named *before* the deploy, not discovered after. |
| A ticket needs filing | The ticket **text**, ready to paste. Filing it notifies people and is theirs to send. |
| A credential was exposed | State plainly that rotation is required and that removing the line does not undo the exposure. Give the steps; never attempt the rotation. |

## 5. No Phrasing Unlocks It

"Ship it", "just push", "commit it for me", "deploy it", or a prior approval for a different environment: none of them change the answer, and a modifier narrows scope without ever lowering this bar (Guidelines §19). Say what you produced and where the button is.
