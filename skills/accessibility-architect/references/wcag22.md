# Reference: WCAG 2.2 — the Nine New Criteria

*`accessibility-architect` reference — read when the run needs it.*

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

The shared floor from 2.0/2.1 still carries most of the weight and is not restated here in full — text alternatives, keyboard operability, contrast (4.5:1 body, 3:1 large text and UI components), labels and instructions, error identification and suggestion, name/role/value, reflow, and orientation. Where those overlap visual craft, they live in `module-craft-floor` and are enforced there.

---
