---
name: module-operability-floor
description: "Module — loaded by name from an m-skills architect, not an entry point. Whether an interface can be operated at all: native-element-first construction, the full contract an ARIA role obliges you to supply, focus management, and live regions for async status."
user-invocable: false
---

# Module: The Operability Floor

**Loaded by:** `accessibility-architect` · `design-architect` · `code-review-architect` · `testing-architect` · `planning-architect` · `implementing-architect`. Read it whenever a run touches an interactive surface; do not restate its content in a skill file.

**Why this is separate from the craft floor:** almost everything below produces **zero automated violations**. A focus trap with no exit, focus never returned to the trigger after a dialog closes, a route change that announces nothing — there is no violating node for a scanner to find. They are architectural, which means they are decided when the interaction is designed, not fixed from a log afterwards.

**The rule that governs all of it:** `role`, `aria-*`, and `tabindex` change what assistive technology is *told*, and change nothing about what the element *does*. A `<div role="button">` announces as a button and then ignores Enter, ignores Space, cannot be focused, and cannot be disabled. **No ARIA is better than bad ARIA.**

---

## 1. Native First, ARIA Second

1. **Use the element that already means it.** `<button>`, `<a href>`, `<input>`, `<select>`, `<details>`, `<dialog>`, `<table>`, `<label>`, `<fieldset>`/`<legend>`, heading levels in order. Each arrives with role, keyboard behaviour, focusability, and a disabled state you did not have to write and cannot forget.
2. **Only if no native element expresses it**, reach for ARIA — and then you owe the full contract, not just the role.
3. **Never use ARIA to describe something that is not true**, and never put a role on an element that contradicts it (`role="button"` on an `<a href>`, an interactive control inside `aria-hidden`).

**The contract a role obliges you to supply.** If you write `role="button"` on a non-button you must also supply: `tabindex="0"`, an Enter handler, a Space handler (including preventing page scroll), a visible focus indicator, `aria-disabled` **plus** actually blocking the action, and an accessible name. Six things the native element gave you for free. This is why the answer is almost always "use the button".

**Accessible name, in priority order** — `aria-labelledby` → `aria-label` → the element's own content → `title` (weak, avoid relying on it). Rules that matter in practice:

- **The visible label must be part of the accessible name.** A button reading "Save" with `aria-label="Submit changes"` is unusable by voice control: the user says "click Save" and nothing happens.
- **`aria-label` on a non-interactive element is usually ignored.** It is not a comment field.
- **An icon-only control needs a name**, and the icon itself is `aria-hidden` so it does not double-announce.
- **Decorative images take `alt=""`** — not a missing `alt`, and not a filename. Informative images describe the *information*, not the picture. An image inside a link describes the link's destination.
- **Never `aria-hidden` on a focusable element.** It creates a control that exists for the keyboard and not for the screen reader.

**Structure is semantics too.** One `<h1>`; heading levels descend without skipping and reflect the document, not the font size. Landmarks (`<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`) with labels when repeated. Lists as lists. Tables with real `<th>` and `scope` — a data table is not a grid of divs. A skip link as the first focusable element on a page with repeated navigation.

---

## 2. Focus Management — the Half No Scanner Sees

**Focus order and visibility**
- Tab order follows visual order. If DOM order and visual order disagree, fix the layout — never patch it with positive `tabindex`. Only `0` and `-1` are legitimate.
- Everything interactive is reachable by keyboard and has a **visible** focus indicator. `:focus-visible`, never `outline: none` with no replacement.
- Nothing is focusable that should not be — no `tabindex="0"` on wrappers, no focusable hidden content behind a closed menu or an off-screen carousel slide.
- Check that focus is not *obscured* when it lands — a sticky-header and scroll-padding problem, and the fix is usually `scroll-margin-top`.

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

**Dynamic content** — when new content appears in response to an action, either move focus to it (if the user should act on it now) or announce it (§3). Never both. Never neither.

---

## 3. Live Regions and Async Status

For anything that changes without the user's focus moving: form validation results, save confirmations, search-result counts, upload progress, toasts, connection loss.

- **The container exists in the DOM before the message does.** A live region injected together with its text is frequently not announced — the assistive technology never observed a change. Render the empty region up front and write text into it.
- **`aria-live="polite"`** for everything that can wait for a pause; **`assertive`** only for errors that interrupt the user's task. An assertive region firing on every keystroke is worse than silence.
- Prefer `role="status"` (implicitly polite) and `role="alert"` (implicitly assertive) for the common cases.
- **One region per purpose**, reused. Multiple regions firing at once produce interleaved speech.
- **Do not duplicate an announcement that focus already delivers.** If focus moves to the error summary, the summary does not also need to be a live region — the user hears it twice.
- **Progress and loading** — announce start and end, not every percentage. `aria-busy` on the region being replaced.

**Form errors, the pattern that works:** mark the field `aria-invalid="true"`; associate the message with the field via `aria-describedby` so it is read when focus arrives; on submit-time failure, move focus to a summary listing every error with links to the fields. Errors name the problem *and* the recovery — the craft floor says the same thing about copy; this is where it becomes operability.

---

## 4. The Refuse List

- **`outline: none` with no replacement indicator.** The single most common self-inflicted barrier.
- **Positive `tabindex`.**
- **`aria-hidden` on anything focusable**, or on a whole page region that still contains active controls.
- **A `<div>` or `<span>` with a click handler and nothing else.**
- **`aria-label` that contradicts or omits the visible label.**
- **Placeholder text as the only label.** It disappears on input, and it fails contrast in most designs.
- **Blocking paste into password or one-time-code fields.**
- **Drag as the only way to do something.**
- **Removing a scan rule to reach green.**
- **An accessibility overlay or widget marketed as making a site compliant.** It does not; it frequently makes things worse; disabled-user organizations broadly oppose them. Say so once, plainly, if asked to add one.
