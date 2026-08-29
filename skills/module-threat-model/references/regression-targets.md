# Reference: Regression Targets

*`module-threat-model` reference — read when the run needs it.*

## 6. Regression Targets

**What to test against comes from here; how the test is built and where it lives belongs to `testing-architect` §2.** The pairing rule is one-directional: the test must **fail against the unpatched code**. A security test that passes before the fix is asserting the happy path with a scary name. Name the test by the attack, not by the fix.

The sinks worth a regression test, whenever a change reaches one:

- **Untrusted deserialization / import** — feed a payload carrying prototype-polluting keys (`__proto__`, `constructor.prototype`) or unexpected shape through the real import/merge/hydrate path. Assert the global object is untouched **and** the malicious keys are dropped from the result.
- **Injection into a rendering or query sink** — bind attacker markup or a `javascript:`-style URL through the real code path; assert it is escaped or rejected, and that any "trust this" escape hatch only ever receives developer-controlled input.
- **Consent / permission gates** — assert the sensitive write or read is **blocked** before consent and allowed after.
- **AuthZ / IDOR** — assert an unauthorized route, or an id the user doesn't own, is refused rather than silently served.
- **Path traversal** — assert `..` and absolute-path segments in a user- or import-controlled string are rejected before touching a file path, asset URL, dynamic import, or storage key.
- **Size / shape limits** — assert a malformed or oversized input is rejected by the sanitizer *before* it reaches storage, forms, or export.

Keep these as ordinary tests in the project's existing framework. No new tooling.
