# Project Profile

> Copy to `.claude/PROJECT-PROFILE.md`. **Do not try to fill this in all at once.**
> It grows as the project does — each section is filled by the skill that needs it, the first time
> it needs it. A half-filled profile is the normal, healthy state.
> Keep it short. This is a lookup table, not documentation.

## How this file gets filled

Every row carries one of five states. **Never leave a row blank and never guess a value** — pick a state.

| State | Meaning | Who resolves it |
|---|---|---|
| a real value | Known and verified | whoever learned it |
| `n-a` | Doesn't apply to this project | anyone, once |
| `TODO` | Needed now, but nobody has answered | ask the user at the next natural pause |
| `pending: <when>` | Not knowable yet — e.g. `pending: first deploy` | the owning skill, when that moment arrives |
| `assumed: <value>` | A working guess, not verified | must be confirmed before anything irreversible depends on it |

**Section ownership** — a skill fills its own section on first use and leaves the others alone:

| Section | Owner | Filled when |
|---|---|---|
| Identity, Commands | SessionStart bootstrap | first session — mostly auto-detected |
| Conventions | `implementing-architect` / `testing-architect` | first time code or tests are written |
| Design | `design-architect` | first UI work — **established** if the project has no UI yet |
| Security | `security-architect` | first work touching untrusted input, authorization, or secrets |
| Accessibility | `accessibility-architect` | first interactive surface, or the first a11y gate run |
| Search Visibility | `search-optimization-architect` | first GEO / AI-search / crawlability work |
| Documentation Targets, Commit Convention | `rolling-history` | first changelog entry |
| Documentation Standards | `documentation-architect` | first doc written, audited, or repaired |
| Product Definition | `product-architect` | first time work is specified or sliced |
| Deployment | `deployment-architect` | first deploy or first "is this ready to ship?" |
| Guardrails, Propagation Sites | any skill — chiefly `debugging-architect` | whenever something is learned the hard way |

**Greenfield projects:** a project that doesn't exist yet has nothing to detect. Its rows are `pending`, and
they get **decided** rather than discovered — the first skill to need a decision proposes one, and records
it here once the user agrees. Never write `assumed:` values into a greenfield profile silently.

---

## Identity

*Owner: SessionStart bootstrap · mostly auto-detected on first session.*

- **Project:** `<name>` — one line on what it is.
- **Stack:** `<language / framework / runtime>`
- **Package manager:** `<npm | pnpm | yarn | bun | uv | poetry | cargo | go | make | …>`
- **Repo shape:** `<single package | monorepo (workspaces at …) >`

## Packages *(monorepos only — delete this section for a single-package repo)*

*Owner: whichever skill first works inside a package. Resolve the package from the paths you are touching, read its rows first, then fall back to the shared rows below. Package rows win on conflict; a change spanning packages takes the **union** of their constraints.*

| Package | Path | Stack | Gates that differ | Deploy target | UI? |
|---|---|---|---|---|---|
| `<name>` | `packages/<x>` | `<…>` | `<e.g. adds an a11y gate>` | `<…>` | `<yes/no>` |
| `<name>` | `packages/<y>` | `<…>` | `<inherits shared>` | `n-a — library>` | `<no>` |

Everything below is **repo-wide** unless a package overrides it.

## Commands (role → the command this project actually uses)

*Owner: SessionStart bootstrap · auto-detected. A role with no command is `n-a`, never invented.*

> **This table is machine-read.** `check-quality.sh` parses these rows and treats them as the authority
> (Guidelines §5 rule 1), so keep the shape: one row per role, the role in the first cell, the command in
> the second. A cell left blank, set to `n-a`, or still holding a `<placeholder>` falls through to
> auto-detection rather than becoming an invented command — so a half-filled table is safe.

