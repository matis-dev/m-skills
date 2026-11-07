---
name: debugging-architect
description: Use when something is broken, failing, flaky, or slow and the cause is not yet known. Reproduce, narrow, then one falsifiable hypothesis at a time under a three-hypothesis ceiling; regression test before the fix; a guard so it cannot recur silently. Produces a fixed-shape Diagnosis. Production incidents restore service first.
argument-hint: "[symptom or failing test] [+ modifiers: production | flaky | prepare only]"
disable-model-invocation: true
---

# Skill: Debugging Architect — Diagnosis Without the Spiral

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Profile section owned:** §Guardrails → Known blind spots (Guidelines §5). Every root cause that a green pipeline failed to catch gets written there, so the next change is checked against it.


**Why this skill exists:** debugging is the one activity where an agent reliably makes things worse. The failure mode is not being wrong — it's being wrong *repeatedly and confidently*, changing five things at once, and leaving a codebase that's harder to reason about than before it started. Every rule below exists to stop that.

---

## Operational Constraints (Strict)

1. **Reproduce before you theorise.** A bug you cannot reproduce is a bug you cannot verify you fixed. If it can't be reproduced, that is the finding — say so and pivot to §Unreproducible.
2. **Change one thing at a time.** Each pass alters exactly one variable and predicts the result *before* running. Two simultaneous changes make a passing result uninterpretable.
3. **Hard pass ceiling (Guidelines §16).** Three hypotheses tested and disproved → **stop**. Do not start a fourth. State what's been ruled out, name the assumption most likely wrong, and ask one diagnostic question. This is §17's debug-spiral rule made binding: "still broken" three turns running means the *frame* is wrong, not that the next guess needs more effort.
4. **Never fix by weakening.** Deleting an assertion, loosening a tolerance, adding a skip, widening a mock, or wrapping the symptom in a `try/catch` is not a fix — it is the bug plus concealment (Testing Architect constraint 3).
5. **No speculative fixes.** "This might help" is not a fix. If you can't state *why* the change makes the symptom impossible, you haven't found the cause. Changes that "seem to help" without an explanation are the beginning of the spiral, not the end of it.
6. **Revert your own probes.** Tag every debug log and temporary probe with one unique prefix for the session (`[DEBUG-a4f2]`), so removal is a single grep. Probes, instrumentation, and narrowing scaffolds come out before you're done — or are called out explicitly if deliberately kept.
7. **Production first, diagnosis second.** If users are affected, `deployment-architect`'s Rollback Mode runs *first*. Restore service, then debug the artifact at leisure. Production is not a debugging environment.
8. **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open. `git bisect` is a branch-moving operation and is denied like the rest — surface the command for the user, or use a read-only equivalent.

---

## What to Read, and When

The six phases below are the spine and apply to every run. These are read on demand:

| Read | When |
|---|---|
| `<this-skill>/references/flaky.md` | The failure is intermittent. Different discipline: you are proving a *rate*, not a state. |
| `<this-skill>/references/slow.md` | The symptom is slowness, or the ask is "make it faster". You are moving a measured number. |
| `<this-skill>/references/unreproducible.md` | It cannot be reproduced. Ship instrumentation, not a guess. |
| `<this-skill>/references/diagnosis-format.md` | Writing up the result. |
| `module-gate-battery` | Running the gates after the fix — and §3 when a test "passes but the feature is broken". |
| `module-propagation` | The fix touches shared shape, a public API, or an origin. |
| `module-findings` | Stating confidence in a root cause. |

---

## Phase 1 — Establish the Symptom

Answer these before touching code. Guessing here costs whole sessions.

| Question | Why it matters |
|---|---|
| **What exactly happens, and what was expected?** | "It doesn't work" is not a symptom. Get the actual output, error, or wrong value. |
| **What's the smallest input that triggers it?** | Reduction *is* diagnosis — a shrinking repro usually names the cause on its own. |
| **When did it last work?** | A known-good point converts an open search into a bounded one. |
| **What changed since?** | Code, dependency, data, config, environment, clock, or a service you don't own. |
| **Deterministic or intermittent?** | Intermittent means state, ordering, timing, or concurrency — see §Flaky. |
| **Where does it *not* happen?** | Passing locally but failing in CI is itself a diagnosis: environment, not logic. |

