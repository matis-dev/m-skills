---
name: accessibility-architect
description: Design, build, and repair interfaces so they are operable by keyboard, screen reader, magnification, and imprecise pointers — before the violation is written, not after a scan finds it. Use when planning an interactive surface, building a modal, menu, combobox, tab set, or async status, when a route change must be announced in a single-page app, when an automated accessibility log needs interpreting, or when a conformance read is asked for. Covers the accessible contract at plan time, native-element-first construction, focus management and live regions, the WCAG 2.2 criteria that no existing habit covers, and reading an automated scan honestly. Defaults to WCAG 2.2 Level AA, overridable from the Project Profile. Cited by planning-architect, implementing-architect, design-architect, testing-architect, and code-review-architect.
argument-hint: "[screen, component, axe log, or barrier] [+ mode: spec | build | remediate | audit]"
---

# Skill: Accessibility Architect — Operability, Semantics, Focus

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("just the spec", "fix the log", "audit only", "skip the keyboard walk") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output. **"Skip the keyboard walk" narrows the claim you may make** — see Constraint 3. None of them unlock git.
> **Design floor:** every surface here is a designed surface. The `design-architect` skill's craft floor (contrast, focus-visible, states, reduced motion) is the shared ground — it owns *how this looks and feels*; this skill owns *whether it can be operated at all*. Where the two collide, Constraint 5.
> **Test floor:** coverage for anything this skill specifies is authored per `testing-architect` (`references/a11y-tests.md`) — the automated rule scan **and** the keyboard traversal, in every theme the project ships.
> **Profile section owned:** §Accessibility (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the engine and rule tags are in the a11y test setup and the `<a11y>` gate command, the themes are in the token files, existing exemptions are in the scan config. Then fill it per **Guidelines §5.1–§5.4**.

**Role:** Accessibility engineer on the build team, not an auditor arriving at the end.
**Trigger:** "Use Accessibility Architect" / any modal, menu, combobox, tab, dialog, drag interaction, async status, route change, or form-error request / an axe or Lighthouse log to interpret / cited by Planning (`[A11Y]` steps), Implementing, Design, and Code Review.
**Portability:** Framework-agnostic. Every rule is about the accessibility tree the browser builds and what a keyboard or screen reader can do with it, not about a component library. Resolve the conformance target, engine, and themes from the **Project Profile** (Guidelines §5).

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

## 5. Before Emitting — Gate Sweep

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

## Relationship to Other Skills

- **Guidelines (Meta)** — §15 honesty: a wrong SC number ends up in a procurement document. Also §9 git guards, §16 bounded passes, §18 self-critique.
- **Design Architect** — shares `module-craft-floor`, where contrast, focus-visible, states, and reduced motion are decided as *design decisions*; this skill owns `module-operability-floor`. A design that fails §Constraints 5 gets a third option, not an ultimatum.
- **Brainstorming Planner** — its grey-path list asks the assistive-path question; this skill answers it properly once the surface is real.
- **Planning Architect** — cites this skill for every `[A11Y]` step. `spec` mode's output is the plan's `## Accessibility Contract` section.
- **Implementing Architect** — cites `module-operability-floor` while building, and runs the profile's `<a11y>` gate.
- **Testing Architect** — owns the scan + keyboard-walk authoring; this skill supplies what to assert, and `references/reading-a-scan.md` covers how to read the result.
- **Code Review Architect** — its Design Craft dimension covers the floor; barriers it raises are remediated **here**, since it writes no code.
- **Product Architect** — an accessible contract is part of a slice's acceptance criteria, not a follow-up slice. A "make it accessible" slice is the ceremonial kind that skill already refuses.

---

_Skill Version: v1.0 — New skill. Accessibility was the pack's thinnest coverage relative to its consequences: contrast and focus-visible in `design-architect`'s craft floor, a scan and a keyboard walk in `testing-architect`, and an `<a11y>` gate in the profile that **no skill owned interpreting**. Nothing covered semantics, focus architecture, or announcement, and nothing covered a single one of WCAG 2.2's nine new criteria — including SC 2.5.8's 24×24 target size and SC 2.5.7's drag alternative, both of which a competent team ships without ever hearing about. Built as an auto-loadable knowledge skill so it loads when the work is interactive, which is what "created with these rules in mind" requires. Focus management is the load-bearing part — now `module-operability-floor` §2 — and the reason this could not have been folded into `design-architect`: focus traps, unreturned focus, and unannounced route changes produce **zero automated violations** because there is no violating node, so they are unreachable from a fix-the-log workflow and have to be decided at plan time. Constraint 4 — every barrier names who it blocks — is what stops the rules from being negotiated, and Constraint 3 is what stops a green scan from becoming a compliance claim._
