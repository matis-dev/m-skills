# Reference: The Review Sweep

*`module-threat-model` reference — read when the run needs it.*

## 4. The Review Sweep

Each item is yes/no/n-a; any "yes" is a finding with severity. Sections with no findings are explicitly noted clean.

**If the plan carried `[SEC]` tags, start there.** Verify the trust boundaries the plan named actually got their controls, at the place the plan said. That is a cheaper and more reliable pass than re-deriving the threat model from the diff, and a boundary the plan named but the diff does not implement is a finding on its own.

**Injection & rendering sinks** *(A04)*
- Raw HTML/markup binding without sanitization; a "trust this value" escape hatch without inline justification.
- User-controlled string interpolated into a URL, template, shell command, or query without validation or parameterization.
- Dynamic code execution (`eval`, `Function`, string-argument timers, dynamic import of a user-controlled path).

**Untrusted input & deserialization** *(A08)*
- Parsed user input **merged or spread into an existing object without key filtering** — a prototype-pollution sink. Flag any deep-merge, spread, or assign over untrusted input that doesn't drop dangerous keys or use a null-prototype target. Structured cloning does **not** sanitize.
- Imported data trusted for **shape** without passing the sanitizer/validator before it reaches storage, forms, or export.
- Missing size/type/count limits on uploads or imports.

**Network / IO** *(A02, A05)*
- Requests to user-controlled URLs; origin pinned?
- New external `<script>`/`<link>` — pinned version, integrity, crossorigin where applicable?
- **New external origin loaded** — every place the security policy is declared updated (markup meta *and* server header, dev *and* prod config), with the right directive? A missing host is a functional break, not just hardening. **Blind spot:** a blocked resource renders consistently broken, so its visual baseline still passes — flag as a verification gap (`module-propagation`, Protocol C).

**Storage** *(A01, A05)*
- Anything sensitive written to client storage without the project's consent/permission flow?
- PII, tokens, or plaintext secrets stored at all? Keys namespaced against collision?

**Routing / AuthZ** *(A01)*
- New route gated where it should be? Public-by-default acceptable only if intentional — flag uncertainty.
- **IDOR** — an id or index from a route/query used to select or mutate data with no ownership check?
- **Path traversal** — user- or import-controlled string building a file path, asset URL, dynamic import, or storage key without normalizing `..` and leading-slash segments? Common on import/export filenames.

**Configuration / Secrets** *(A02, A05)*
- Any string matching a secret pattern (API key, token, password, private key, cloud key prefix, JWT)? Cite every hit even if it looks intentional.
- Hardcoded internal infrastructure URLs; production secrets landing in a tracked config file.

**Dependencies** *(A06)*
- Advisories from `<audit>` tied to changed deps — each is a finding at the audit's severity.
- New packages: maintainer reputation, last-publish sanity, typo-squat ruled out against the known-good name.
- Transitive pins via overrides/resolutions — justified?

**Server-rendering / hydration** *(A04 — if applicable)*
- User-controlled data escaped through the framework's binding (safe) vs. interpolated raw into HTML (unsafe)?
- Hydration mismatch enabling DOM clobbering?

**Supply chain** *(A03 — broader than the advisory scan above)*
- New dependency, CI action, or base image left **unpinned**, or a lockfile change nobody read for transitive additions?
- A build or install step fetching a script over the network and executing it?
- CI credentials or workflow permissions wider than the job needs; a publish step running from an unverified pipeline?

**Exceptional conditions** *(A10 — the one no gate reports)*
- A `catch` around a permission, signature, token, or verification check that **swallows the failure and continues**?
- A security decision whose error path returns permissive — `true`, `null`-as-allowed, or a fall-through to the default branch?
- A dependency timeout or outage that degrades **open** instead of closed?
- An error message or stack trace reaching the user with internal structure in it?
> Fail-open code passes every test and every scanner, because it is working code until the day the thing it calls is down. Read the error path deliberately; it will not be flagged for you.

**Logging** *(A09)*
- New logging of request/response bodies, tokens, or PII?
- Handlers swallowing security-relevant exceptions silently?

> Severity guidance: data exfiltration / auth bypass / RCE-class → **Critical**. Stored injection or a known-CVE dep with an exploit path → **High**. Injection reachable only via developer-controlled input → **Medium**. Defense-in-depth gaps → **Low** or **Nit**.

---
