---
name: module-threat-model
description: "Module — loaded by name from an m-skills architect, not an entry point. The OWASP Top 10:2025 categories mapped to the sink shapes they take in code, trust-boundary mapping, secure construction by sink, the review-time sweep, and reachability-first triage."
user-invocable: false
---

# Module: The Threat Model, by Sink

**Loaded by:** `security-architect` · `code-review-architect` · `testing-architect` · `planning-architect` · `implementing-architect` · `brainstorming-planner`. Read the section your run needs; do not restate its content in a skill file.

**The failure this exists to prevent:** security arriving as a review comment. By then the shape is already wrong — the ownership check has no natural place to live because the data access was designed without one, and the fix is a refactor nobody scheduled. Every category below is cheapest at plan time, affordable at write time, and expensive at review time.

---

## 2. Read One Section, Not the File

§1 above is the shared vocabulary and is short on purpose. Everything else is a reference file — read the one this run needs.

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/trust-boundaries.md` | **Plan time.** Where untrusted data enters, where privilege changes, where data leaves, and the control at each crossing. Produces a plan's Trust Boundaries table. |
| `${CLAUDE_SKILL_DIR}/references/secure-construction.md` | **Write time.** The correct shape by sink — query, document, authorization, file, secret, error path, dependency. |
| `${CLAUDE_SKILL_DIR}/references/review-sweep.md` | **Review time.** The yes/no/n-a sweep over a diff, grouped by OWASP anchor. |
| `${CLAUDE_SKILL_DIR}/references/triage.md` | An advisory or scanner finding arrived. Reachability, blast radius, one outcome. |
| `${CLAUDE_SKILL_DIR}/references/regression-targets.md` | Writing the test that closes a finding. What the attack is; `testing-architect` owns how the test is built. |

## 1. The Categories, as They Appear in Code

**OWASP Top 10:2025** is the spine — resolve the tracked standard from the profile's §Security if the project pins a different one. Each row maps the category to the *sink shape* you can actually grep for, because a definition you cannot recognize in a diff is not a working control.

| # | Category | What it looks like in the code |
|---|---|---|
| **A01** | Broken Access Control | An id from a route, query, or body used to select or mutate a record with no ownership check (IDOR). A route added without the guard its siblings carry. Authorization enforced in the UI but not at the data access. A user-controlled string building a file path or storage key without normalizing `..` (path traversal). |
| **A02** | Security Misconfiguration | Debug or verbose errors reaching a user. Default credentials or permissive defaults left in place. Over-broad CORS. A missing or unenforced security-policy header. Permissions granted at the framework's default rather than deliberately. |
| **A03** | **Software Supply Chain Failures** *(new in 2025 — broader than "vulnerable dependencies")* | An unpinned dependency, action, or base image. A build step fetching a script over the network and executing it. A lockfile change nobody read. A package whose name is one character from the real one. CI credentials with more scope than the job needs. Publishing from an unverified pipeline. |
| **A04** | Injection | User-controlled string interpolated into a query, template, shell command, or URL rather than parameterized. Raw HTML/markup binding without sanitization, or a "trust this value" escape hatch with no inline justification. Dynamic code execution — `eval`, string-argument timers, a dynamic import of a user-controlled path. |
| **A05** | Cryptographic Failures | Sensitive data in transit or at rest without protection. Home-rolled crypto. A fast general-purpose hash used for passwords. A predictable token or ID where unpredictability is the control. Secrets in client-reachable code. |
| **A06** | Vulnerable & Outdated Components | Advisories against dependencies the change actually touches. Triage per `references/triage.md`; the upgrade itself belongs to `maintenance-architect`. |
| **A07** | Authentication Failures | Credential stuffing with no rate limit or lockout. Session identifier not rotated on privilege change. Tokens that never expire or cannot be revoked. Password reset that leaks account existence. Weak or missing second factor where the profile says one is required. |
| **A08** | Data Integrity Failures | Parsed untrusted input merged, spread, or assigned into an existing object without key filtering — a prototype-pollution sink. Deserializing untrusted data into live objects. Imported data trusted for *shape* without passing the validator before it reaches storage. An update from an unverified source. **Structured cloning does not sanitize** — it preserves attacker-controlled keys. |
| **A09** | Security Logging & Alerting Failures | An authentication or authorization failure that produces no record. Nothing that would alert on a burst of them. The inverse defect: tokens, PII, or request bodies written *into* logs. |
| **A10** | **Mishandling of Exceptional Conditions** *(new in 2025 — 24 CWEs)* | A `catch` that swallows an authorization or verification failure and continues. A permission check whose error path returns `true`, `null`-as-allowed, or falls through to the default branch. A timeout or dependency outage that degrades **open** instead of closed. An error message that leaks internal structure. **The rule: every security decision fails closed, and its failure is logged.** |

> **The two categories most likely to be missing from an existing checklist are A03 and A10**, because both are recent and neither looks like a "vulnerability" while you are writing it. A10 in particular is invisible to every scanner: fail-open code is *working code* until the day the dependency it calls is down.

**Never invent a category or a CWE number.** Cite one only when certain; otherwise describe the weakness precisely and omit the identifier — the loading skill's constraints bind here.

---

