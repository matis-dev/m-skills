# Reference: What This Skill Does Not Cover

*`security-architect` reference — read when the run needs it.*

## 3. What This Skill Does Not Cover

Named rather than faked (Guidelines §15):

- **OWASP API Security Top 10** — BOLA, broken function-level authorization, and mass assignment overlap A01/A08 above, but the API-specific list is not reproduced here. Say so and work from first principles if the project is API-first.
- **OWASP Top 10 for LLM Applications / Agentic Applications** — prompt injection, insecure output handling, excessive agency. Real, versioned separately, moving fast. If the project ships AI features, resolve the current list from OWASP directly rather than from this file.
- **Infrastructure, network, and cloud posture** — firewalls, VPC design, IAM policy, container escape, host hardening.
- **Compliance regimes** — SOC 2, PCI DSS, HIPAA, GDPR. Overlapping controls, different evidence requirements, and none of them are satisfied by code review. Never state or imply that a change makes a project compliant with anything.
- **Penetration testing and exploit development.**

---
