# Reference: Mode: decompose

*`product-architect` reference — read when the run needs it.*

## Mode: `decompose` — Cut a Plan Into Shippable Slices

The primary mode. Input: an approved plan, an epic, or a feature too big for one sitting. Output: an ordered set of slices, each one an independent handoff to `implementing-architect`.

### 1. Find the seams

Read the plan and identify where value can be cut without leaving something half-built. Take the **first heuristic that produces slices which each stand alone** — this is the Laziness Ladder (Guidelines §2) applied to slicing:

| Cut along | Use when | Example shape |
|---|---|---|
| **Workflow steps** | the feature is a sequence | ship "create draft" before "publish", before "schedule" |
| **Happy path vs. grey paths** | the unhappy states are most of the work | ship the success case; offline, retry, and conflict follow as their own slices |
| **Business-rule variations** | one rule has many cases | ship the default rule; the exceptions each become a slice |
| **Data variation** | the shape varies by type or source | ship one type end to end, then widen |
| **Interface / surface** | it must work in several places | ship one platform or one viewport, then the next |
| **Operations** | it is CRUD-shaped | read before write before delete; delete is often its own slice because it is where the danger is |
| **Deferred scale** | it must eventually be fast or large | ship the correct naive version with its ceiling named (Guidelines §2), optimize as a later slice |

**Never cut by layer, by role, or by activity.** "Database slice / API slice / UI slice", "backend dev's part / frontend dev's part", and "build slice / test slice" all produce work that cannot ship on its own.

### 2. Apply the slice ceiling

**If a slice cannot be implemented, reviewed, and shipped in one session, cut it again.** Resolve the project's actual ceiling from §Product Definition — if it is unrecorded, read the merged PRs and use what this team actually ships. Two more cuts is normal. A slice you cannot cut further and still cannot finish is a signal the plan is wrong; say that instead of shipping an impossible ticket.

Then check each slice against **INVEST**, and name the letter when one fails:

- **I**ndependent — shippable without waiting on a sibling. Sequential is fine; entangled is not.
- **N**egotiable — states the outcome, not the implementation. The plan holds the *how*.
- **V**aluable — someone can see the difference. **A slice whose only value is "the next slice becomes possible" is not a slice** — fold it into the one that needs it.
- **E**stimable — if nobody can size it, it needs a spike first, and the spike is its own timeboxed slice with a written question.
- **S**mall — under the ceiling.
- **T**estable — the acceptance criteria are falsifiable.

### 3. Write each slice

```
### Slice N: <outcome, in the user's words>
- **Value:** who can now do what
- **Priority:** <project's vocabulary — P0/P1/P2, MoSCoW, whatever §Product Definition says>
- **Depends on:** <slice number, or nothing>
- **Acceptance criteria:** Given / When / Then — or the project's format if it has one
- **Out of scope:** what a reviewer might expect here and will not find
- **Notes for implementation:** the reuse paths and constraints carried down from the plan
```

Then order them: **walking skeleton first** (thinnest end-to-end path — it proves the seams are real), **then highest risk** (the slice most likely to invalidate the plan, while changing course is still cheap), **then by value**.

### 4. Slice anti-patterns — refuse these

- **A "setup" or "scaffolding" slice** with no observable outcome. Fold it into the first slice that needs it.
- **A "write the tests" slice.** Tests ship with the code they verify (Guidelines §11). A test-only slice means the previous slice was not done.
- **A "QA" or "polish" slice** used to defer finishing. Name the specific gap and put it in the slice that owns it.
- **"Refactor first, then the feature"** as two slices in one plan — that is bundling, and it destroys attribution when something breaks (`maintenance-architect` constraint 1). Either the refactor stands alone with its own justification, or it happens inside the slice that needs it.
- **A slice with acceptance criteria that restate the title.** If the AC is not falsifiable, it is decoration.
- **More than about seven slices for one feature.** Group them into two rounds and lead with the first — more than seven is a roadmap, not a decomposition (Guidelines §17.4).

**Handoff:** each slice is pasted into a fresh `implementing-architect` run, carrying its AC and its notes. State this in one line at the end, and name which slice to start with.

---
