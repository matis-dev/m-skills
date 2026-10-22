---
name: security-architect
description: Load when planning a feature that takes untrusted input or changes authorization, when writing an auth check, query, upload handler, or error path, when an advisory arrives, when a review finding needs a fix, or when the existing codebase should be audited for vulnerabilities. Models trust boundaries, hardens the sink as it is written, remediates with a regression test, triages by reachability, audits the project read-only. OWASP Top 10:2025.
argument-hint: "[feature, file, finding, advisory, or nothing for the whole project] [+ mode: model | harden | remediate | triage | audit]"
---

# Skill: Security Architect — Threat Modelling, Secure Construction, Remediation

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Test floor:** every fix this skill writes is paired with a test authored per the `testing-architect` skill (§2 security-regression cases). This skill owns *what the attack is*; that one owns *how the test is built and where it lives*.
> **Profile section owned:** §Security (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the auth model is in the middleware or guard layer, the authorization seam is wherever data access happens, the secret contract is in the env example, the audit gate is in CI. Then fill it per **Guidelines §5.1–§5.4**.

**The failure this exists to prevent:** security arriving as a review comment. By then the shape is already wrong — the ownership check has no natural place to live because the data access was designed without one, the query was built by concatenation because that was the first thing that worked, and the fix is now a refactor nobody scheduled. Every category in the threat model is cheapest at plan time, affordable at write time, and expensive at review time. This skill exists to move it left, and to be the place a fix actually gets written when it didn't.

---

## Operational Constraints

1. **Never invent an OWASP category or a CWE number** — `module-evidence` §1, in a domain where a fabricated citation gets quoted downstream by a human who trusts it, into a ticket, a compliance document, or a customer email. If you are not certain of the identifier, **describe the weakness precisely and omit the number**. A described weakness with no ID is honest work; a confident `CWE-000` is a defect worse than silence. Re-verify anything quoted from `references/evidence-base.md` before repeating it.
2. **Reachability before severity.** A `Critical` advisory in a dependency the code never calls on an attacker-reachable path outranks nothing. State the path from an attacker-controlled input to the vulnerable sink, or state that you could not establish one. This forbids **both** failure modes: performing urgency over an unreachable finding, and waving away a reachable one because the headline severity is low.
3. **Never fix by weakening.** No disabling a validator, broadening a CORS origin, widening a permission, adding a scanner suppression, or loosening a type to make the finding disappear. If a check is wrong, fix the check. A suppression is acceptable only with an inline comment naming who accepted the risk and the condition under which it is revisited — recorded in the profile's §Security accepted-risks row (mirrors `testing-architect` constraint 3 and `debugging-architect`'s no-fixing-by-weakening rule).
4. **A fix without a regression test is not a fix.** The test asserts the *attack fails*, not that the happy path still works. It must fail against the unpatched code — if it passes before the fix, it tests nothing. Authored per `testing-architect` §2.
5. **Never write a real secret into a tracked file — including in an example — and never read one into context.** Placeholders only. Variable names come from the env example or the code that reads them; a value that matters is the user's to check. `guard-secrets.sh` enforces both directions. If a real credential is found in the working tree or history, stop, report it, and state plainly that rotation is required and that removing the line does not undo the exposure. Rotation is the user's action; never attempt it.
6. **Never perform an outward-facing or destructive action — hand it over** per `module-handover`. Rotating a key, revoking a session, changing a production access rule, or filing a public advisory are the user's to run, named per environment, and enforced by `guard-outward.sh`. This skill writes code; it does not operate the system.
7. **Bounded verification** (Guidelines §16). Model or fix in one pass → one batched verification → one fix batch → stop. Enumerating a fourth speculative attack path is the security equivalent of the debug spiral.

---

## Modes

| Mode | Fires at | Produces |
|---|---|---|
| **`model`** | **Planning** — the point of this skill | The trust-boundary map for the feature, the categories actually in play, and the per-step `[SEC]` note `planning-architect` carries into the plan. Read-only. |
| **`harden`** | **Implementation**, while the sink is being written | The secure-by-default construction for this specific sink. Not a review — the correct shape, first time. |
| **`remediate`** | A confirmed finding (review, scanner, report) | The fix **plus** its regression test. Names the category and, only when certain, the CWE. |
| **`triage`** | An advisory or a reported vulnerability arrives | Reachability, blast radius, and one of — fix now / fix on the next batch / accept with a revisit condition. Hands the upgrade itself to `maintenance-architect`. |
| **`audit`** | **An existing codebase** — the security read of what is already written | `references/audit.md`: the boundary map, every sink traced to an entry point, findings by reachability, and what was not covered. Read-only; each finding goes to `remediate`. |

