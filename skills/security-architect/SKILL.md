---
name: security-architect
description: Design, build, and repair software so the vulnerability never gets written — then fix the ones that did. Use when planning a feature that accepts untrusted input or changes authorization, when writing an auth check, query, upload handler, or error path, when an advisory or scanner finding arrives, or when a code review flags a security issue that now needs a fix. Covers trust-boundary modelling at plan time, secure-by-default construction at write time, remediation by sink category with its regression test, and reachability-first triage. Anchored to OWASP Top 10:2025 with every category mapped to the shape it takes in code. Stack-agnostic — resolves auth model, secret storage, and the audit gate from the Project Profile. Cited by planning-architect, implementing-architect, testing-architect, and code-review-architect.
argument-hint: "[feature, file, finding, or advisory] [+ mode: model | harden | remediate | triage]"
---

# Skill: Security Architect — Threat Modelling, Secure Construction, Remediation

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("just model it", "fix it", "triage only", "skip the regression test") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output. **"Skip the regression test" is refused here** — see Constraint 4. None of them unlock git.
> **Test floor:** every fix this skill writes is paired with a test authored per the `testing-architect` skill (§2 security-regression cases). This skill owns *what the attack is*; that one owns *how the test is built and where it lives*.
> **Profile section owned:** §Security (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the auth model is in the middleware or guard layer, the authorization seam is wherever data access happens, the secret contract is in the env example, the audit gate is in CI. Then ask at most 3–4 questions covering only what the code cannot say — who may access production data, where secrets actually live, which risks were accepted deliberately and by whom — and write it back. A question the repo already answers is a defect (Guidelines §5.3).

**Role:** Application security engineer embedded in the build, not auditing it afterwards.
**Trigger:** "Use Security Architect" / any auth, authorization, input-handling, secrets, upload, dependency-advisory, or "is this safe" request / cited by Planning (§2 trust boundaries), Implementing (§3 construction), and Code Review (remediation of a Phase 4 finding).
**Portability:** Stack-agnostic. Every rule is about the *sink* — the place where data becomes a query, a document, a path, a command, or a permission decision — not about a framework. Resolve the auth model, authorization seam, and secret storage from the **Project Profile** (Guidelines §5).

**The failure this exists to prevent:** security arriving as a review comment. By then the shape is already wrong — the ownership check has no natural place to live because the data access was designed without one, the query was built by concatenation because that was the first thing that worked, and the fix is now a refactor nobody scheduled. Every category in §1 is cheapest at plan time, affordable at write time, and expensive at review time. This skill exists to move it left, and to be the place a fix actually gets written when it didn't.

---

## Operational Constraints

1. **Never invent an OWASP category or a CWE number.** Guidelines §15 applied to a domain where a fabricated citation gets quoted downstream by a human who trusts it — into a ticket, a compliance document, or a customer email. If you are not certain of the identifier, **describe the weakness precisely and omit the number**. A described weakness with no ID is honest work; a confident `CWE-000` is a defect worse than silence. Re-verify anything quoted from §5 before repeating it.
2. **Reachability before severity.** A `Critical` advisory in a dependency the code never calls on an attacker-reachable path outranks nothing. State the path from an attacker-controlled input to the vulnerable sink, or state that you could not establish one. This forbids **both** failure modes: performing urgency over an unreachable finding, and waving away a reachable one because the headline severity is low.
3. **Never fix by weakening.** No disabling a validator, broadening a CORS origin, widening a permission, adding a scanner suppression, or loosening a type to make the finding disappear. If a check is wrong, fix the check. A suppression is acceptable only with an inline comment naming who accepted the risk and the condition under which it is revisited — recorded in the profile's §Security accepted-risks row (mirrors `testing-architect` constraint 5 and `debugging-architect`'s no-fixing-by-weakening rule).
4. **A fix without a regression test is not a fix.** The test asserts the *attack fails*, not that the happy path still works. It must fail against the unpatched code — if it passes before the fix, it tests nothing. Authored per `testing-architect` §2.
5. **Never write a real secret into a tracked file — including in an example.** Placeholders only. If a real credential is found in the working tree or history, stop, report it, and state plainly that rotation is required and that removing the line does not undo the exposure. Rotation is the user's action; never attempt it.
6. **Confirm before any outward-facing or destructive action.** Rotating a key, revoking a session, changing a production access rule, or filing a public advisory are the user's calls, named per environment. This skill writes code; it does not operate the system.
7. **Bounded verification** (Guidelines §16). Model or fix in one pass → one batched verification → one fix batch → stop. Enumerating a fourth speculative attack path is the security equivalent of the debug spiral.

---

## Modes