**Get the real error text.** Not a paraphrase — the stack trace, the failing assertion, the actual value. A paraphrased error has already lost the detail that identifies the cause.

**Several symptoms, or a "why does X behave like this" spanning subsystems?** Write the questions down first, each with the evidence that would answer it. Before finishing, mark every one **answered**, **partial**, or **unresolved** — a broad investigation is never reported complete while a question is still open.

**Exit: one red command.** Phase 1 is done when you can name one command — a test invocation, a script, a curl, a CLI run against a fixture — that you have **already run**, shown with its output, and that is:

- **Red on this bug** — it drives the real code path and fails on the user's exact symptom, not a nearby failure, so it can go green once fixed. "Runs without crashing" catches nothing.
- **Deterministic** — same verdict every run; for an intermittent bug, a pinned reproduction rate (§Flaky).
- **Fast and unattended** — seconds, no human in the loop.

Every later phase consumes this command. Reading code to build a theory before it exists is the spiral starting.

**Reproduces only by hand** — a click sequence, a device, a third-party UI? The red check is those steps written down and run once with the result shown; scripting them is the first Phase 2 cut, where a seam allows. That is reproduced, not §Unreproducible. Nothing reproduces after a real attempt → §Unreproducible, listing what you tried.

---

## Phase 2 — Narrow Before Hypothesising

Resist the first plausible theory. Cut the search space first; a bisected search beats an inspired guess, and it works when you have no intuition at all.

**Bisect along whichever axis is cheapest here:**

- **Time** — which commit introduced it? `git bisect` is the tool; **surface the commands, don't run them** (§8). A `git log` over the suspect paths is often enough.
- **Code path** — does the failure survive when a layer is removed? Call the unit directly, bypass the framework, stub the collaborator.
- **Data** — does it fail for all inputs or one shape? Empty, boundary, unicode, very large, null, pre-migration rows.
- **Environment** — local vs. CI vs. deployed. Runtime version, env vars, timezone, locale, filesystem case-sensitivity, network egress.
- **Config** — does it fail with defaults? A wrong flag is a common and invisible cause.

**Minimise as you narrow.** Cut inputs, callers, config, data, and steps one at a time, rerunning the red command after each cut. Done when every remaining element is load-bearing — removing any one turns it green. The minimal repro shrinks Phase 3's suspect list and becomes Phase 5's regression test.

**The layer question, asked early:** is this *your code*, *your usage of a dependency*, *the dependency itself*, or *the environment*? Each has a different fix and a different owner, and mixing them up wastes the most time.

---

## Phase 3 — One Hypothesis at a Time

**Rank first, then test one.** List 3–5 candidate mechanisms, most likely first, before testing any — a single candidate anchors on the first plausible idea. Show the ranked list to the user: they often re-rank it in one line ("we changed #3 yesterday") or have already ruled one out. Proceed on your ranking if they're away.

Then for each pass, write these three lines **before** running anything:

```
Hypothesis: <the specific mechanism you believe causes this>
Prediction:  if true, <this exact observable> will happen
Test:        <the single change or probe that discriminates>
```

Rules:
- **The prediction must be falsifiable.** "It'll probably work better" tests nothing. "The value will be `undefined` at line 42" is a real test.
- **A disproved hypothesis is progress** — record it. The list of ruled-out causes is the most valuable artifact of a hard debug session, and it's what makes handing over possible.
- **Confidence gate** (`module-findings` §2). Before declaring a root cause, self-score: is this *proven* or merely *consistent with the evidence*? Below ~80, say so plainly and keep it labelled as a theory. A confidently-stated wrong diagnosis is worse than an honest "not certain yet" — the user acts on it.
- **Count the passes.** At three disproved hypotheses, stop (§3). Not a suggestion.

**Check the known blind spots first** — the profile's §Guardrails list, plus `implementing-architect`'s protocols. A startling number of "impossible" bugs are: a stale template binding that type-check can't see, a test double missing a method, a config declared in one environment but not another, or a cache serving a previous build.

---

## Phase 4 — Prove the Cause

