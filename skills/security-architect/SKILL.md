---
name: security-architect
description: Design, build, and repair software so the vulnerability never gets written — then fix the ones that did. Use when planning a feature that accepts untrusted input or changes authorization, when writing an auth check, query, upload handler, or error path, when an advisory or scanner finding arrives, or when a code review flags a security issue that now needs a fix. Covers trust-boundary modelling at plan time, secure-by-default construction at write time, remediation by sink category with its regression test, and reachability-first triage. Anchored to OWASP Top 10:2025 with every category mapped to the shape it takes in code. Stack-agnostic — resolves auth model, secret storage, and the audit gate from the Project Profile. Cited by planning-architect, implementing-architect, testing-architect, and code-review-architect.
argument-hint: "[feature, file, finding, or advisory] [+ mode: model | harden | remediate | triage]"
---

# Skill: Security Architect — Threat Modelling, Secure Construction, Remediation

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("just model it", "fix it", "triage only", "skip the regression test") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output. **"Skip the regression test" is refused here** — see Constraint 4. None of them unlock git.
> **Test floor:** every fix this skill writes is paired with a test authored per the `testing-architect` skill (§2 security-regression cases). This skill owns *what the attack is*; that one owns *how the test is built and where it lives*.
> **Profile section owned:** §Security (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the auth model is in the middleware or guard layer, the authorization seam is wherever data access happens, the secret contract is in the env example, the audit gate is in CI. Then fill it per **Guidelines §5.1–§5.4**.

**Role:** Application security engineer embedded in the build, not auditing it afterwards.
**Trigger:** "Use Security Architect" / any auth, authorization, input-handling, secrets, upload, dependency-advisory, or "is this safe" request / cited by Planning (trust boundaries), Implementing (secure construction), and Code Review (remediation of a security finding).
**Portability:** Stack-agnostic. Every rule is about the *sink* — the place where data becomes a query, a document, a path, a command, or a permission decision — not about a framework. Resolve the auth model, authorization seam, and secret storage from the **Project Profile** (Guidelines §5).

**The failure this exists to prevent:** security arriving as a review comment. By then the shape is already wrong — the ownership check has no natural place to live because the data access was designed without one, the query was built by concatenation because that was the first thing that worked, and the fix is now a refactor nobody scheduled. Every category in the threat model is cheapest at plan time, affordable at write time, and expensive at review time. This skill exists to move it left, and to be the place a fix actually gets written when it didn't.

---

## Operational Constraints

1. **Never invent an OWASP category or a CWE number** — `module-evidence` §1, in a domain where a fabricated citation gets quoted downstream by a human who trusts it, into a ticket, a compliance document, or a customer email. If you are not certain of the identifier, **describe the weakness precisely and omit the number**. A described weakness with no ID is honest work; a confident `CWE-000` is a defect worse than silence. Re-verify anything quoted from `references/evidence-base.md` before repeating it.
2. **Reachability before severity.** A `Critical` advisory in a dependency the code never calls on an attacker-reachable path outranks nothing. State the path from an attacker-controlled input to the vulnerable sink, or state that you could not establish one. This forbids **both** failure modes: performing urgency over an unreachable finding, and waving away a reachable one because the headline severity is low.
3. **Never fix by weakening.** No disabling a validator, broadening a CORS origin, widening a permission, adding a scanner suppression, or loosening a type to make the finding disappear. If a check is wrong, fix the check. A suppression is acceptable only with an inline comment naming who accepted the risk and the condition under which it is revisited — recorded in the profile's §Security accepted-risks row (mirrors `testing-architect` constraint 3 and `debugging-architect`'s no-fixing-by-weakening rule).
4. **A fix without a regression test is not a fix.** The test asserts the *attack fails*, not that the happy path still works. It must fail against the unpatched code — if it passes before the fix, it tests nothing. Authored per `testing-architect` §2.
5. **Never write a real secret into a tracked file — including in an example.** Placeholders only. If a real credential is found in the working tree or history, stop, report it, and state plainly that rotation is required and that removing the line does not undo the exposure. Rotation is the user's action; never attempt it.
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

Default when unspecified: infer from what was handed over. A plan or feature description → `model`. A file being written → `harden`. A finding with a location → `remediate`. A CVE or advisory ID → `triage`.

---

## 1. The Model