| Role | Command | Notes |
|---|---|---|
| `<lint>` | | |
| `<format>` | | if separate from lint |
| `<typecheck>` | | `n-a` for untyped languages |
| `<test>` | | unit/integration, with coverage if available |
| `<build>` | | the gate that catches what typecheck can't (e.g. AOT/template compilation) |
| `<e2e>` | | `n-a` if none |
| `<visual>` | | golden/screenshot suite, if separate from `<e2e>` |
| `<a11y>` | | `n-a` if none |
| `<audit>` | | dependency advisories |
| `<run>` | | dev server / app entry point + the URL it serves |

**Gate order:** `<lint> → <typecheck> → <test> → <build> → <e2e> → <visual> → <a11y> → <audit>`
Adjust if this project's order differs. Cheap-and-fast first; the slow gate that catches the most goes before the slowest.

**Golden / snapshot update command (USER-ONLY — never run by a skill):** `<command>`
**Report location for failed visual diffs:** `<path>`

## Conventions

*Owner: `implementing-architect` / `testing-architect` · filled the first time code or tests are written here. On a greenfield project these are decisions, not observations.*

- **Design system / UI vocabulary:** `<component library, token set, CSS convention>` — survey before proposing custom UI.
- **Styling:** `<utility-CSS | CSS modules | styled-components | …>`; custom CSS allowed when: `<condition>`
- **State / data layer:** `<pattern>`
- **Localized?** `<no | yes — locales: en, …; mechanism: translate('key') | i18next | gettext | …>`
- **Test layers in use:** `<unit: framework | integration: … | e2e: … | visual: … | a11y: …>`
- **Test file placement:** `<next to source as *.spec.ts | tests/ mirror tree | …>`
- **Coverage bar:** `<e.g. 100% branch on new code>`

## Design

*Owner: `design-architect` · filled at the first UI work. If the project has no interface yet, these are **established** — decided once and then treated as committed — rather than detected.*

- **Does this project have a UI?** `<yes | no — n-a the rest | not yet: pending first screen>`
- **Visual world:** `<committed look, or "none yet — establish on first screen">`
- **Design tokens live in:** `<file//path | none yet>`
- **Component vocabulary:** `<library, or the project's own primitives>`
- **Themes shipped:** `<light | dark | both | named themes>`
- **Default visitor mode:** `<Persuade | Operate | Read | Experience>` — per surface, this is just the common case
- **Type / colour decisions worth not re-litigating:** `<display face, body face, accent, anything already argued about>`
- **Deliberate exceptions to the refuse list:** `<pattern + the brief that earned it>`

## Security

*Owner: `security-architect` · filled at the first work touching untrusted input, authorization, or secrets. **Read the repo before asking** (Guidelines §5.3) — the auth model is in the middleware or guard layer, the authorization seam is wherever data access happens, the secret contract is in the env example, the audit gate is in CI. Ask only what the code cannot say: who may reach production data, and which risks were accepted on purpose.*

- **Auth model:** `<session cookie | JWT | OIDC provider | API keys | none yet>`
- **Authorization enforced at:** `<route guard | data-access layer | both>` — if the answer is "the UI", that is the finding.
- **Ownership check helper:** `<path:symbol | none — each handler does its own>`
- **Secrets come from:** `<manager / env source>`; **never** committed. Rotation is user-only.
- **Untrusted input enters at:** `<public endpoints, forms, uploads, webhooks, imports, message queues, third-party responses>`
- **Standard tracked:** `<OWASP Top 10:2025 (default) | 2021 | + API Security Top 10 | + LLM Top 10>`
- **Audit gate:** `<the <audit> command>` — see §Commands; `n-a` if none.
- **Accepted risks:** `<risk — accepted by <who> on <date> — revisit when <condition>>` — an accepted risk with no revisit condition is an ignored one.

## Accessibility

*Owner: `accessibility-architect` · filled at the first interactive surface or the first `<a11y>` gate run. Read the a11y test setup and the token files first; ask only for the conformance target, the legal driver, and what anyone has actually tested with.*