| Mode | Fires at | Produces |
|---|---|---|
| **`model`** | **Planning** — the point of this skill | §2 trust-boundary map for the feature, the §1 categories actually in play, and the per-step `[SEC]` note `planning-architect` carries into the plan. Read-only. |
| **`harden`** | **Implementation**, while the sink is being written | The secure-by-default construction from §3 for this specific sink. Not a review — the correct shape, first time. |
| **`remediate`** | A confirmed finding (review, scanner, report) | The fix **plus** its regression test. Names the category and, only when certain, the CWE. |
| **`triage`** | An advisory or a reported vulnerability arrives | §4: reachability, blast radius, and one of — fix now / fix on the next batch / accept with a revisit condition. Hands the upgrade itself to `maintenance-architect`. |

Default when unspecified: infer from what was handed over. A plan or feature description → `model`. A file being written → `harden`. A finding with a location → `remediate`. A CVE or advisory ID → `triage`.

---

## 1. The Categories, as They Appear in Code

**OWASP Top 10:2025** is the spine — resolve the tracked standard from the profile's §Security if the project pins a different one. Each row maps the category to the *sink shape* you can actually grep for, because a definition you cannot recognize in a diff is not a working control.

| # | Category | What it looks like in the code |
|---|---|---|
| **A01** | Broken Access Control | An id from a route, query, or body used to select or mutate a record with no ownership check (IDOR). A route added without the guard its siblings carry. Authorization enforced in the UI but not at the data access. A user-controlled string building a file path or storage key without normalizing `..` (path traversal). |
| **A02** | Security Misconfiguration | Debug or verbose errors reaching a user. Default credentials or permissive defaults left in place. Over-broad CORS. A missing or unenforced security-policy header. Permissions granted at the framework's default rather than deliberately. |
| **A03** | **Software Supply Chain Failures** *(new in 2025 — broader than "vulnerable dependencies")* | An unpinned dependency, action, or base image. A build step fetching a script over the network and executing it. A lockfile change nobody read. A package whose name is one character from the real one. CI credentials with more scope than the job needs. Publishing from an unverified pipeline. |
| **A04** | Injection | User-controlled string interpolated into a query, template, shell command, or URL rather than parameterized. Raw HTML/markup binding without sanitization, or a "trust this value" escape hatch with no inline justification. Dynamic code execution — `eval`, string-argument timers, a dynamic import of a user-controlled path. |
| **A05** | Cryptographic Failures | Sensitive data in transit or at rest without protection. Home-rolled crypto. A fast general-purpose hash used for passwords. A predictable token or ID where unpredictability is the control. Secrets in client-reachable code. |
| **A06** | Vulnerable & Outdated Components | Advisories against dependencies the change actually touches. Triage per §4; the upgrade itself belongs to `maintenance-architect`. |
| **A07** | Authentication Failures | Credential stuffing with no rate limit or lockout. Session identifier not rotated on privilege change. Tokens that never expire or cannot be revoked. Password reset that leaks account existence. Weak or missing second factor where the profile says one is required. |
| **A08** | Data Integrity Failures | Parsed untrusted input merged, spread, or assigned into an existing object without key filtering — a prototype-pollution sink. Deserializing untrusted data into live objects. Imported data trusted for *shape* without passing the validator before it reaches storage. An update from an unverified source. **Structured cloning does not sanitize** — it preserves attacker-controlled keys. |
| **A09** | Security Logging & Alerting Failures | An authentication or authorization failure that produces no record. Nothing that would alert on a burst of them. The inverse defect: tokens, PII, or request bodies written *into* logs. |
| **A10** | **Mishandling of Exceptional Conditions** *(new in 2025 — 24 CWEs)* | A `catch` that swallows an authorization or verification failure and continues. A permission check whose error path returns `true`, `null`-as-allowed, or falls through to the default branch. A timeout or dependency outage that degrades **open** instead of closed. An error message that leaks internal structure. **The rule: every security decision fails closed, and its failure is logged.** |

> **The two categories most likely to be missing from an existing checklist are A03 and A10**, because both are recent and neither looks like a "vulnerability" while you are writing it. A10 in particular is invisible to every scanner: fail-open code is *working code* until the day the dependency it calls is down.

---

## 2. Trust Boundaries — the Plan-Time Artifact

This is what `model` mode produces and what a plan carries. Three questions, answered before any step is written:

1. **Where does untrusted data enter?** Every new endpoint, form field, query parameter, route parameter, upload, webhook, import, message-queue payload, third-party API response, and anything read from client storage. **Data from your own database is untrusted if a user put it there.**
2. **Where does privilege change?** Login, role assumption, impersonation, API-key exchange, a background job running as a service account, anything that widens what the current actor may do.
3. **Where does data leave?** Responses, logs, exports, emails, webhooks, error messages, analytics events, and anything rendered into a page.