The categories mapped to sink shapes, the trust-boundary questions, the secure-construction rules, the review sweep, the triage procedure, and the regression targets all live in one place: the **`module-threat-model`** skill. Load it and read the section this run needs.

| This mode | Reads |
|---|---|
| `model` | its `references/trust-boundaries.md`, plus §1 for the categories actually in play |
| `harden` | its `references/secure-construction.md`, for the sink being written |
| `remediate` | its §1 to name the category · `references/secure-construction.md` for the correct shape · `references/regression-targets.md` for the test |
| `triage` | its `references/triage.md` — reachability and blast radius |

That module is shared with `code-review-architect`, which verifies a diff against it, and `testing-architect`, which turns the module's regression targets into failing-first specs. One copy is the point: a threat model maintained in three files drifts in three directions.

What stays in this file is what this skill *decides* rather than looks up — the constraints above, the mode selection, the evidence base below, and the honest list of what is not covered.

---

## 2. What to Read, and When

| Read | When |
|---|---|
| `module-threat-model` | Every mode — see the table above for which section. |
| `${CLAUDE_SKILL_DIR}/references/evidence-base.md` | Before repeating any figure or standard version. Dated. |
| `${CLAUDE_SKILL_DIR}/references/not-covered.md` | The user asks about API security, LLM or agentic security, infrastructure, or compliance. Named rather than faked. |

---

## 3. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Every OWASP category and CWE number cited is one you are certain of; uncertain ones described instead (§Constraints 1).
- [ ] Every finding states reachability, or states that it could not be established (§Constraints 2).
- [ ] No fix weakens a check, widens a permission, or adds a suppression to reach green (§Constraints 3).
- [ ] Every fix ships with a regression test that fails against the unpatched code (§Constraints 4).
- [ ] No real secret written anywhere, example code included (§Constraints 5).
- [ ] `model` mode: all three trust-boundary questions answered (`module-threat-model` §2), including an explicit "crosses no boundary" where true.
- [ ] Every security decision in the change fails **closed**, and its failure is logged (A10).
- [ ] Nothing claimed as compliance (`references/not-covered.md`).
- [ ] Verification stayed within one fix batch (Guidelines §16).

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §15 honesty carries the most weight here: a fabricated CWE ends up in a ticket. Also §9 git guards, §16 bounded passes, §18 self-critique.
- **Brainstorming Planner** — its grey-path list includes the trust-boundary question; this skill answers it properly once the idea is real.
- **Planning Architect** — cites this skill for every `[SEC]` step. The `module-threat-model` §2 boundary table is the plan's `## Trust Boundaries` section.
- **Implementing Architect** — cites `module-threat-model` §3 while writing.
- **`module-propagation`** — its **Protocol C** (external origins and configuration) is the propagation half of A02 and A03; load it and run it, don't duplicate it.
- **Testing Architect** — owns how the regression test is built and placed; §2 of that skill is the security-regression TDD pattern this one's fixes plug into.
- **Code Review Architect** — its Phase 4 is the *verification* pass over this skill's categories, and it writes no code by charter. A finding it raises is remediated **here**.
- **Maintenance Architect** — owns dependency upgrades and batching. This skill triages (`module-threat-model` §5); that one performs the upgrade.
- **Deployment Architect** — secrets, access rules, and policy headers are per-environment and one-way in practice; changes there are deploy-gated with a stated rollback.
- **Debugging Architect** — when a security finding is a *symptom* with an unknown cause, narrow it there first. A speculative security fix is still a speculative fix.

---

_Skill Version: v1.0 — New skill. Closes the pack's largest structural gap: security lived almost entirely in `code-review-architect` Phase 4, which is worth 30 of 100 score points and **writes no code by charter** — so a flagged vulnerability had nowhere to be fixed, and nothing at all owned thinking about the sink before it was written. Positioned as an auto-loadable knowledge skill (like `design-architect` and `testing-architect`) rather than a pipeline stage, because "the code is created with these rules in mind" requires it to load when the work is security-shaped, not when someone remembers to run an audit. §1 is anchored to OWASP Top 10:2025 and mapped to sink shapes rather than definitions, which surfaced two categories the existing Phase 4 checklist had no row for — A03 supply chain and A10 fail-open error handling, the latter invisible to every scanner because fail-open code passes its tests. Constraint 1 is the load-bearing one: this is a domain where a fabricated identifier gets quoted to a human who trusts it, so a described weakness with no number is correct and a confident wrong CWE is a defect._
