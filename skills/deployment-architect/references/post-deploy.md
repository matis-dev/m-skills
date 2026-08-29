# Reference: Post-Deploy Verification

*`deployment-architect` reference — read when the run needs it.*

## Phase 6 — Post-Deploy Verification

Runs **after the user reports the deploy landed**, and uses only the reversible checks Constraint 3 already permits — health endpoints, reading logs, exercising a path in a browser or with `curl`. Against the **real environment**, never against local state or a green CI run.

1. **Health check** — the endpoint or signal from the profile.
2. **The critical path** — actually exercise the thing that matters (log in, load the main screen, submit the core form). One real path beats ten green checks.
3. **The change itself** — verify what this release shipped, in the environment it shipped to.
4. **Errors and logs** — a brief watch window. New error classes, a rate change, failed requests to a newly added origin.
5. **The blind-spot sweep** — the things that specifically break only in a deployed environment:

| Symptom | Usual cause |
|---|---|
| Blank screen, works locally | Blocked external origin (policy not updated everywhere) or wrong base path |
| Old version still served | CDN cache, service worker, or a client holding a cached entry document |
| Works for new users, breaks for existing | Missing backfill, or code assuming the post-migration shape |
| Fails only under load or after idle | Cold start, connection-pool exhaustion, memory ceiling |
| Intermittent 4xx/5xx to one host | CORS, egress rule, or an unprovisioned credential |

State the verdict plainly: **verified**, **rolled back**, or **watching** with what you're watching and for how long. If verification fails, the decision is rollback (Constraint 8) — production is not a debugging environment.

---
