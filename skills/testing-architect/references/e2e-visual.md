# Reference: E2E and Visual Tests

*`testing-architect` reference — read when the run needs it.*

## 4. E2E & Visual Tests

### Helpers Are Mandatory
Use the project's existing e2e helper module — never re-implement seeding, auth, consent dismissal, or theming inline. Helpers encode app-specific bootstrap behavior (ready signals, storage versions, overlay blockers) that inline code gets subtly wrong. If a needed helper doesn't exist, add it *to the helper module* in the same change.

### Spec Skeleton (adapt to the project's framework)
```
describe('<feature> — visual', () => {
  beforeEach: navigate → wait for app ready → dismiss blocking overlays → seed state

  for each theme the project ships:
    beforeEach: set theme
    test('<state under test>'):
      target the component root
      compare screenshot named `<area>-<state>-<theme>`
})
```

### Selector Discipline
- Anchor on **component/element selectors** and stable ids or test attributes already in the markup.
- **Never** scope on styling utility classes — they shift with every refactor.
- If a needed anchor doesn't exist, add a stable id/test attribute in the same change set and cite it in the plan.

### Screenshot Naming & Tolerance
- Pattern: `<area>-<state>-<theme>`. Baselines land in the framework's own directory — never hand-edit them.
- **Every theme the project ships gets covered.** Contrast and color-scheme bugs appear in exactly one theme.
- Respect the project's diff tolerance. **Never loosen it to make a diff pass** — that is the test weakening rule (§Constraint 3).

### When Visual Diffs Appear
Stop and hand it over — the procedure and the exact wording are in `module-gate-battery` §4. Never run the update, never delete a failing baseline, never loosen the tolerance.

---
