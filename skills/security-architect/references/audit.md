# Reference: The Project Audit

*`security-architect` reference — read in `audit` mode.*

## The Project Audit

The code as it stands at `HEAD`, not a diff. **Read-only:** each finding is handed to `remediate`, each dependency upgrade to `maintenance-architect`. One pass, in this order.

1. **Scope.** Whatever was handed over — one or more paths, or a part named in words ("the auth module", "the upload flow"), resolved to its files by reading the code and listed before anything is swept. Uncommitted changes → the hunks in `git diff HEAD` plus untracked files, swept as a diff in step 4. Nothing handed over → the whole repository. On a narrowed scope, entry points **outside** it that reach into it still go on the map: reachability does not stop at the scope's edge, so a sink is never called unreachable because its caller lives in another directory. State the commit (`git rev-parse --short HEAD`) and what was excluded — vendored, generated, and build output. Read the profile's §Security first: the auth model, the authorization seam, the secret contract, the accepted risks. An accepted risk inside its revisit condition is not a finding; one past it is.
2. **Map the boundaries.** Answer the three questions in `module-threat-model` → `references/trust-boundaries.md` for the codebase, not a feature: every entry point (routes, handlers, CLI arguments, webhooks, queue consumers, uploads and imports, reads from client storage), every privilege change, every exit. The map is the first section of the report. An entry point with no control at its crossing is already a finding.
3. **Find the sinks.** Grep for each sink shape in the module's §1, A01–A10. Search the project's own wrappers first (its query builder, template helper, shell runner, fetch client), then the generic forms. Record the patterns used: they are the "what was searched" that every absence claim rests on.
4. **Sweep each sink.** Run `module-threat-model` → `references/review-sweep.md` over the sinks found instead of over a diff. Trace each one back to an entry point on the map. That trace is its reachability: report a sink that no entry point reaches as unreachable, never at its headline severity. A10 gets a deliberate read of the error paths around every auth and verification check, because no grep finds fail-open code.
5. **Secrets.** Grep tracked files for secret patterns (the sweep's Configuration row). Never read a secret file, and never echo a matched value. Report the hit as `path:line` with rotation required (Constraint 5). Searching history (`git log -p -S`) is offered to the user, not run unasked.
6. **Dependencies and supply chain.** Run the profile's audit command once. Triage each advisory per `module-threat-model` → `references/triage.md` and list it; the upgrade goes to `/m-skills:advisories`. Then the A03 rows the scanner misses: unpinned CI actions and base images, install steps that execute fetched scripts, and workflow permissions wider than the job needs.
7. **Report** per `module-findings`. In an audit, the confidence gate's "introduced by this change set" reads "present at `HEAD`", and `[OUT-OF-DIFF]` does not apply. Shape:
   - **Verdict line**, with the evidence that set it: 🔴 **Exposed** (a reachable Critical or High) · 🟠 **At risk** (reachable Mediums) · 🟡 **Hardening gaps** (Low and defense-in-depth only) · 🟢 **Nothing found in what was covered**. Never "secure", and never a score.
   - **The next action:** the top finding, as the exact `/m-skills:security-architect <finding> — remediate` line.
   - **The boundary map** from step 2.
   - **Findings grouped by OWASP anchor**, each one naming its owner. Categories with no findings are noted clean.
   - **Worth a second look (unverified)**, kept apart from the findings.
   - **Not covered:** the areas skipped, the search patterns' blind spots (dynamic dispatch, runtime config, anything outside the repo), and the domains in `references/not-covered.md`.

**Bounded** (Guidelines §16). On a repository too large for one pass, audit the entry points and the sinks they reach, and list the rest under *Not covered*. Never sample silently.

---
