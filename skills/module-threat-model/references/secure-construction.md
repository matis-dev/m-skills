# Reference: Secure Construction — the Write-Time Half

*`module-threat-model` reference — read when the run needs it.*

## 3. Secure Construction — the Write-Time Half

Grouped by sink, because that is how you meet them.

**Building a query or command**
Parameterize or use the project's query builder — never string concatenation, never a template literal with a user value, and not for identifiers or `ORDER BY` either (allow-list those against a fixed set of column names). Shell commands take an argument array, never a composed string. If the project has a data-access layer, the fix is to go through it, not around it (Guidelines §7, reuse before create).

**Rendering into a document**
Let the framework's binding escape it. The raw-HTML escape hatch requires sanitization by the project's existing sanitizer *and* an inline comment naming why it is unavoidable. Never build markup by concatenation. A URL from user input is validated against an allowed scheme set before it becomes an `href` or a redirect target.

**Making an authorization decision**
Enforce at the data access, not only in the UI — a hidden button is not a control. The check answers *may this actor perform this action on this specific object*, so it takes the actor and the object, never just the action. Prefer one shared guard the whole codebase routes through over per-handler checks that drift. **The error path denies.**

**Accepting a file**
Limit size before reading, and count before iterating. Validate type by content where the project can, not by extension or client-supplied content-type. **Never use a client-supplied filename as a path component** — generate the stored name. Serve user uploads from a path or origin that cannot execute them.

**Handling secrets**
Read from the project's configured source (profile §Security). Never a literal, never a default fallback value that is a real key, never in a client bundle, never in a log line, never in an error message. New config value → check every declaration site per `module-propagation`, Protocol C.

**Writing the error path**
Fail closed and log the decision. The user sees a generic message; the log gets the detail. Never let a `catch` around a verification, permission, or signature check continue as if it had passed — this is A10, and it is the one a passing test suite will never show you.

**Adding a dependency**
Check the name against the real package character by character. Check that it is maintained and that its last publish is plausible. Pin it. Read the lockfile diff for transitive additions you did not ask for. This is A03, and "it was in the tutorial" is not provenance.

---