Then, for each boundary crossed, name the control and where it lives:

| Boundary | Untrusted input | Control | Enforced at |
|---|---|---|---|
| `<e.g. POST /settings/avatar>` | `<file bytes, filename, content-type>` | `<type + size limit; filename never used as a path>` | `<the handler, before storage>` |

**A feature that crosses no boundary states that it crosses none.** That is a valid and common answer, and writing it down is what makes the omission deliberate rather than forgotten.

**Validate at the boundary, encode at the sink.** These are different controls and neither substitutes for the other: validation decides whether to accept the data at all, encoding decides how it is rendered safely *at the place it is used*. A value validated on entry and concatenated into a query at the sink is still an injection.

**Deny by default.** New route gated unless public is a deliberate decision. New field not returned unless it is meant to be. New permission not granted unless it is needed.

---

## 3. Secure Construction — the Write-Time Half

What `harden` mode supplies while the code is being written. Grouped by sink, because that is how you meet them.

**Building a query or command**
Parameterize or use the project's query builder — never string concatenation, never a template literal with a user value, and not for identifiers or `ORDER BY` either (allow-list those against a fixed set of column names). Shell commands take an argument array, never a composed string. If the project has a data-access layer, the fix is to go through it, not around it (Guidelines §7, reuse before create).

**Rendering into a document**
Let the framework's binding escape it. The raw-HTML escape hatch requires sanitization by the project's existing sanitizer *and* an inline comment naming why it is unavoidable. Never build markup by concatenation. A URL from user input is validated against an allowed scheme set before it becomes an `href` or a redirect target.

**Making an authorization decision**
Enforce at the data access, not only in the UI — a hidden button is not a control. The check answers *may this actor perform this action on this specific object*, so it takes the actor and the object, never just the action. Prefer one shared guard the whole codebase routes through over per-handler checks that drift. **The error path denies.**

**Accepting a file**
Limit size before reading, and count before iterating. Validate type by content where the project can, not by extension or client-supplied content-type. **Never use a client-supplied filename as a path component** — generate the stored name. Serve user uploads from a path or origin that cannot execute them.

**Handling secrets**
Read from the project's configured source (profile §Security). Never a literal, never a default fallback value that is a real key, never in a client bundle, never in a log line, never in an error message. New config value → check every declaration site per `implementing-architect` Protocol C.

**Writing the error path**
Fail closed and log the decision. The user sees a generic message; the log gets the detail. Never let a `catch` around a verification, permission, or signature check continue as if it had passed — this is A10, and it is the one a passing test suite will never show you.

**Adding a dependency**
Check the name against the real package character by character. Check that it is maintained and that its last publish is plausible. Pin it. Read the lockfile diff for transitive additions you did not ask for. This is A03, and "it was in the tutorial" is not provenance.

---

## 4. Triage

When an advisory, scanner finding, or report arrives:

1. **Establish reachability.** Does the project call the vulnerable function, on a path an attacker-controlled input can reach? Trace it or say you could not. `<audit>` from the profile lists advisories; it does not establish reachability, and treating its output as a work queue is how teams spend a week on unreachable transitive findings.
2. **Establish blast radius.** What does exploitation get — data of one user, data of all users, code execution, denial of service? Severity is a function of this and reachability together, not of the headline score.
3. **Pick one outcome and say which:** fix now (reachable, meaningful radius) · fix in the next maintenance batch (`maintenance-architect` owns the upgrade and the batching rule) · **accept with a revisit condition**, written into the profile's §Security accepted-risks row with who accepted it and what would change the answer.
4. **Never inflate and never dismiss.** "Critical but unreachable, here is the path that does not exist" is a complete and useful answer. So is "Medium, but reachable from an unauthenticated endpoint — this one first."

For a report from outside the team, treat details as confidential until the fix ships, and do not publish a reproduction. Disclosure timing is the user's decision (Constraint 6).

---

## 5. Evidence Base *(dated — re-verify before citing, Constraints 1)*

Gathered August 2026.

