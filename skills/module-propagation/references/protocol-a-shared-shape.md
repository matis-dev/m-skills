# Reference: Protocol A — Shared Data Shape

*`module-propagation` reference — read when the run needs it.*

## Protocol A — Shared Data Shape

**Known gate blind spots:**
- **Type-checking usually doesn't cover markup/template bindings.** A stale binding compiles clean and fails only at build/AOT or runtime. The **build gate** is the one that catches template drift — a green type-check is necessary and never sufficient.
- **Compiler-silenced fixtures** (`as any`, `as unknown as T`, `# type: ignore`) keep old shapes passing green. Green tests do not prove fixtures match the schema.

**The sweep** — grep the OLD identifier and OLD value project-wide, then confirm each category:

1. **Type / model definition** — the declaration itself.
2. **Every construction site** — factories, builders, form groups, default objects. There is almost always **more than one** (a primary plus a variant, array-item, or parallel builder).
3. **Both mapping directions** — serialize *and* hydrate, encode *and* decode, to-DTO *and* from-DTO.
4. **Validation stated twice** — the declarative validators **and** any hand-written validation service. The same bound is routinely hardcoded in two places.
5. **Sanitizers / normalizers / migrations.**
6. **Boundaries** — export and import paths, API payloads, storage schemas, query params.
7. **Templates / views** — bindings referencing the name. *(Build-gate-only failures.)*
8. **Parallel subsystems** — the secondary UI mirroring the primary one, a flat-field interface, an admin form. **The easiest miss.**
9. **User-facing strings** — a removed field **orphans its label/placeholder keys**; remove them from **all** locales. Grep each key across source before deleting to confirm zero references. Strings that bake a bound into prose ("must be between X and Y") go stale while their key stays used.
10. **Fixtures and test doubles** — old-shape mocks pass green; update them anyway.
11. **Comments and doc-comments** quoting the old bound or behavior.

**Numeric bounds and enum values — do NOT rely on grep.** A renamed identifier greps cleanly; a moved bound does not (a bare number drowns in false positives), so "grep found nothing" is not proof. Walk a **semantic site list** instead, because the value gets *re-expressed*, not just referenced — wherever the app **states** the constraint a second time: declarative validators in *every* factory (including any per-branch re-wiring helper), the hand-written validation check, markup `min`/`max`/`maxlength` attributes and client-side clamps, parallel/secondary field configs, user-facing strings baking the value into prose (update all locales), spec boundary assertions pinned to the old edge, and comments.

**Closing check:** re-grep the old identifier/value — expect zero hits outside changelog and migration docs. For bounds/enums, confirm each semantic site by name. Then run `<build>`, not just `<typecheck>`, before claiming the change is done.

---