- **Conformance target:** `<WCAG 2.2 AA (default) | 2.1 AA | A | AAA on: …>`
- **Legal or contractual driver:** `<named regulation | customer requirement | none stated>` — changes how a claim may be worded, not what gets built.
- **A11y engine + rule tags:** `<engine, tag set>` — must match the `<a11y>` gate command in §Commands.
- **Themes the scan must cover:** `<from §Design — contrast findings appear in exactly one>`
- **Assistive tech actually tested with:** `<screen reader + browser pairs | keyboard-only | none yet>` — this row is what bounds any conformance claim.
- **Component patterns already solved:** `<path:symbol for the project's dialog, menu, tabs — reuse before rebuilding>`
- **Known exemptions:** `<component — why it cannot be fixed — accepted by <who>>` — third-party and unfixable only, never convenience.

## Search Visibility

*Owner: `search-optimization-architect` · filled at the first GEO / AI-search work. Read the live site and the framework config before asking — rendering mode is in `view-source`, the crawl policy is in the deployed `robots.txt`.*

- **Is this project a public web property?** `<yes | no — n-a the rest>`
- **Production origin:** `<https://…>` — the URL findings are verified against.
- **Rendering mode per route type:** `<static | server-rendered | client-rendered>` — verified by fetching without JS, not from the framework's docs.
- **Crawl policy — retrieval bots:** `<allowed | blocked | per-bot: …>`; **training bots:** `<allowed | blocked>`; decided by `<who>` on `<date>`.
- **`robots.txt` / sitemap generated by:** `<file path or build step>` — edit the source, never the output.
- **Schema emitted:** `<types + where the JSON-LD is generated>` — `n-a` if none.
- **`llms.txt`:** `<shipped from <source> | deliberately skipped — Tier 3>`
- **Engines that matter commercially, in order:** `<AI Overviews | ChatGPT | Perplexity | agents | …>`
- **Prompt set for measurement:** `<path to the versioned file>`; **runs per prompt:** `<n ≥ 7>`; **last baseline:** `<date>`
- **Conversion event AI referrals are judged on:** `<event name>` — sessions are not the metric.
- **Analytics property / channel group:** `<where assistant referrers are separated from generic referral>`
- **Publishing owner:** `<who can actually change page content>` — content findings are worthless if nobody can ship them.

## Documentation Targets

*Owner: `rolling-history` · filled at the first changelog entry. A doc that doesn't exist is omitted, not invented.*

| File | Path | Updated when |
|---|---|---|
| Changelog | `<path>` | every session (Rolling History) |
| README | `<path>` | setup/scripts/feature-list changes |
| Architecture | `<path>` | structural facts change |
| Deployment | `<path>` | build/ship/runtime/env changes |
| API | `<path>` | integration contract changes |
| Tests | `<path>` | test tooling/strategy changes |

Anything not listed does not exist in this project — don't propose edits to it.

## Documentation Standards

*Owner: `documentation-architect` · filled the first time a doc is written or audited. Read the existing docs before asking: the markup flavour, voice, and docstring style are already on disk.*

- **Markup flavour:** `<CommonMark | GFM | reStructuredText | AsciiDoc | MDX>`
- **Docs site / generator:** `<none — docs live in the repo | the generator + its build command | pending: first docs site>`
- **Docs build / link check command:** `<command>` — `n-a` if none. Never invented (Guidelines §5.3).
- **Primary readers, in order:** `<end users | integrators | contributors | operators>` — the first one is who the README serves.
- **Docstring convention on exported symbols:** `<JSDoc/TSDoc | Google-style | numpydoc | rustdoc | godoc | none — n-a the rest>`
- **Generated reference?** `<no | yes — from <source> by <command>, output at <path>; never hand-edit the output>`
- **Diagram convention:** `<Mermaid in-file | committed SVG | none yet>`
- **Voice:** `<second person, active, imperative headings | …>` — quote a sentence from an existing doc that gets it right.
- **Fixed terminology:** `<term the code uses = term the docs use>` — one name per concept, listed only where the two once disagreed.
- **Deliberately undocumented:** `<internal package, experimental flag, …>` + why, so nobody "fixes" it later.

