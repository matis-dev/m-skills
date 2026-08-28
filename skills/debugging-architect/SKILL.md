---
name: debugging-architect
description: Diagnose a defect without spiralling. Use when something is broken, failing, flaky, slow, or behaving unexpectedly, and the cause is not yet known. Covers reproduction first, narrowing before hypothesising, one falsifiable hypothesis at a time, a bounded pass ceiling that forces a stop-and-reassess, the regression test written before the fix, and turning the finding into a permanent guard. Stack-agnostic — resolves commands from the Project Profile. For production incidents it restores service before investigating.
argument-hint: "[symptom or failing test] [+ modifiers: production | flaky | prepare only]"
disable-model-invocation: true
---

# Skill: Debugging Architect — Diagnosis Without the Spiral

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("production", "flaky", "just diagnose") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Guardrails → Known blind spots (Guidelines §5). Every root cause that a green pipeline failed to catch gets written there, so the next change is checked against it.

**Role:** Diagnostician. Find the actual cause, prove it, fix it once, and make it impossible to reintroduce silently.
**Trigger:** "Use Debugging Architect" / "This is broken" / "Why is this failing?" / a failing test whose cause isn't obvious.
**Output:** A **Diagnosis** (fixed shape, §Output Format) — reproduction, evidence, root cause, the fix, and the guard that now prevents recurrence.

**Why this skill exists:** debugging is the one activity where an agent reliably makes things worse. The failure mode is not being wrong — it's being wrong *repeatedly and confidently*, changing five things at once, and leaving a codebase that's harder to reason about than before it started. Every rule below exists to stop that.

---

## Operational Constraints (Strict)

1. **Reproduce before you theorise.** A bug you cannot reproduce is a bug you cannot verify you fixed. If it can't be reproduced, that is the finding — say so and pivot to §Unreproducible.
2. **Change one thing at a time.** Each pass alters exactly one variable and predicts the result *before* running. Two simultaneous changes make a passing result uninterpretable.
3. **Hard pass ceiling (Guidelines §16).** Three hypotheses tested and disproved → **stop**. Do not start a fourth. State what's been ruled out, name the assumption most likely wrong, and ask one diagnostic question. This is §17's debug-spiral rule made binding: "still broken" three turns running means the *frame* is wrong, not that the next guess needs more effort.
4. **Never fix by weakening.** Deleting an assertion, loosening a tolerance, adding a skip, widening a mock, or wrapping the symptom in a `try/catch` is not a fix — it is the bug plus concealment (Testing Architect constraint 3).
5. **No speculative fixes.** "This might help" is not a fix. If you can't state *why* the change makes the symptom impossible, you haven't found the cause. Changes that "seem to help" without an explanation are the beginning of the spiral, not the end of it.
6. **Revert your own probes.** Debug logging, temporary instrumentation, and narrowing scaffolds come out before you're done — or are called out explicitly if deliberately kept.
7. **Production first, diagnosis second.** If users are affected, `deployment-architect`'s Rollback Mode runs *first*. Restore service, then debug the artifact at leisure. Production is not a debugging environment.
8. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). A `git add` / `commit` / `push` / branch operation, a `--no-verify`, or a snapshot-update command is **denied by the runtime**. Files stay unstaged and visual diffs stay the user's to review. `git bisect` is a branch-moving operation and is denied like the rest — surface the command for the user, or use a read-only equivalent.

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

---

## Phase 2 — Narrow Before Hypothesising

Resist the first plausible theory. Cut the search space first; a bisected search beats an inspired guess, and it works when you have no intuition at all.

**Bisect along whichever axis is cheapest here:**

- **Time** — which commit introduced it? `git bisect` is the tool; **surface the commands, don't run them** (§8). A `git log` over the suspect paths is often enough.
- **Code path** — does the failure survive when a layer is removed? Call the unit directly, bypass the framework, stub the collaborator.
- **Data** — does it fail for all inputs or one shape? Empty, boundary, unicode, very large, null, pre-migration rows.
- **Environment** — local vs. CI vs. deployed. Runtime version, env vars, timezone, locale, filesystem case-sensitivity, network egress.
- **Config** — does it fail with defaults? A wrong flag is a common and invisible cause.

