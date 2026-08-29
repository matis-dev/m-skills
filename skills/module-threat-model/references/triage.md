# Reference: Triage — Reachability Before Severity

*`module-threat-model` reference — read when the run needs it.*

## 5. Triage — Reachability Before Severity

When an advisory, scanner finding, or report arrives:

1. **Establish reachability.** Does the project call the vulnerable function, on a path an attacker-controlled input can reach? Trace it or say you could not. `<audit>` lists advisories; it does not establish reachability, and treating its output as a work queue is how teams spend a week on unreachable transitive findings.
2. **Establish blast radius.** What does exploitation get — data of one user, data of all users, code execution, denial of service? Severity is a function of this and reachability together, not of the headline score.
3. **Pick one outcome and say which:** fix now (reachable, meaningful radius) · fix in the next maintenance batch (`maintenance-architect` owns the upgrade and the batching rule) · **accept with a revisit condition**, written into the profile's §Security accepted-risks row with who accepted it and what would change the answer.
4. **Never inflate and never dismiss.** "Critical but unreachable, here is the path that does not exist" is a complete and useful answer. So is "Medium, but reachable from an unauthenticated endpoint — this one first."

For a report from outside the team, treat details as confidential until the fix ships, and do not publish a reproduction. Disclosure timing is the user's decision.

---