Default when unspecified: infer from what was handed over. A plan or feature description → `model`. A file being written → `harden`. A finding with a location → `remediate`. A CVE or advisory ID → `triage`. A path, "check the project", or existing code named with "audit", "check", or "scan" ("audit the auth module") → `audit` of that scope, never `model`: `model` is for what is not built yet. Any of these decides the mode — don't ask.

**Nothing handed over** (a bare invocation, no feature, finding, or advisory under discussion) → ask in the picker (Guidelines §17), one sheet:

| Option | Runs |
|---|---|
| **Audit the whole project (Recommended)** | `audit` of the repository at `HEAD` — no second question |
| Audit one part | `audit`, scoped — second sheet: which part, `multiSelect`, the likeliest areas the repo suggests (directories or modules holding entry points) |
| Threat-model a planned feature | `model` — second sheet: which feature, candidates from open plans and the conversation |
| Fix a finding or triage an advisory | `remediate` or `triage`, by what is picked — second sheet: which one, candidates from the last review or audit and the project's advisory scan |

Before asking, run `git status --porcelain`. **Uncommitted changes present** → the second option becomes **Audit my uncommitted changes (N files)** — `audit` scoped to `git diff HEAD` plus untracked files, no second question — and the last two rows merge into **Something else**, whose second sheet offers threat-model, fix a finding, or triage an advisory.

Ask the second sheet only when its answer is not already in context, and never a third. `harden` is not offered: implementation cites it mid-run, nobody types it.

---

## 1. The Model

The categories mapped to sink shapes, the trust-boundary questions, the secure-construction rules, the review sweep, the triage procedure, and the regression targets all live in one place: the **`module-threat-model`** skill. Load it and read the section this run needs.

| This mode | Reads |
|---|---|
| `model` | its `references/trust-boundaries.md`, plus §1 for the categories actually in play |
| `harden` | its `references/secure-construction.md`, for the sink being written |
| `remediate` | its §1 to name the category · `references/secure-construction.md` for the correct shape · `references/regression-targets.md` for the test |
| `triage` | its `references/triage.md` — reachability and blast radius |
| `audit` | `${CLAUDE_SKILL_DIR}/references/audit.md`, which walks its `references/trust-boundaries.md`, §1, `references/review-sweep.md`, and `references/triage.md` in order |

That module is shared with `code-review-architect`, which verifies a diff against it, and `testing-architect`, which turns the module's regression targets into failing-first specs. One copy is the point: a threat model maintained in three files drifts in three directions.

What stays in this file is what this skill *decides* rather than looks up — the constraints above, the mode selection, the evidence base below, and the honest list of what is not covered.

---

## 2. What to Read, and When

| Read | When |
|---|---|
| `module-threat-model` | Every mode — see the table above for which section. |
| `module-propagation` | `harden` / `remediate` on an external origin or configuration (A02, A03) — its Protocol C is the propagation half; run it, don't duplicate it. |
| `${CLAUDE_SKILL_DIR}/references/evidence-base.md` | Before repeating any figure or standard version. Dated. |
| `${CLAUDE_SKILL_DIR}/references/not-covered.md` | The user asks about API security, LLM or agentic security, infrastructure, or compliance. Named rather than faked. |

---

## 3. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Every OWASP category and CWE number cited is one you are certain of; uncertain ones described instead (§Constraints 1).
- [ ] Every finding states reachability, or states that it could not be established (§Constraints 2).
- [ ] No fix weakens a check, widens a permission, or adds a suppression to reach green (§Constraints 3).
- [ ] Every fix ships with a regression test that fails against the unpatched code (§Constraints 4).
- [ ] No real secret written anywhere, example code included, and no secret file read (§Constraints 5).
- [ ] `model` mode: all three trust-boundary questions answered (`module-threat-model` → `references/trust-boundaries.md`), including an explicit "crosses no boundary" where true.
- [ ] Every security decision in the change fails **closed**, and its failure is logged (A10).
- [ ] `audit` mode: nothing written; scope, commit, search patterns, and what was not covered all stated; the project never called secure.
- [ ] Nothing claimed as compliance (`references/not-covered.md`).
- [ ] Verification stayed within one fix batch (Guidelines §16).

---

_v1.1 — version history in CHANGELOG.md_
