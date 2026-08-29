---
name: module-gate-battery
description: "Module — loaded by name from an m-skills architect, not an entry point. How the project's quality gates are run and reported: the order, the one-batch rule, the result table, the ways a green run lies, and the manual stop when a visual baseline fails."
user-invocable: false
---

# Module: Running the Gates, and Not Believing Them

**Loaded by:** `implementing-architect` · `testing-architect` · `code-review-architect` · `deployment-architect` · `maintenance-architect` · `debugging-architect`. Read it when a run reaches the gates; do not restate its content in a skill file.

**What this module is not:** it does not resolve the commands. Which command each role maps to comes from the Project Profile (Guidelines §5) and is injected by the plugin's preamble hook. This module holds the *procedure* — order, batching, reporting, and the specific ways a green run can be wrong.

---

## 1. The Order, and the One-Batch Rule

Run the gates in the profile's order. Where the profile states none, this is the order, cheapest signal first:

`<lint>` → `<typecheck>` → `<test>` (capture coverage) → `<build>` → `<e2e>` → `<visual>` → `<a11y>` → `<audit>`

**Run them as one batch and record every result. Do not abort at the first failure** unless that failure genuinely blocks the gates after it (a broken build makes `<e2e>` meaningless; a lint error does not). Stopping at the first red line turns one round of fixes into four, which is the open loop Guidelines §16 forbids.

- A role with no command in the profile is **`n-a`** — say so and move on. Never invent a script name to fill a row (Guidelines §15).
- A gate that fails is **reported with its output**, never skipped and never summarised into optimism.
- One batch → one fix batch → at most one confirming re-run → stop.

**`<build>` is not optional when shape changed.** Type-checking usually does not cover markup or template bindings; only the build does. A green `<typecheck>` is necessary and never sufficient.

---

## 2. Reporting the Result

One row per gate the project actually has. Omit rows for gates that do not exist rather than printing `n-a` noise, unless the reader needs to know a gate is absent.

| Gate | Result |
|---|---|
| `<lint>` | ✅ / ❌ <one-line summary if ❌> |
| `<typecheck>` | ✅ / ❌ |
| `<test>` | ✅ / ❌ — coverage: <n>% branches |
| `<build>` | ✅ / ❌ |
| `<e2e>` | ✅ / ⚠️ diffs awaiting manual review / ❌ |
| `<visual>` | ✅ / ⚠️ diffs awaiting manual review / ❌ |
| `<a11y>` | ✅ / ❌ <violations, themes affected> |
| `<audit>` | <advisories by severity> |

Every number in that table came from output you actually saw. Coverage percentages and advisory counts are copied, never estimated (Guidelines §15). A gate not run this session is stated as not run — a ✅ nobody observed is a fabrication, including under a "skip gates" modifier (Guidelines §19).

---

## 3. The Green-But-Lying Traps

Tests that pass while proving nothing. Check for these **by name** before trusting a green run.

- **Fake timers vs. subscriptions born outside them.** A subscription created at construction time — in a constructor, a field initializer, or an `init()` called from one — binds its scheduler **outside** any later fake-timer scope. Time-based operators on that stream (debounce, throttle, delay, audit) then **cannot be advanced by the test's clock**: the value enters the operator and never comes out. Symptom: *"expected spy to have been called, but it was never called"* while the upstream steps clearly run — that is this trap, not a wiring bug. Fixes, in order: prefer an operator that's synchronously testable and also fixes the stale-response race; or create the subscription **inside** the test rather than in setup; or drive it with the framework's virtual scheduler. Never assume "set value + advance clock" flushes it.
- **Compiler-silenced fixtures.** A mock cast to satisfy the type checker (`as any`, `as unknown as T`, `# type: ignore`) keeps the *old* shape while the schema moves on. Green tests do not prove fixtures match the current schema — grep and update them by hand.
- **Hand-maintained test doubles.** A spy object built from a list of method names silently returns nothing for any method not on the list. Adding a method to a service breaks every consumer spec that spies it — with a misleading "never called", not a type error.
- **Gates with a blind spot.** Type-checking usually does not cover template/markup bindings — only the build does. Visual snapshots do not catch a resource that is *consistently* broken (a blocked origin renders blank identically every run, so the baseline matches). Name the project's blind spots in the profile's §Guardrails and verify past them.
- **A11y scans do not prove usability.** An automated rule scan catches a fraction of real barriers, and can catch none of the architectural ones. Pair it with keyboard traversal, and never read a green scan as "accessible".
- **A test that passes whether or not the feature works.** If deleting the implementation does not fail the test, the test is decoration.

A blind spot found the hard way is written into the profile's §Guardrails → Known blind spots, phrased as what to check next time. That write-back is what makes this list grow with the project instead of staying generic.

---

## 4. When a Visual or Golden Gate Reports Diffs

**Stop. Do not run the update command.** This is Guidelines §10 and it is enforced by the plugin's `guard-mutations.sh` hook, which denies the call.

Surface the failure literally:

> "Visual diffs detected — review the report at `<report path>`; if intended, run `<update-command>` manually."

Then wait for inspection and an explicit go-ahead. Do not delete failing baselines. Do not loosen the diff tolerance to make it pass — that is fixing by weakening (`testing-architect` constraint 3).

Baselines exist to tell the user what changed visually. Auto-updating erases the exact signal the test was written to produce, which is why the update is always the last **manual** step and never part of an automated pipeline.

---

## 5. What a Green Pipeline Still Does Not Prove

Worth stating out loud whenever a run ends green, because it is where the next incident comes from:

- That the change **propagated** to its mirror sites (`module-propagation`).
- That it works **there** — with that environment's config, against pre-existing data, behind caches that outlive the deploy.
- That an interface can be **operated** by keyboard and screen reader.
- That the code is **reachable-safe** — fail-open error paths pass every test they have.
