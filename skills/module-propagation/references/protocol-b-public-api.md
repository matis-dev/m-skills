# Reference: Protocol B — Public API & Test Doubles

*`module-propagation` reference — read when the run needs it.*

## Protocol B — Public API & Test Doubles

A green `<typecheck>`/`<build>` does **not** prove consumer *tests* survive: test doubles are built from hand-maintained name lists and silently return nothing for anything not on them.

Grep the type name **and** the method name across the source:

1. **Real callers** — the type checker catches these. It does not catch anything below.
2. **Spy/mock object name lists** — every consumer test that spies this type must add the new method, or the call returns undefined → *"is not a function"* or a misleading *"never called"*.
3. **Hand-written mock classes** — tests substituting a fake implementation need the new method stubbed.
4. **Inline stub objects** passed as providers/config by value.
5. **Tests asserting the OLD collaborator** — if the implementation swapped which collaborator it calls, the test must stub the new one, not the old.

**Closing check:** grep the new method name across test files — every consumer test exercising the changed path should reference it. Then run `<test>`; an *"is not a function"* or a surprise *"never called"* is this protocol, not a product bug.

---
