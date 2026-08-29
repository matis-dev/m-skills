# Reference: Mode: prd

*`product-architect` reference — read when the run needs it.*

## Mode: `prd` — Requirements Someone Can Build From

Only when the work genuinely needs a durable spec: several people, a contract with another team, a regulated surface, or a decision that will be re-litigated. **A PRD for a two-day feature is overhead** — say so and offer `deep-dive` instead (Guidelines §2).

Sections, in this order, and none of them padded:

1. **Header** — name, status, owner, date.
2. **Problem** — the user pain, as *As a … I want … so that …*, plus what happens if nobody builds it.
3. **Success** — the north star metric, with its **current value and its source**, or an explicit `baseline unknown — instrument before measuring`. Input metrics beneath it.
4. **Audience** — primary and secondary. A persona with no research behind it is written as `assumption:`.
5. **Scope, prioritized** — `Must / Should / Could / Won't` in the project's own vocabulary. **The `Won't` section is mandatory** and is the section that saves the most time later.
6. **Functional requirements** — the happy path as numbered steps, plus a diagram where the flow is non-obvious (`module-writing-floor` governs the diagram).
7. **Non-functional requirements** — performance, security and access control, scale, accessibility, localization. **Each with a number that is either sourced or marked as a target**, never a plausible-sounding default.
8. **Grey paths** — offline, timeout, empty, loading, partial failure, permission denied, concurrent edit. Carried from `brainstorming-planner` if that ran; produced here if it didn't.
9. **Data and analytics** — new fields, schema changes, and the events that must be tracked for section 3's metrics to ever be measurable.
10. **Risks and dependencies** — third parties, legal and compliance, one-way doors.
11. **Acceptance criteria** — 3–5 Given/When/Then scenarios covering the happy path, one grey path, and one boundary.

Close by naming the next step: `decompose` this PRD, or take it to `planning-architect` for the technical plan first.

---
