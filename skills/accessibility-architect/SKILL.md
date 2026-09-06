---
name: accessibility-architect
description: Load before building a modal, menu, combobox, tab set, drag interaction, async status, or route change, when an accessibility scan needs interpreting, or when a conformance read is asked for. Produces the accessible contract — name, role, keyboard map, focus on open and on close, announcement — and a banded verdict. WCAG 2.2 AA by default.
argument-hint: "[screen, component, axe log, or barrier] [+ mode: spec | build | remediate | audit]"
---

# Skill: Accessibility Architect — Operability, Semantics, Focus

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Design floor:** every surface here is a designed surface. The `design-architect` skill's craft floor (contrast, focus-visible, states, reduced motion) is the shared ground — it owns *how this looks and feels*; this skill owns *whether it can be operated at all*. Where the two collide, Constraint 5.
> **Test floor:** coverage for anything this skill specifies is authored per `testing-architect` (`references/a11y-tests.md`) — the automated rule scan **and** the keyboard traversal, in every theme the project ships.
> **Profile section owned:** §Accessibility (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the engine and rule tags are in the a11y test setup and the `<a11y>` gate command, the themes are in the token files, existing exemptions are in the scan config. Then fill it per **Guidelines §5.1–§5.4**.

**The two failures this exists to prevent:**

1. **Accessibility as a violation list.** A scan runs late, produces 40 findings, someone adds `aria-label` to everything until the count reaches zero, and the modal still traps a keyboard user. Automated rules catch a *minority* of real barriers and can catch none of the architectural ones — focus that goes nowhere, a route change nobody hears, an error announced to no one — because there is no violating node to find. Zero violations is a fact about the scan, not about the interface.

2. **ARIA used as the first tool instead of the last.** `role`, `aria-*`, and `tabindex` change what assistive technology is *told*, and change nothing about what the element *does*. A `<div role="button">` announces as a button and then ignores Enter, ignores Space, cannot be focused, and cannot be disabled. The lie is worse than the original silence: **no ARIA is better than bad ARIA.**

---

## Operational Constraints

1. **Never cite a success criterion by number you have not verified** — `module-evidence` §1, in a domain where a wrong SC number ends up in a VPAT, a procurement answer, or a legal response. Uncertain → **describe the barrier and who it blocks, and omit the number.** A described barrier with no ID is honest work.
2. **Fix the component, never the test.** No widening a scan exclusion, no adding a rule to the ignore list, no relaxing a threshold to reach green. Exclusions exist only for genuinely third-party, unfixable widgets, each justified with an inline comment naming the reason — the rule already stated in `testing-architect`'s a11y-test reference; this skill enforces it rather than restating it.
3. **A green automated scan is not a conformance claim, and never claim a level you have not tested at.** "Passes axe with `wcag22aa` tags, keyboard walk clean on these three flows, not screen-reader tested" is a true and useful statement. "WCAG 2.2 AA compliant" is a claim about 87 criteria, most of which no tool evaluates. Never write the second when you did the first.
4. **Barriers are stated with who they block.** "Target is 18px" is a measurement; "the delete control is 18px, so anyone with a tremor or using a phone one-handed will miss it and hit the adjacent row" is a finding. The second gets fixed. This is not decoration — it is what stops a rule from being lawyered.
5. **The brief wins on aesthetics; the floor wins on access — and where they truly collide, propose a third option.** A design that cannot be operated has not made a trade-off, it has excluded people. But "make it uglier" is almost never the only fix available: a focus ring can be designed, a target can grow its hit area without growing its visual box, a drag can keep its drag *and* gain a click alternative. Bring the third option, not an ultimatum.
6. **Bounded verification** (Guidelines §16). Scan, keyboard-walk, and inspect in one batched round across every theme → one fix batch → at most one confirm round → stop.

---

## Modes

| Mode | Fires at | Produces |
|---|---|---|
| **`spec`** | **Planning** — the point of this skill | The accessible contract *before the component exists*: name, role, value, focus order, keyboard map, and what gets announced. The per-step `[A11Y]` note `planning-architect` carries. Read-only. |
| **`build`** | **Implementation** | The correct construction from `module-operability-floor` — native element first, ARIA only where native cannot express it. |
| **`remediate`** | An axe log, a Lighthouse report, or a reported barrier | The fix in the component, plus the coverage that catches its return (`testing-architect`). |
| **`audit`** | An existing surface | `references/reading-a-scan.md`: an evidence-backed read against the profile's target level, with a banded verdict and an explicit statement of what was **not** tested. Never an invented score. |

Default when unspecified: a feature description → `spec`. A component being written → `build`. A log or a barrier report → `remediate`. A screen with no stated question → `audit`.

---

## 1. Conformance Target

**WCAG 2.2 Level AA** is the default. Resolve the actual target from the profile's §Accessibility — a project may pin 2.1 AA (still the common legal reference in several jurisdictions), or hold specific AAA criteria, or track A only.

WCAG 2.2 reached W3C Recommendation on **2023-10-05**. It adds nine success criteria to 2.1 and **removes** 4.1.1 Parsing (obsolete — browsers recover from malformed markup, and the criterion no longer identified real barriers).

**The nine are the ones no pre-2.2 habit covers** — everything a team already does for 2.1 leaves them open. They are in `${CLAUDE_SKILL_DIR}/references/wcag22.md` with the failure each one actually produces, and with the levels attached, because an AAA criterion is not a compliance failure at AA.

The shared floor from 2.0/2.1 still carries most of the weight and is not restated here — text alternatives, keyboard operability, contrast, labels and instructions, error identification, name/role/value, reflow, orientation. Where those overlap visual craft they live in `module-craft-floor`; where they are about operation they live in `module-operability-floor`.

## 2. The Operability Floor

Native-element-first construction, the full contract an ARIA role obliges you to supply, focus management (order, overlays, disclosure, single-page routing), live regions for async status, and the refuse list all live in the **`module-operability-floor`** skill. Load it — it is the substance of `spec`, `build`, and `remediate` modes.

**Its focus-management section is why this skill exists separately from `design-architect`.** A focus trap with no exit, focus never returned to the trigger, a route change nobody hears: each produces **zero automated violations**, because there is no violating node to find. They are unreachable from a fix-the-log workflow and have to be decided at plan time — which is what `spec` mode is for.

What stays in this file is what this skill decides rather than looks up: the conformance target below, who each barrier blocks, how to read a scan honestly, and the constraints above.

---

## 3. What to Read, and When

| Read | When |
|---|---|
| `module-operability-floor` | `spec`, `build`, `remediate` — the substance of all three. |
| `${CLAUDE_SKILL_DIR}/references/wcag22.md` | Checking against 2.2 specifically. The nine criteria no pre-2.2 habit covers, with the failure each one actually produces. |
| `${CLAUDE_SKILL_DIR}/references/who-it-blocks.md` | Writing up a barrier. Constraint 4 requires naming who it blocks; this is the table. |
| `${CLAUDE_SKILL_DIR}/references/reading-a-scan.md` | `audit`, or anyone says "axe is clean". |
| `${CLAUDE_SKILL_DIR}/references/evidence-base.md` | Before citing a criterion number or a version fact. Dated. |
| `module-findings` | Shaping the findings and the banded verdict. |

---

## 4. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Every SC number cited is one you are certain of; uncertain ones described instead (§Constraints 1).
- [ ] Native element used wherever one exists; every ARIA role carries its full contract (`module-operability-floor` §1).
- [ ] Everything interactive is keyboard-reachable, with a visible focus indicator that is not obscured (`module-operability-floor` §2).
- [ ] Every overlay: focus in, trapped, Escape closes, **focus returned to the trigger** (`module-operability-floor` §2).
- [ ] Route changes and async status are announced or focused — one, not both, not neither (`module-operability-floor` §2–§3).
- [ ] Live regions exist in the DOM before their content does (`module-operability-floor` §3).
- [ ] Targets meet 24×24 or the spacing exception; anything draggable has a single-pointer alternative (§1).
- [ ] Checked in **every theme** the project ships (`references/reading-a-scan.md`).
- [ ] Every barrier reported names who it blocks (§Constraints 4).
- [ ] No claim made beyond what was actually tested, and what was not tested is stated (§Constraints 3).
- [ ] Verification stayed within two rounds (Guidelines §16).

---

_v1.0 — version history in CHANGELOG.md_