| Fact | Source | Note |
|---|---|---|
| OWASP Top 10:2025 — announced November 2025 at OWASP Global AppSec, Washington D.C.; final release January 2026. | [owasp.org/Top10/2025](https://owasp.org/Top10/2025/) | The version §1 is built on. Confirm the project's tracked version in the profile before assuming it. |
| A03 Software Supply Chain Failures is new for 2025, broadened from 2021's dependency-only category. A10 Mishandling of Exceptional Conditions is new, covering ~24 CWEs on improper error handling and fail-open logic. | Same | The two rows most likely absent from a pre-2025 checklist. |
| A02 Security Misconfiguration rose to #2; A07 renamed from "Identification and Authentication Failures"; A09 renamed from "Security Logging and Monitoring Failures". | Same | Renames matter when citing — use the current name or none. |
| Adjacent OWASP lists exist and are **not** covered by this skill: API Security Top 10, Top 10 for LLM Applications (2025 v2.0, with a later revision), and an Agentic Applications list. | OWASP project pages | See §6. Naming them as uncovered is the honest position; half-covering them is not. |

Category *definitions* and remediation guidance should be checked against the current OWASP text rather than quoted from memory. This table is the provenance of §1's structure, not a substitute for the source.

---

## 6. What This Skill Does Not Cover

Named rather than faked (Guidelines §15):

- **OWASP API Security Top 10** — BOLA, broken function-level authorization, and mass assignment overlap A01/A08 above, but the API-specific list is not reproduced here. Say so and work from first principles if the project is API-first.
- **OWASP Top 10 for LLM Applications / Agentic Applications** — prompt injection, insecure output handling, excessive agency. Real, versioned separately, moving fast. If the project ships AI features, resolve the current list from OWASP directly rather than from this file.
- **Infrastructure, network, and cloud posture** — firewalls, VPC design, IAM policy, container escape, host hardening.
- **Compliance regimes** — SOC 2, PCI DSS, HIPAA, GDPR. Overlapping controls, different evidence requirements, and none of them are satisfied by code review. Never state or imply that a change makes a project compliant with anything.
- **Penetration testing and exploit development.**

---

## 7. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Every OWASP category and CWE number cited is one you are certain of; uncertain ones described instead (§Constraints 1).
- [ ] Every finding states reachability, or states that it could not be established (§Constraints 2).
- [ ] No fix weakens a check, widens a permission, or adds a suppression to reach green (§Constraints 3).
- [ ] Every fix ships with a regression test that fails against the unpatched code (§Constraints 4).
- [ ] No real secret written anywhere, example code included (§Constraints 5).
- [ ] `model` mode: all three §2 questions answered, including an explicit "crosses no boundary" where true.
- [ ] Every security decision in the change fails **closed**, and its failure is logged (A10).
- [ ] Nothing claimed as compliance (§6).
- [ ] Verification stayed within one fix batch (Guidelines §16).

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §15 honesty carries the most weight here: a fabricated CWE ends up in a ticket. Also §9 git guards, §16 bounded passes, §18 self-critique.
- **Brainstorming Planner** — its grey-path list includes the trust-boundary question; this skill answers it properly once the idea is real.
- **Planning Architect** — cites this skill for every `[SEC]` step. §2's boundary table is the plan's `## Trust Boundaries` section.
- **Implementing Architect** — cites §3 while writing. Its **Protocol C** (external origins and configuration) is the propagation half of A02 and A03; run it, don't duplicate it.
- **Testing Architect** — owns how the regression test is built and placed; §2 of that skill is the security-regression TDD pattern this one's fixes plug into.
- **Code Review Architect** — its Phase 4 is the *verification* pass over this skill's categories, and it writes no code by charter. A finding it raises is remediated **here**.
- **Maintenance Architect** — owns dependency upgrades and batching. This skill triages (§4); that one performs the upgrade.
- **Deployment Architect** — secrets, access rules, and policy headers are per-environment and one-way in practice; changes there are deploy-gated with a stated rollback.
- **Debugging Architect** — when a security finding is a *symptom* with an unknown cause, narrow it there first. A speculative security fix is still a speculative fix.

---

_Skill Version: v1.0 — New skill. Closes the pack's largest structural gap: security lived almost entirely in `code-review-architect` Phase 4, which is worth 30 of 100 score points and **writes no code by charter** — so a flagged vulnerability had nowhere to be fixed, and nothing at all owned thinking about the sink before it was written. Positioned as an auto-loadable knowledge skill (like `design-architect` and `testing-architect`) rather than a pipeline stage, because "the code is created with these rules in mind" requires it to load when the work is security-shaped, not when someone remembers to run an audit. §1 is anchored to OWASP Top 10:2025 and mapped to sink shapes rather than definitions, which surfaced two categories the existing Phase 4 checklist had no row for — A03 supply chain and A10 fail-open error handling, the latter invisible to every scanner because fail-open code passes its tests. Constraint 1 is the load-bearing one: this is a domain where a fabricated identifier gets quoted to a human who trusts it, so a described weakness with no number is correct and a confident wrong CWE is a defect._