**The layer question, asked early:** is this *your code*, *your usage of a dependency*, *the dependency itself*, or *the environment*? Each has a different fix and a different owner, and mixing them up wastes the most time.

---

## Phase 3 — One Hypothesis at a Time

For each pass, write these three lines **before** running anything:

```
Hypothesis: <the specific mechanism you believe causes this>
Prediction:  if true, <this exact observable> will happen
Test:        <the single change or probe that discriminates>
```

Rules:
- **The prediction must be falsifiable.** "It'll probably work better" tests nothing. "The value will be `undefined` at line 42" is a real test.
- **A disproved hypothesis is progress** — record it. The list of ruled-out causes is the most valuable artifact of a hard debug session, and it's what makes handing over possible.
- **Confidence gate (from `code-review-architect` §7).** Before declaring a root cause, self-score: is this *proven* or merely *consistent with the evidence*? Below ~80, say so plainly and keep it labelled as a theory. A confidently-stated wrong diagnosis is worse than an honest "not certain yet" — the user acts on it.
- **Count the passes.** At three disproved hypotheses, stop (§3). Not a suggestion.

**Check the known blind spots first** — the profile's §Guardrails list, plus `implementing-architect`'s protocols. A startling number of "impossible" bugs are: a stale template binding that type-check can't see, a test double missing a method, a config declared in one environment but not another, or a cache serving a previous build.

---

## Phase 4 — Prove the Cause

Before fixing, close the loop both ways:

1. **Explain the whole symptom.** A cause that explains most of it is usually adjacent to the real one. Unexplained residue means you're not done.
2. **Make it appear and disappear on demand.** Toggle the cause; the symptom must follow. That's proof, not correlation.
3. **Explain the "why now"** — if this code is old, what changed to expose it? Skipping this is how the same bug returns in a different shape.

---

## Phase 5 — Fix It Once

1. **Write the failing test first**, per the `testing-architect` skill. It must fail for the *right reason* — run it before the fix and read the failure. A regression test that would pass without the fix is decoration.
2. **Fix the cause, not the symptom.** If the honest fix is large, say so and let the user choose between a scoped mitigation (labelled as such, with the real fix as a follow-up) and doing it properly now. Never disguise a mitigation as a fix.
3. **Smallest change that removes the cause** (Guidelines §2, §3). Do not refactor the surrounding area because you were in there.
4. **Check propagation.** If the fix touches shared shape, a public API, or an external origin, run the matching protocol from the `implementing-architect` skill — bug fixes hit the same mirror sites features do, with less scrutiny.
5. **Run the gates**, in the profile's order, once as a batch.
6. **Remove your probes** (§6).

---

## Phase 6 — Make It Impossible to Recur Silently

The step that separates debugging from firefighting. A fix nobody can accidentally undo is worth more than the fix itself.

- **The regression test stays.** Named for the bug's behaviour, not its ticket.
- **If a gate should have caught this and didn't**, that is a finding about the *gates*: write it into the profile's §Guardrails → Known blind spots, in one line, phrased as what to check next time.
- **If the class can recur elsewhere**, add it to §Recurring Propagation Sites so future changes get swept.
- **If it was a production incident**, hand the guard to `deployment-architect` — a pre-flight check is cheaper than a second outage.
- **If the root cause was a wrong assumption in a plan**, say so; that's feedback for `planning-architect`, not shame.

---

## Flaky / Intermittent Failures

Different discipline: you're proving a *rate*, not a state.

1. **Quantify first.** Run it 20–50 times and record the failure rate. "Sometimes" is not a measurement, and without a baseline you cannot tell a fix from luck.
2. **The usual causes, in the order they actually occur:** shared state between tests (order dependence), real time or timezone, unawaited async work, ordering assumptions over unordered collections, a shared external resource, resource exhaustion under parallelism, and randomness without a fixed seed.
3. **Try order dependence early** — run the test alone, then in reverse order. It's cheap and it's the most common cause.
4. **Never "fix" a flake by retrying it.** A retry hides a real race that will surface in production, where nothing retries for you. Retry is acceptable only for a genuinely external dependency, and only with a comment saying which one.
5. **Verify with the same measurement.** Same run count, failure rate at zero. One green run proves nothing about a 5% flake.

