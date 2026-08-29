---
name: module-propagation
description: "Module — loaded by name from an m-skills architect, not an entry point. The change-propagation protocols: the mirror sites a green pipeline structurally cannot catch when a shared data shape, a public API surface, or an external origin changes."
user-invocable: false
---

# Module: Change Propagation — the Mirror Sites Gates Miss

**Loaded by:** `planning-architect` · `implementing-architect` · `code-review-architect` · `debugging-architect` · `deployment-architect` · `maintenance-architect` · `security-architect`. Read it when a run reaches a change of the shapes below; do not restate its content in a skill file.

**Why this exists:** a green pipeline is **not** proof a change fully landed. Each protocol below covers sites the automated gates structurally cannot reach. They trigger on the **shape** of the change, not on the project.

> Every concrete example here is an **illustration of a category**, not a rule. Substitute what exists in the project you are in. Categories are what survive; a catalogue of last month's field names is what rots.

---

## When each protocol fires

| Protocol | Fires when the change… |
|---|---|
| **A — Shared data shape** | renames, removes, retypes, or restructures a shared field (object↔array, string↔object); changes an enum value; moves a numeric bound |
| **B — Public API & test doubles** | adds, renames, removes, or re-signs a method on a service, module, or class's public surface |
| **C — External origins & configuration** | makes the app load a new external origin (tiles, an API host, a font, an image CDN, a third-party script), or depends on new runtime configuration |

More than one can apply to a single change. If none apply, say so in one line rather than omitting the section.

## The three moments it is used

- **At plan time** — the plan's *Files to Modify* list enumerates **every mirror site, one per line**, plus the verification line for the change's shape. Walking the categories is what turns "update the field" into a complete plan.
- **At build time** — run the sweep, then the closing check, before claiming the change is done.
- **At review time** — verify the sweep actually happened. Findings of this class are the highest-value output of a review, because they pass every gate.

---

## Read the Protocol That Fires

| Read | Protocol |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/protocol-a-shared-shape.md` | **A** — a shared field renamed, removed, retyped, restructured; an enum value changed; a numeric bound moved. |
| `${CLAUDE_SKILL_DIR}/references/protocol-b-public-api.md` | **B** — a public method added, renamed, removed, or re-signed. |
| `${CLAUDE_SKILL_DIR}/references/protocol-c-external-origins.md` | **C** — a new external origin, or a new runtime configuration value. |

The review-time audit below is short enough to stay here, because a reviewer needs all three shapes at once.

## The Review-Time Audit

When verifying that someone else's change swept correctly, these five are where it fails:

- **Stale markup/template bindings** referencing a removed name — these pass type-check and fail only at build/runtime. If the build gate was green, this is covered; if it was skipped, grep the markup for the old name.
- **Orphaned user-facing keys** left by a removed field — grep each suspect key across source; zero references → finding.
- **Compiler-silenced fixtures** still holding the pre-change shape — flag any mock that doesn't match the current schema.
- **Test doubles missing a newly added method** — the spy list, mock class, or inline stub returns nothing and the test fails misleadingly, or worse, passes.
- **Moved bounds / swapped enum values** — verify by semantic site, per Protocol A. A site left on the old value is a finding even when grep and tests are green.

---

## Verification lines, by change shape

- **Identifier renames/removals** — re-grep the old identifier across the source tree; expect zero hits outside changelog/migration docs.
- **Numeric bounds and enum values** — grep is unreliable; list the **semantic sites by name** instead.
- **Templates** — confirm via the `<build>` gate, not `<typecheck>`.

---

## Recurring sites are recorded, not rediscovered

A propagation site found the hard way goes into the Project Profile's **§Recurring Propagation Sites** (Guidelines §5), so the next change of that shape is swept for it automatically. That write-back is what stops this module from being the same lesson learned twice.
