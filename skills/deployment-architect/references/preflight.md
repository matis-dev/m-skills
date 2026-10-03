# Reference: Pre-Flight Risk Pass

*`deployment-architect` reference — read when the run needs it.*

## Phase 3 — Pre-Flight Risk Pass

The failure classes CI cannot see. Each is yes/no/n-a; any yes is a finding with severity.

**Configuration & secrets**
- Env vars the new code reads — **present in the target environment**? A var that exists locally and in CI but not in prod is the single most common deploy failure. Enumerate the ones this change added.
- Any secret, token, or key inside the built artifact? Client bundles ship everything they contain — check what got inlined.
- Config defaults that silently differ per environment (log level, debug flags, feature toggles, API base URL, sample rates)?
- New third-party service — credentials provisioned in the target, quota/rate limits understood?

**Data & migrations**
- Does this release change persistent state? If yes: is the migration **reversible**, and is it **forward-compatible** with the currently-running code?
- **Ordering:** does the new code require the migration, or does the migration require the new code? A migration that breaks the running version causes downtime during a rolling deploy. Prefer expand → deploy → contract: add the new shape, ship code using it, remove the old shape in a later release.
- Long-running migration against a live table — lock duration understood, batched if needed?
- Backfill needed for existing rows, and is the code correct for rows that predate it?
- **Is there a backup or a restore point taken before this runs?**

**Caching & assets**
- Are static assets content-hashed, so clients don't get a stale bundle against a new API?
- CDN cache invalidation needed, and is it part of the deploy or a separate step?
- A service worker or app cache that will serve the previous version until it updates? **This makes a rollback appear not to work** and is a classic false alarm.
- HTML/entry document cached longer than it should be?

**External origins & policy**
- New external origin — declared in **every** place the policy exists (markup meta, server header, dev and prod config)? A blocked origin renders consistently broken, so tests and visual baselines pass (`module-propagation`, Protocol C).
- CORS allowances updated on the API side for a new frontend origin?
- New outbound host allowed by any egress restriction?

**Runtime & compatibility**
- Runtime version in the target matches what was built against (node/python/JVM/etc.)?
- Native or platform-specific dependencies built for the target architecture?
- Cold-start or memory characteristics changed meaningfully?
- Health check still passes with the new startup sequence — including the case where a dependency is briefly unavailable?

**Blast radius**
- Can this ship behind a flag or to a subset first? If a safe partial rollout is available and not being used, say why.
- What breaks for a user mid-session when this lands — an in-flight form, an open websocket, a cached page?
- Is the deploy window sensible (traffic, on-call, time of day, day of week)?

---
