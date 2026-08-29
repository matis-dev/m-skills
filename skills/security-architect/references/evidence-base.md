# Reference: Evidence Base

*`security-architect` reference — read when the run needs it.*

## 2. Evidence Base *(dated — re-verify before citing, Constraints 1)*

Gathered August 2026.

| Fact | Source | Note |
|---|---|---|
| OWASP Top 10:2025 — announced November 2025 at OWASP Global AppSec, Washington D.C.; final release January 2026. | [owasp.org/Top10/2025](https://owasp.org/Top10/2025/) | The version `module-threat-model` §1 is built on. Confirm the project's tracked version in the profile before assuming it. |
| A03 Software Supply Chain Failures is new for 2025, broadened from 2021's dependency-only category. A10 Mishandling of Exceptional Conditions is new, covering ~24 CWEs on improper error handling and fail-open logic. | Same | The two rows most likely absent from a pre-2025 checklist. |
| A02 Security Misconfiguration rose to #2; A07 renamed from "Identification and Authentication Failures"; A09 renamed from "Security Logging and Monitoring Failures". | Same | Renames matter when citing — use the current name or none. |
| Adjacent OWASP lists exist and are **not** covered by this skill: API Security Top 10, Top 10 for LLM Applications (2025 v2.0, with a later revision), and an Agentic Applications list. | OWASP project pages | See `not-covered.md`. Naming them as uncovered is the honest position; half-covering them is not. |

Category *definitions* and remediation guidance should be checked against the current OWASP text rather than quoted from memory. This table is the provenance of the module's §1 structure, not a substitute for the source.

---
