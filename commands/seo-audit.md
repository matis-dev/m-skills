---
description: Audit a page or site for retrievability by search and answer engines — verified against fetched bytes, not assumptions.
argument-hint: "[URL, site, or page to audit]"
---

Run `search-optimization-architect` in **Audit** mode. The mode is already chosen — do not re-open the mode question, and do not drift into `brief`, `entity`, or `measure`. This run is **read-only**.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/search-optimization-architect/SKILL.md` — its constraints and tier ordering apply in full.
2. Fetch the target **as a non-JS client** first, per `${CLAUDE_PLUGIN_ROOT}/skills/search-optimization-architect/references/technical-readiness.md` §1. Run the Tier-1 checks and **stop the report there if one fails** — everything below is unreachable until it passes.
3. Then, in order: the island test on real chunks (`references/retrieval-content.md`), the rest of `references/technical-readiness.md`, coverage gaps (`references/entity-authority.md`).
4. Load `module-findings` for the finding shape, and `module-evidence` before repeating any figure from `references/evidence-base.md`.

Every finding carries `url:element` and its tier, and every claim is verified against the bytes you actually fetched.

Target: $ARGUMENTS

If no target was given, ask which URL or site to audit.