---

## Unreproducible

If it can't be reproduced, stop guessing and improve observability instead:

- Say plainly that it is not reproduced, and that anything below is a theory.
- Collect what exists: logs, traces, error reports, the exact environment, the user's steps.
- **Add the instrumentation that would identify it next time**, and say what signal to look for. Shipping a diagnostic is a legitimate outcome.
- Note the conditions under which it was seen; a pattern across reports is often the diagnosis.
- Do **not** ship a speculative fix for an unreproduced bug (§5). It creates the illusion of resolution and destroys the evidence trail.

---

## Output Format (Fixed)

```markdown
# Diagnosis: <symptom in one line>

**Status:** root cause proven / probable cause (unproven) / not reproduced
**Next action:** <the single thing the user does now>

## Symptom
- Expected: <…> · Actual: <…>
- Smallest reproduction: <steps or command>
- Deterministic: yes / no (<rate>) · Environments affected: <…>

## Ruled Out
- <hypothesis> — disproved by <observation>

## Root Cause
`path/to/file.ext:LN` — <the mechanism, in plain language>
**Why now:** <what changed to expose it>
**Confidence:** <proven — toggled on and off / probable — consistent but not isolated>

## Fix
- Failing test added: `<path>` — fails before, passes after
- Change: `<path:LN>` — <what and why>
- Propagation checked: <n-a / protocol A|B|C run>
- Gates: <results>

## Guard Against Recurrence
- Regression test: `<path>`
- Blind spot recorded: <one line for the profile — or n-a>
- Probes removed: yes
```

---

## Quality Checklist Before Claiming "Fixed"

- [ ] Reproduced before diagnosing — or explicitly reported as unreproduced.
- [ ] Narrowed before hypothesising; the search was cut, not guessed at.
- [ ] Each pass changed one variable with a written, falsifiable prediction.
- [ ] Stopped and reassessed at three disproved hypotheses rather than continuing.
- [ ] Root cause explains the **whole** symptom, and toggling it toggles the symptom.
- [ ] Failing test written first, and it failed for the right reason.
- [ ] Fix addresses the cause; any mitigation is labelled a mitigation.
- [ ] Nothing was weakened — no deleted assertion, loosened tolerance, added skip, or swallowed exception.
- [ ] Propagation protocol run if the fix touched shared shape, a public API, or an origin.
- [ ] Debug probes removed.
- [ ] Blind spot written to the profile if a gate should have caught this.
- [ ] Confidence stated honestly; an unproven cause is labelled unproven.
- [ ] **No `git add`, `commit`, `push`, or `bisect`** — commands surfaced for the user.

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §16 bounded passes is the load-bearing one here; §15 honesty forbids a confidently-wrong diagnosis; §17's debug-spiral clause is enforced as constraint 3.
- **Testing Architect** — writes the failing-first regression test; its §3 green-but-lying traps are frequently the cause when a test "passes but the feature is broken".
- **Implementing Architect** — its propagation protocols apply to fixes exactly as to features, and its blind-spot list is the first place to look.
- **Code Review Architect** — the confidence gate; and a review finding too subtle to diagnose from the diff comes here.
- **Deployment Architect** — production incidents roll back *first*; the resulting guard becomes a pre-flight check.
- **Planning Architect** — if the cause was a wrong assumption in a plan, that's plan feedback, not a code problem.

---

_Skill Version: v1.0 — New skill covering the pipeline's largest gap: every other stage assumed the cause was already known. Built around the failure mode agents actually exhibit — being wrong repeatedly and confidently while changing several things at once — so the binding rules are the hard three-hypothesis ceiling (making Guidelines §17's debug-spiral clause enforceable), one falsifiable prediction per pass, no speculative fixes, and no fixing by weakening. Separate disciplines for flaky failures (prove a rate, never retry a race away) and unreproducible reports (ship instrumentation, not a guess). Phase 6 closes the incident→prevention loop the pack previously lacked, writing gate blind spots back to the Project Profile so the next change is checked against what was learned._
