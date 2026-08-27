---
name: accessibility-architect
description: Design, build, and repair interfaces so they are operable by keyboard, screen reader, magnification, and imprecise pointers — before the violation is written, not after a scan finds it. Use when planning an interactive surface, building a modal, menu, combobox, tab set, or async status, when a route change must be announced in a single-page app, when an automated accessibility log needs interpreting, or when a conformance read is asked for. Covers the accessible contract at plan time, native-element-first construction, focus management and live regions, the WCAG 2.2 criteria that no existing habit covers, and reading an automated scan honestly. Defaults to WCAG 2.2 Level AA, overridable from the Project Profile. Cited by planning-architect, implementing-architect, design-architect, testing-architect, and code-review-architect.
argument-hint: "[screen, component, axe log, or barrier] [+ mode: spec | build | remediate | audit]"
---

# Skill: Accessibility Architect — Operability, Semantics, Focus

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("just the spec", "fix the log", "audit only", "skip the keyboard walk") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output. **"Skip the keyboard walk" narrows the claim you may make** — see Constraint 3. None of them unlock git.
> **Design floor:** every surface here is a designed surface. The `design-architect` skill's craft floor (contrast, focus-visible, states, reduced motion) is the shared ground — it owns *how this looks and feels*; this skill owns *whether it can be operated at all*. Where the two collide, Constraint 5.
> **Test floor:** coverage for anything this skill specifies is authored per the `testing-architect` skill §5 — the automated rule scan **and** the keyboard traversal, in every theme the project ships.
> **Profile section owned:** §Accessibility (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the engine and rule tags are in the a11y test setup and the `<a11y>` gate command, the themes are in the token files, existing exemptions are in the scan config. Then ask at most 3–4 questions covering only what the code cannot say — the conformance target, whether a legal driver applies, which assistive technology anyone has actually tested with — and write it back. A question the repo already answers is a defect (Guidelines §5.3).

**Role:** Accessibility engineer on the build team, not an auditor arriving at the end.
**Trigger:** "Use Accessibility Architect" / any modal, menu, combobox, tab, dialog, drag interaction, async status, route change, or form-error request / an axe or Lighthouse log to interpret / cited by Planning (`[A11Y]` steps), Implementing, Design, and Code Review.
**Portability:** Framework-agnostic. Every rule is about the accessibility tree the browser builds and what a keyboard or screen reader can do with it, not about a component library. Resolve the conformance target, engine, and themes from the **Project Profile** (Guidelines §5).

**The two failures this exists to prevent:**

1. **Accessibility as a violation list.** A scan runs late, produces 40 findings, someone adds `aria-label` to everything until the count reaches zero, and the modal still traps a keyboard user. Automated rules catch a *minority* of real barriers and can catch none of the architectural ones — focus that goes nowhere, a route change nobody hears, an error announced to no one — because there is no violating node to find. Zero violations is a fact about the scan, not about the interface.

2. **ARIA used as the first tool instead of the last.** `role`, `aria-*`, and `tabindex` change what assistive technology is *told*, and change nothing about what the element *does*. A `<div role="button">` announces as a button and then ignores Enter, ignores Space, cannot be focused, and cannot be disabled. The lie is worse than the original silence: **no ARIA is better than bad ARIA.**

---

## Operational Constraints

1. **Never cite a success criterion by number you have not verified.** Guidelines §15 in a domain where a wrong SC number ends up in a VPAT, a procurement answer, or a legal response. Uncertain → **describe the barrier and who it blocks, and omit the number.** A described barrier with no ID is honest work.
2. **Fix the component, never the test.** No widening a scan exclusion, no adding a rule to the ignore list, no relaxing a threshold to reach green. Exclusions exist only for genuinely third-party, unfixable widgets, each justified with an inline comment naming the reason — the rule already stated at `testing-architect` §5; this skill enforces it rather than restating it.
3. **A green automated scan is not a conformance claim, and never claim a level you have not tested at.** "Passes axe with `wcag22aa` tags, keyboard walk clean on these three flows, not screen-reader tested" is a true and useful statement. "WCAG 2.2 AA compliant" is a claim about 87 criteria, most of which no tool evaluates. Never write the second when you did the first.
4. **Barriers are stated with who they block.** "Target is 18px" is a measurement; "the delete control is 18px, so anyone with a tremor or using a phone one-handed will miss it and hit the adjacent row" is a finding. The second gets fixed. This is not decoration — it is what stops a rule from being lawyered.
5. **The brief wins on aesthetics; the floor wins on access — and where they truly collide, propose a third option.** A design that cannot be operated has not made a trade-off, it has excluded people. But "make it uglier" is almost never the only fix available: a focus ring can be designed, a target can grow its hit area without growing its visual box, a drag can keep its drag *and* gain a click alternative. Bring the third option, not an ultimatum.
6. **Bounded verification** (Guidelines §16). Scan, keyboard-walk, and inspect in one batched round across every theme → one fix batch → at most one confirm round → stop.

---

## Modes

| Mode | Fires at | Produces |
|---|---|---|
| **`spec`** | **Planning** — the point of this skill | The accessible contract *before the component exists*: name, role, value, focus order, keyboard map, and what gets announced. The per-step `[A11Y]` note `planning-architect` carries. Read-only. |
| **`build`** | **Implementation** | The correct construction from §2–§4 — native element first, ARIA only where native cannot express it. |
| **`remediate`** | An axe log, a Lighthouse report, or a reported barrier | The fix in the component, plus the coverage that catches its return (`testing-architect` §5). |
| **`audit`** | An existing surface | §6: an evidence-backed read against the profile's target level, with a banded verdict and an explicit statement of what was **not** tested. Never an invented score. |

Default when unspecified: a feature description → `spec`. A component being written → `build`. A log or a barrier report → `remediate`. A screen with no stated question → `audit`.

---

## 1. Conformance Target

**WCAG 2.2 Level AA** is the default. Resolve the actual target from the profile's §Accessibility — a project may pin 2.1 AA (still the common legal reference in several jurisdictions), or hold specific AAA criteria, or track A only.

WCAG 2.2 reached W3C Recommendation on **2023-10-05**. It adds nine success criteria to 2.1 and **removes** 4.1.1 Parsing (obsolete — browsers recover from malformed markup, and the criterion no longer identified real barriers).

**The nine, because these are the ones no existing habit covers.** Everything a team already does for 2.1 leaves these open:

| SC | Level | What it requires | The failure you will actually find |
|---|---|---|---|
| **2.4.11** Focus Not Obscured (Minimum) | AA | A focused element is not entirely hidden by author-created content | A sticky header or cookie bar covering the element the user just tabbed to. Extremely common, and invisible unless you tab through the page yourself. |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Not obscured *at all* | — |
| 2.4.13 Focus Appearance | AAA | Minimum size and contrast for the focus indicator | — |
| **2.5.7** Dragging Movements | AA | Anything achievable by dragging has a single-pointer alternative | Reorderable lists, sliders, kanban boards, map panning, drag-to-upload with no browse button. Provide click-to-select-then-click-to-place, or arrow-key move, or explicit buttons. |
| **2.5.8** Target Size (Minimum) | AA | Targets are at least **24×24 CSS px**, or spaced so 24px circles do not overlap | Icon-only buttons in dense tables, close buttons, pagination, inline edit/delete affordances. The hit area may exceed the visual box — this is usually invisible padding, not a redesign. |
| **3.2.6** Consistent Help | A | Help mechanisms appear in the same relative order on every page that offers them | A support link that moves between header and footer across sections of the app. |
| **3.3.7** Redundant Entry | A | Information already entered in a process is auto-populated or selectable, not re-asked | "Same as billing address" with no checkbox. Multi-step forms that ask for the email again at step 4. |
| **3.3.8** Accessible Authentication (Minimum) | AA | No cognitive function test (puzzle, transcription, memorization) without an alternative | Blocking paste into a one-time-code field, or into a password field. Image CAPTCHAs with no non-cognitive alternative. |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | As above, with fewer exceptions | — |

The shared floor from 2.0/2.1 still carries most of the weight and is not restated here in full — text alternatives, keyboard operability, contrast (4.5:1 body, 3:1 large text and UI components), labels and instructions, error identification and suggestion, name/role/value, reflow, and orientation. Where those overlap visual craft, they live in `design-architect` §2 and are enforced there.

---

## 2. Native First, ARIA Second

The rule, in order:

1. **Use the element that already means it.** `<button>`, `<a href>`, `<input>`, `<select>`, `<details>`, `<dialog>`, `<table>`, `<label>`, `<fieldset>`/`<legend>`, heading levels in order. Each arrives with role, keyboard behaviour, focusability, and a disabled state you did not have to write and cannot forget.
2. **Only if no native element expresses it**, reach for ARIA — and then you owe the full contract, not just the role.
3. **Never use ARIA to describe something that is not true**, and never put a role on an element that contradicts it (`role="button"` on an `<a href>`, an interactive control inside `aria-hidden`).

**The ARIA contract you take on with a role.** If you write `role="button"` on a non-button you must also supply: `tabindex="0"`, an Enter handler, a Space handler (including preventing page scroll), a visible focus indicator, `aria-disabled` **plus** actually blocking the action, and an accessible name. Six things the native element gave you for free. This is why the answer is almost always "use the button".

**Accessible name, in priority order** — `aria-labelledby` → `aria-label` → the element's own content → `title` (weak, avoid relying on it). Rules that matter in practice:

- **The visible label must be part of the accessible name.** A button reading "Save" with `aria-label="Submit changes"` is unusable by voice control: the user says "click Save" and nothing happens.
- **`aria-label` on a non-interactive element is usually ignored.** It is not a comment field.
- **An icon-only control needs a name**, and the icon itself is `aria-hidden` so it does not double-announce.
- **Decorative images take `alt=""`** — not a missing `alt`, and not a filename. Informative images describe the *information*, not the picture. An image inside a link describes the link's destination.
- **Never `aria-hidden` on a focusable element.** It creates a control that exists for the keyboard and not for the screen reader.

**Structure is semantics too.** One `<h1>`; heading levels descend without skipping and reflect the document, not the font size. Landmarks (`<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`) with labels when repeated. Lists as lists. Tables with real `<th>` and `scope` — a data table is not a grid of divs. A skip link as the first focusable element on a page with repeated navigation.

---

## 3. Focus Management — the Half No Scanner Sees

Automated tooling cannot find these, because a broken focus path has no violating node. They are architectural, which is why they belong in `spec` mode rather than in a fix list.

**Focus order and visibility**
- Tab order follows visual order. If DOM order and visual order disagree, fix the layout — never patch it with positive `tabindex`. Only `0` and `-1` are legitimate.
- Everything interactive is reachable by keyboard and has a **visible** focus indicator. `:focus-visible`, never `outline: none` with no replacement.
- Nothing is focusable that should not be — no `tabindex="0"` on wrappers, no focusable hidden content behind a closed menu or an off-screen carousel slide.
- Check that focus is not *obscured* when it lands (SC 2.4.11) — this is a scroll-padding and sticky-header problem, and the fix is usually `scroll-margin-top`.

**Overlays — modal dialogs, sheets, non-modal popovers**
1. Move focus **into** the overlay on open — the first interactive element, or the dialog container with `tabindex="-1"` when the content should be read from the top.
2. **Trap focus** inside it while it is modal: Tab from the last element returns to the first, Shift+Tab from the first goes to the last.
3. **Escape closes it**, and any closable overlay also has a visible close control (Escape alone is not discoverable).
4. **Return focus to the element that opened it** on close. This is the step that is skipped most often, and losing focus to `<body>` sends a keyboard user back to the top of the document with no idea where they were.
5. Content behind a modal is inert — `inert` on the background, or `aria-hidden` on the siblings. Not on the dialog's own ancestors.
6. Prefer the platform's native dialog where the project can use it; it supplies most of the above.

**Disclosure, menus, and expanding controls**
- The **trigger** carries `aria-expanded` (`true`/`false`), and it lives on the element that is actually activated. `aria-controls` where the relationship is not obvious.
- A menu that opens on hover must also open on focus, and must not close before the pointer can travel to it.
- Arrow-key navigation within a composite widget (menu, tab set, listbox, toolbar) with a single tab stop — the roving-tabindex pattern. **Tab moves between widgets; arrows move within one.** Getting this backwards makes a 40-item menu a 40-press obstacle.

**Single-page routing** — the barrier no scan reports
A client-side route change replaces the page without any of the things a real navigation does. On every route change: move focus to the new view's heading or main container (`tabindex="-1"`), update the document title, and announce the change via a live region for anyone who does not track focus. Without this, a screen-reader user activates a link and hears nothing at all — the most common serious barrier in single-page applications, and it produces zero automated violations.

**Dynamic content** — when new content appears in response to an action, either move focus to it (if the user should act on it now) or announce it (§4). Never both. Never neither.

---

## 4. Live Regions and Async Status

For anything that changes without the user's focus moving: form validation results, save confirmations, search-result counts, upload progress, toasts, connection loss.

- **The container exists in the DOM before the message does.** A live region injected together with its text is frequently not announced — the assistive technology never observed a change. Render the empty region up front and write text into it.
- **`aria-live="polite"`** for everything that can wait for a pause; **`assertive`** only for errors that interrupt the user's task. An assertive region firing on every keystroke is worse than silence.
- Prefer `role="status"` (implicitly polite) and `role="alert"` (implicitly assertive) for the common cases.
- **One region per purpose**, reused. Multiple regions firing at once produce interleaved speech.
- **Do not duplicate an announcement that focus already delivers.** If focus moves to the error summary, the error summary does not also need to be a live region — the user hears it twice.
- **Progress and loading** — announce start and end, not every percentage. `aria-busy` on the region being replaced.

**Form errors, the pattern that works:** mark the field `aria-invalid="true"`; associate the message with the field via `aria-describedby` so it is read when focus arrives; on submit-time failure, move focus to a summary listing every error with links to the fields. Errors name the problem *and* the recovery (`design-architect` §2 says the same thing about copy — this is where it becomes operability).

---

## 5. Who Each Barrier Blocks

The reason Constraint 4 exists. A rule that is only a rule gets negotiated; a rule attached to a person gets fixed.

| Barrier | Who it blocks | What they experience |
|---|---|---|
| No keyboard path, or a focus trap with no exit | Motor-impaired users, anyone using switch access or voice control, and anyone whose mouse just died | The task is impossible — not slow, impossible. |
| No visible focus indicator | Keyboard users, low-vision users, and everyone in bright sunlight | Every keypress is a guess about where they are. |
| Targets under 24px, drag-only interactions | Tremor, limited dexterity, one-handed phone use, and touch generally | Repeated mis-taps, often on the destructive control next to the intended one. |
| Contrast below 4.5:1 | Low vision, colour vision deficiency, aging eyes, any glare | Text is present and unreadable — and the person often assumes it is their fault. |
| Missing or wrong accessible name | Screen-reader and voice-control users | "Button, button, button." Voice control cannot address a control it cannot name. |
| Unannounced route or status change | Screen-reader users | They act, hear nothing, and cannot tell whether it worked or whether the app is broken. |
| Cognitive-function auth, redundant re-entry, inconsistent help | Cognitive and memory disabilities — and, in practice, everyone under pressure | Abandonment at the last step of a flow they had already completed. |
| Motion with no reduced-motion fallback | Vestibular disorders | Nausea and dizziness from using the product. Not a preference. |

---

## 6. Reading an Automated Log

`audit` mode, and the correct response whenever someone says "axe is clean".

1. **A violation count is not a conformance level.** Automated rules evaluate a minority of the criteria; the remainder require a human. Report what was run, against which rule tags, on which routes and states, in which themes.
2. **Group by cause, not by node.** Forty "button has no accessible name" findings are usually one icon-button component. Fix the component and the count collapses — a per-node fix list is how remediation becomes a month of work that should have been an hour.
3. **Scan the states, not just the initial render.** Modal open, menu expanded, error shown, list empty, list loading. Most components are only accessible in the state the scan happened to catch.
4. **Every theme the project ships** — contrast findings routinely appear in exactly one (`testing-architect` §4 says the same for visual coverage, and for the same reason).
5. **Then do the manual half**, without which no conformance statement is available: tab the whole flow start to finish with the mouse untouched, confirm focus is always visible and never trapped, test at 200% zoom and 320px width, and — where anyone on the team can — listen to it in a real screen reader.
6. **Verdict shape:** what was tested · what was found, grouped by cause · what was **not** tested · and a banded verdict against the target level with the evidence for it. Never a number out of 100 with no published method (Guidelines §15).

---

## 7. The Refuse List

- **`outline: none` with no replacement indicator.** The single most common self-inflicted barrier.
- **Positive `tabindex`.**
- **`aria-hidden` on anything focusable**, or on a whole page region that still contains active controls.
- **A `<div>` or `<span>` with a click handler and nothing else.**
- **`aria-label` that contradicts or omits the visible label.**
- **Placeholder text as the only label.** It disappears on input, and it fails contrast in most designs.
- **Blocking paste into password or one-time-code fields** (SC 3.3.8).
- **Drag as the only way to do something** (SC 2.5.7).
- **Removing a scan rule to reach green** (§Constraints 2).
- **An accessibility overlay or widget marketed as making a site compliant.** It does not; it frequently makes things worse; disabled-user organizations broadly oppose them. Say so once, plainly, if asked to add one.
- **Claiming a conformance level that has not been tested at that level** (§Constraints 3).

---

## 8. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Every SC number cited is one you are certain of; uncertain ones described instead (§Constraints 1).
- [ ] Native element used wherever one exists; every ARIA role carries its full contract (§2).
- [ ] Everything interactive is keyboard-reachable, with a visible focus indicator that is not obscured (§3).
- [ ] Every overlay: focus in, trapped, Escape closes, **focus returned to the trigger** (§3).
- [ ] Route changes and async status are announced or focused — one, not both, not neither (§3, §4).
- [ ] Live regions exist in the DOM before their content does (§4).
- [ ] Targets meet 24×24 or the spacing exception; anything draggable has a single-pointer alternative (§1).
- [ ] Checked in **every theme** the project ships (§6.4).
- [ ] Every barrier reported names who it blocks (§Constraints 4).
- [ ] No claim made beyond what was actually tested, and what was not tested is stated (§Constraints 3).
- [ ] Verification stayed within two rounds (Guidelines §16).

---

## 9. Evidence Base *(dated — re-verify before citing, Constraints 1)*

Gathered August 2026.

| Fact | Source | Note |
|---|---|---|
| WCAG 2.2 became a W3C Recommendation on 2023-10-05. 87 success criteria across A/AA/AAA. | [w3.org/TR/WCAG22](https://www.w3.org/TR/WCAG22/) | The default target in §1. |
| The nine new criteria: 2.4.11, 2.4.12, 2.4.13, 2.5.7, 2.5.8, 3.2.6, 3.3.7, 3.3.8, 3.3.9 — with 2.4.11, 2.5.7, 2.5.8 and 3.3.8 at AA, and 3.2.6 and 3.3.7 at A. | Same | The §1 table. Levels matter when citing — an AAA criterion is not a compliance failure at AA. |
| 4.1.1 Parsing was removed in 2.2 as obsolete. | Same | Do not report it as a violation. |
| SC 2.5.8 Target Size (Minimum) is **24×24 CSS px** with a spacing exception; the 44×44 figure belongs to 2.5.5 Target Size (Enhanced), AAA. | Same | Quoting 44×44 as the AA requirement is the most common error here. |
| SC 2.5.7 requires a single-pointer alternative to any dragging movement. | [Understanding SC 2.5.7](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html) | The alternative may be click-then-click, arrow keys, or explicit controls. |

Criterion *text* and the current technique list should be read from the W3C source rather than quoted from memory. This table is the provenance of §1's structure, not a substitute for the spec.

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §15 honesty: a wrong SC number ends up in a procurement document. Also §9 git guards, §16 bounded passes, §18 self-critique.
- **Design Architect** — shares the floor. Contrast, focus-visible, states, and reduced motion stay there as *design decisions*; this skill owns semantics, focus architecture, and announcement. A design that fails §Constraints 5 gets a third option, not an ultimatum.
- **Brainstorming Planner** — its grey-path list asks the assistive-path question; this skill answers it properly once the surface is real.
- **Planning Architect** — cites this skill for every `[A11Y]` step. `spec` mode's output is the plan's `## Accessibility Contract` section.
- **Implementing Architect** — cites §2–§4 while building, and runs the profile's `<a11y>` gate.
- **Testing Architect** — owns the scan + keyboard-walk authoring in its §5; this skill supplies what to assert and, in §6, how to read the result.
- **Code Review Architect** — its Design Craft dimension covers the floor; barriers it raises are remediated **here**, since it writes no code.
- **Product Architect** — an accessible contract is part of a slice's acceptance criteria, not a follow-up slice. A "make it accessible" slice is the ceremonial kind that skill already refuses.

---

_Skill Version: v1.0 — New skill. Accessibility was the pack's thinnest coverage relative to its consequences: contrast and focus-visible in `design-architect`'s craft floor, a scan and a keyboard walk in `testing-architect` §5, and an `<a11y>` gate in the profile that **no skill owned interpreting**. Nothing covered semantics, focus architecture, or announcement, and nothing covered a single one of WCAG 2.2's nine new criteria — including SC 2.5.8's 24×24 target size and SC 2.5.7's drag alternative, both of which a competent team ships without ever hearing about. Built as an auto-loadable knowledge skill so it loads when the work is interactive, which is what "created with these rules in mind" requires. §3 is the load-bearing section and the reason this could not have been folded into `design-architect`: focus traps, unreturned focus, and unannounced route changes produce **zero automated violations** because there is no violating node, so they are unreachable from a fix-the-log workflow and have to be decided at plan time. Constraint 4 — every barrier names who it blocks — is what stops the rules from being negotiated, and Constraint 3 is what stops a green scan from becoming a compliance claim._