## Product Definition

*Owner: `product-architect` · filled the first time work is specified or sliced. Read the repo first: the tracker is in the issue templates and PR links, the priority vocabulary and AC format are in the last few tickets, and the slice ceiling is visible in the size of merged PRs.*

- **Where specs live:** `<docs/product/ | the tracker | n-a — this project doesn't write them>`
- **Tracker:** `<GitHub Issues | Jira | Linear | none — slices are handed over in chat>`
- **Priority vocabulary:** `<P0/P1/P2 | Must/Should/Could/Won't | none>`
- **Estimate scale:** `<Fibonacci points | t-shirt | none — n-a>` — `n-a` is a legitimate answer; don't introduce estimating.
- **Acceptance-criteria format:** `<Gherkin Given/When/Then | bullet checklist>` — quote one from an existing ticket.
- **Slice ceiling:** `<one PR | one session | n days>` — what this team actually ships, read from merged PRs, not aspiration.
- **Definition of Done:** `<gates green + review + docs assessed>` — the gates come from §Commands.

## Commit Convention

*Owner: `rolling-history` · read from the repo's own config, or inferred from `git log`. `pending: first commit` on an empty repo.*

- **Enforced by:** `<commitlint config path | none>`
- **Types allowed:** `<feat, fix, docs, style, refactor, perf, test, chore, ci>`
- **Subject case:** `<sentence-case | lower-case | free>` — quote the rule that the hook enforces.
- **Header limit:** `<n chars>`

## Deployment

*Owner: `deployment-architect` · **do not fill this at install time.** Most projects cannot answer it until the first real deploy is on the table. `pending: first deploy` is the correct value until then.*

- **Hosting model:** `<static/CDN | serverless | long-running server | container/orchestrator | package registry | app store>`
- **Environments, in promotion order:** `<local → preview → staging → production>`
- **Who fires the deploy:** `<the user | CI on merge to main | manual approval gate>`

| Environment | Deploy command / mechanism | URL | Config source |
|---|---|---|---|
| `<staging>` | | | `<where env vars come from>` |
| `<production>` | | | |

- **Rollback mechanism:** `<re-point to previous deployment | redeploy previous artifact | revert + rebuild | registry yank>`
- **Realistic time to recover:** `<minutes>`
- **Health check:** `<endpoint or signal>`
- **Critical user path to verify after deploy:** `<one real path, e.g. log in → open dashboard>`
- **Cache layers:** `<CDN | service worker | app cache | none>` — invalidation is `<automatic | this command>`
- **Migrations:** `<none | tool + command>`; reversible? `<yes/no>`; backup taken by `<mechanism>`
- **Versioning scheme:** `<semver | date | build number>`; version appears in: `<every file that must move together>`
- **One-way doors** (things a rollback does not undo): `<migrations, outbound email, payments, client-side caches>`

## Guardrails Specific to This Project

*Owner: any skill · grows over time. Empty on day one is correct. `debugging-architect` writes here whenever a gate should have caught something and didn't; `maintenance-architect` records deliberate non-upgrades.*

- **Do not touch:** `<generated dirs, vendored code, migrations, lockfiles, …>`
- **Deliberately held dependencies** (owner: `maintenance-architect` — decided once, not re-litigated):
  - `<package>` held at `<version>` because `<reason>`; revisit when `<condition>`
- **Known blind spots** (things a green pipeline does *not* prove):
  - `<e.g. typecheck doesn't cover template bindings — only the build does>`
  - `<e.g. CSP-blocked resources still pass visual snapshots>`
- **Security-sensitive sinks in this codebase:** `<import/deserialization paths, storage, auth boundary, file paths, …>`

## Recurring Propagation Sites

When a shared field / public API / external origin changes, the mirror sites the gates miss in **this** project:

- `<category>` → `<paths>`
- `<category>` → `<paths>`

_(Leave empty on day one. Add a line each time a change lands somewhere the gates didn't catch — this section is the highest-value part of the file after a month.)_