Before fixing, close the loop both ways:

1. **Explain the whole symptom.** A cause that explains most of it is usually adjacent to the real one. Unexplained residue means you're not done.
2. **Make it appear and disappear on demand.** Toggle the cause; the symptom must follow. That's proof, not correlation.
3. **Explain the "why now"** — if this code is old, what changed to expose it? Skipping this is how the same bug returns in a different shape. Code that looks wrong on purpose: check the file the profile's **Decisions** row names before treating it as the bug.

---

## Phase 5 — Fix It Once

1. **Write the failing test first**, per the `testing-architect` skill, from the Phase 2 minimal repro. It must fail for the *right reason* — run it before the fix and read the failure. A regression test that would pass without the fix is decoration. **If no seam reproduces the real pattern** (a single-caller unit test for a bug that needs two callers), a test there is false confidence: say so, and record the missing seam in Phase 6 as a finding about the architecture.
2. **Fix the cause, not the symptom — at the boundary that produces it.** Fix the producer of the bad value before adding downstream repairs, then grep its consumers for the same rule reinterpreted elsewhere; a fix in one caller while the shared code stays broken is a mitigation. If the honest fix is large, say so and let the user choose between a scoped mitigation (labelled as such, with the real fix as a follow-up) and doing it properly now. Never disguise a mitigation as a fix.
3. **Smallest change that removes the cause** (Guidelines §2, §3). Do not refactor the surrounding area because you were in there.
4. **Check propagation.** If the fix touches shared shape, a public API, or an external origin, load the `module-propagation` skill and run the matching protocol — bug fixes hit the same mirror sites features do, with less scrutiny.
5. **Run the gates** per the `module-gate-battery` skill, once as a batch.
6. **Remove your probes** (§6).

---

## Phase 6 — Make It Impossible to Recur Silently

The step that separates debugging from firefighting. A fix nobody can accidentally undo is worth more than the fix itself.

- **The regression test stays.** Named for the bug's behaviour, not its ticket.
- **If no seam could hold that test** (Phase 5 step 1), write the missing seam into the profile's §Guardrails → Known blind spots, in one line, phrased as what would let the next bug of this shape be tested.
- **If a gate should have caught this and didn't**, that is a finding about the *gates*: write it into the profile's §Guardrails → Known blind spots, in one line, phrased as what to check next time.
- **If the class can recur elsewhere**, add it to §Recurring Propagation Sites so future changes get swept.
- **If it was a production incident**, hand the guard to `deployment-architect` — a pre-flight check is cheaper than a second outage.
- **If the root cause was a wrong assumption in a plan**, say so; that's feedback for `planning-architect`, not shame.

Close with the picker (Guidelines §17 rule 3): `Review the fix → code-review-architect` first, `Guard the release → deployment-architect` when it was a production incident, `Stop here`.

---

## Quality Checklist Before Claiming "Fixed"

- [ ] One red command named, run, and shown before diagnosing — or written by-hand steps run once, or explicitly reported as unreproduced.
- [ ] Narrowed and minimised before hypothesising; every element left in the repro is load-bearing.
- [ ] Hypotheses ranked and shown before the first was tested.
- [ ] Each pass changed one variable with a written, falsifiable prediction.
- [ ] Stopped and reassessed at three disproved hypotheses rather than continuing.
- [ ] Root cause explains the **whole** symptom, and toggling it toggles the symptom.
- [ ] Failing test written first, and it failed for the right reason.
- [ ] Fix addresses the cause; any mitigation is labelled a mitigation.
- [ ] Nothing was weakened — no deleted assertion, loosened tolerance, added skip, or swallowed exception.
- [ ] Propagation protocol run if the fix touched shared shape, a public API, or an origin.
- [ ] Debug probes removed — a grep for the session's `[DEBUG-…]` tag returns nothing.
- [ ] Blind spot written to the profile if a gate should have caught this, or if no seam could hold the regression test.
- [ ] Confidence stated honestly; an unproven cause is labelled unproven.
- [ ] **No `git add`, `commit`, `push`, or `bisect`** — commands surfaced for the user.

---

_v1.0 — version history in CHANGELOG.md_
