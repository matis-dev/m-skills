# Reference: Modes of Invocation

*`design-architect` reference — read first, to name what this run is.*

| Ask | What this skill does |
|---|---|
| **Design / build** a surface | §1 mode → §2 brief → build → §3 floor on the built result → §5 sweep. |
| **Audit** existing UI | Read-only. Read the existing brief or stamp first — a missing one is the first finding. Then run §3 and `references/refuse-list.md` over the target; report findings with `path:line`, severity, and the concrete fix. Write nothing. |
| **Redesign** | Constraint 3 applies: keep product truth, content, and function; the old stamp is the anti-reference. Write a new §2 brief that differs on `structure:` and on at least one of `palette:` / `type:`, build to it, and update the project's design doc and profile §Design to match. |
| **Study** a reference the user admires | Fill every field of the §2 brief from the reference — structure and type from what it *does*, not what it says about itself — and set `source:` to the URL or file. Once extracted, that brief **is** the system for this project; don't drift back to a generic default later in the session. |
| **Polish** | `module-craft-floor` only, against the existing brief or stamp. No new direction, no scope growth. |
| **Establish** *(greenfield)* | No UI exists yet, or what exists is placeholder scaffolding. Don't match it — run §2 fully, emit the brief, ask one question ("keep, or adjust?"), then write the block into the profile's §Design. From then on it is the committed world and constraint 2 applies to it like any other. |
