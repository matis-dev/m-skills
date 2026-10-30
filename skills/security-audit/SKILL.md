---
name: security-audit
disable-model-invocation: true
description: Audit the existing codebase for vulnerabilities — boundary map, sinks traced to entry points, findings by reachability, writing nothing.
argument-hint: "[paths or a named part, e.g. src/api or \"the upload flow\" — default: the whole repository]"
---

Run `security-architect` in **audit** mode. The mode is already chosen — do not re-open the mode question, and do not drift into `model`, `harden`, `remediate`, or `triage`. **Write nothing**: this run reports, and each finding is handed to `remediate`.

1. Read `<m-skills>/skills/security-architect/SKILL.md` — its constraints apply in full, Constraint 2 (reachability before severity) and Constraint 5 (no secret read or echoed) most of all.
2. Read `<m-skills>/skills/security-architect/references/audit.md` — the procedure. It sends you into `module-threat-model` for `references/trust-boundaries.md`, `references/review-sweep.md`, and `references/triage.md`; read those when the procedure reaches them.
3. Load `module-findings` for the finding shape and the verdict, and `guidelines-meta`.

Never claim the project is secure or compliant. State what was **not** covered.

Target: the text the user typed after the command

If no target was given, audit the whole repository — do not ask.
