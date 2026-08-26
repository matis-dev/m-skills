---
name: documentation-architect
description: Write, audit, and repair the documentation a project ships — README, quick start, how-to guides, architecture and decision records, API and CLI reference, docstrings on the public surface, migration guides, and user-facing release notes. Use when creating or rewriting any doc, when a reader got stuck, when docs have drifted from the code, or before shipping a change that alters setup, contracts, or structure. Covers reader-and-type selection (tutorial, how-to, reference, explanation), the documentation floor (time-to-first-success, runnable examples, CommonMark, resolving links, honest version facts), the refuse list of doc slop, one-home-per-fact drift control, diagrams that show a mechanism, and an audit mode that produces a friction log instead of a vibe. Stack-agnostic — resolves doc paths, format, and voice from the Project Profile. Cited by rolling-history, planning-architect, and code-review-architect.
argument-hint: "[doc or target] [+ mode: generate | audit | reference | polish | release-notes]"
---

# Skill: Documentation Architect — Docs That Survive Contact With a Reader

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("audit", "polish", "reference only", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Documentation Standards (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo for the answers first** — the format is in the existing docs, the voice is in the README, the docstring convention is in the source, the site generator is in the manifest and config — then ask at most 3–4 questions covering only what the code cannot say (who the docs are actually for, which audience is under-served, what the team refuses to document). A question the repo already answers is a defect (Guidelines §5.3). §Documentation Targets — *which* docs exist and when each is touched — is owned by `rolling-history`; read it, don't rewrite it.

**Role:** Technical writer and documentation architect. Turn what the code does into what a reader can do.
**Trigger:** "Use Documentation Architect" / any write-or-fix-a-doc request / cited by Rolling History when a doc actually needs an edit, by Planning for docs-bearing steps, and by Code Review for doc findings.
**Portability:** Format-agnostic. Every rule targets the rendered document and the reader in front of it, not a generator. Resolve doc paths, markup flavour, site tooling, and voice from the **Project Profile** (Guidelines §5) before writing anything.

**The problem this exists to solve:** documentation fails in two directions and both look fine from the inside. It is written *from the code outward* — accurate, complete, and useless, because it answers "what is this symbol" when the reader asked "how do I do the thing". Or it is written once, correctly, and then the code moves and the doc doesn't, so it becomes a confident liar that costs more than no doc at all. Everything below aims at one outcome: a reader with the stated goal gets there, and nothing in the file claims something the repo cannot back up.

---

## Operational Constraints

1. **Document what exists, not what is planned.** An unbuilt flag, an unmerged endpoint, an aspirational config key — none of them appear. This is Guidelines §15 in the place it does the most damage: a fabricated code sample is *executed* by the reader, and it fails on their machine, not yours. If a doc must mention something not yet shipped, it is labelled unreleased and dated, or it waits.
2. **Read the code before writing about it.** Every command, path, flag, env var, endpoint, type, and default is read from a real file or run in a real shell before it is written down. Never transcribe from memory of what such a project usually does.
3. **The project's committed doc conventions win.** Markup flavour, heading depth, file layout, terminology, voice, and docstring style come from the docs that already exist — read a representative one before adding a sibling. Improving the house style is a separate task from writing today's page.
4. **Surgical edits over rewrites.** An existing doc gets the smallest edit that makes it true (Guidelines §3). A wholesale rewrite needs the user's agreement and a stated reason, because it destroys the review history of every sentence that was already correct.
5. **Never create a doc the project doesn't have** without asking. A new top-level file is scope creep, and an orphan doc nobody links to is worse than the gap it filled.
6. **Bounded passes** (Guidelines §16). Draft fully → one batched verification round (run the examples, resolve the links, check the symbols in the same pass) → one fix batch → at most one confirm round → stop.

---

## 1. Pick the Reader and the Doc Type First

A document serves one reader with one goal. **Mixing types is the most common structural failure** — the tutorial that stops to explain the architecture, the reference page that opens with a sales pitch, the how-to that turns into a changelog. Name the type in one line before writing.

| Type | The reader is | Success looks like | What outranks what |
|---|---|---|---|
| **Tutorial / Quick Start** | New, no context, low patience | Something ran on their machine | **Working beats complete.** One happy path, zero choices, no theory. Every branch you offer is a place to stop. |
| **How-to guide** | Knows the goal, not the steps | The task is done | Task-shaped headings in the reader's words ("Deploy to staging", not "The deployment module"). No conceptual detours. |
| **Reference** | Knows what they want, needs exactness | Found the exact answer fast | **Completeness and precision.** Scannable, uniform, alphabetical or grouped. Personality is noise here. |
| **Explanation / Architecture / ADR** | Deciding, reviewing, or maintaining | Understands *why* it is like this | The reasoning, the alternatives rejected, and the constraint that forced the choice. This is the only type where prose is the point. |

Two follow-on rules:

- **The README is not a type — it is a router.** It answers "what is this, is it for me, how do I start" and then *links out*. A README that has grown a reference section has outgrown itself; propose splitting it rather than continuing to grow it.
- **If the reader can't be named, stop and ask.** "The docs need updating" without a reader produces a page that serves nobody. One question here is cheaper than a rewrite.

---

## 2. Establish Ground Truth Before Writing

Cheapest signal first; nothing below is optional when the doc makes claims about any of it.

1. **Resolve targets** — from the profile's §Documentation Targets (owner: `rolling-history`), the file's path and whether it already exists. From §Documentation Standards, the markup flavour, voice, and any docs-site build. If neither section exists yet, read the docs that are there and match them.
2. **Resolve the entry points you are about to document** — the package manifest's scripts, the CLI's own `--help`, the router or route table, the exported surface, the env example. **The manifest is the authority on commands, not the old README** — a README that contradicts the manifest is the bug you are fixing, not a source.
3. **Run the happy path yourself** where the environment allows it. A quick start you have not executed is a hypothesis. If you cannot run it, say so in the output — "install steps read from the manifest, not executed here" — rather than implying verification you didn't do (Guidelines §15).
4. **Check what the reader already hit.** If this was triggered by someone getting stuck, their exact error is the spec. Reproduce it before rewriting around it.

---

## 3. The Documentation Floor

Checks on the **rendered document**, not on intentions. Run them together in the batched verification round.

- **Time to first success** — prerequisites (runtime versions, accounts, keys, OS constraints) appear **before** the first install command, not in a section below it. The path from landing on the page to something working is the shortest thing on the page.
- **Every code block is runnable as written** — language-tagged, copy-pasteable, no invisible prerequisite, no `$` prompt prefix mixed into copyable lines, no placeholder where a real value from this repo exists. Multi-line commands survive a copy. If output matters, show the real output.
- **Every identifier is real** — commands, paths, flags, env vars, endpoints, types, and defaults each traceable to a file you read. A plausible-looking invented flag is the single most expensive error this skill exists to prevent.
- **Task-shaped headings, active voice** — headings name what the reader does ("Configure the database"), not what the system is ("Database configuration"). "Run the migration" over "The migration should be run". A reader scanning only the headings should see their task.
- **No time estimates.** "Takes 5 minutes", "a quick setup", "this should be fast" — cut them. They are wrong for anyone on a slow network, a cold cache, or an unfamiliar stack, and being wrong there is exactly where a reader gives up. Describe the *steps*, which are stable, not the *duration*, which isn't. *(This is a documentation rule and does not touch Guidelines §17.6, which asks for specific estimates in your replies to the user — a reply estimates a job you are about to do; a doc estimates a stranger's machine.)*
- **Structure is CommonMark-clean** — ATX headers, exactly one H1, no skipped heading levels, fenced blocks with a language tag, real lists rather than dashes in a paragraph. A table of contents once the page passes roughly a screenful of headings.
- **Links resolve** — internal paths exist, anchors match a real heading, external links are ones you actually have reason to believe in. Relative links must survive wherever the docs are rendered (repo view and docs site resolve them differently).
- **Terminology is fixed** — one name per concept for the whole document set. If the code says `workspace` and the docs say `project`, pick one, say which, and note it in the profile. Acronyms and project-specific terms are defined on first use.
- **Version and compatibility facts carry their source** — a supported-version range comes from the manifest, the CI matrix, or the engines field. If nothing states it, say "not specified" rather than picking a number that looks right.
- **Diagrams show a mechanism** — a diagram earns its place by showing something prose cannot: a flow, a sequence, a state machine, a boundary. Prefer text-based diagrams the repo can diff (Mermaid `flowchart` / `sequenceDiagram` / `stateDiagram`). Every diagram gets a caption saying what it shows, and any diagram whose structure the current change invalidates is updated in the same edit or removed. A box-and-arrow picture that restates the file tree is decoration; cut it.
- **Accessibility** — images carry real alt text describing the content, not the filename. Never ship a screenshot of text that could be text. Tables have real headers. Nothing is conveyed by colour alone.

---

## 4. The Refuse List

These are what documentation defaults to when nobody decided. The project's own brief can earn any of them back; reaching for one on autopilot means you weren't writing for a reader.

**Voice and framing**
- "Simply", "just", "easy", "obvious", "of course", "as you can see". They add nothing when the reader succeeds and blame them when they fail.
- Time estimates of any kind (see §3).
- Marketing voice inside a reference or how-to page. Sell on the landing page, not in the parameter table.
- A wall of prose before the reader knows what the thing is. First sentence: what it is. Second: who it's for or what problem it kills.
- "See the code for details", "refer to the source", "self-explanatory". If the code were sufficient, the doc would not be open.
- Apologetic or provisional framing — "this section is a bit rough", "docs coming soon" — left permanently in a shipped file. Either write it or open an issue.

**Structure**
- A feature table that restates the module list with no task attached to any row.
- An auto-generated symbol dump presented as a guide. Generated reference is fine *as reference*, linked from a hand-written page that explains when to reach for what.
- Deep heading nests (H4 and below) used to organise what is really a table.
- Emoji on every heading as a substitute for hierarchy; badge rows longer than the description they sit above.
- A "Contributing" or "License" section that crowds the quick start above the fold.
- Duplicating the same fact in three files (see §5).

**Content**
- Invented numbers: benchmarks, adoption counts, uptime, "10× faster", coverage percentages nobody measured (Guidelines §15).
- `foo` / `bar` / `example.com` / `YOUR_API_KEY_HERE` where a real identifier from this repo would teach more.
- Documented aspirations — a flag, endpoint, or option that does not exist yet.
- A comment or docstring that restates its own signature (`// gets the user` above `getUser()`). That is noise under Guidelines §13, not documentation.
- Copying an upstream library's docs into your repo instead of linking. It is stale the day the dependency bumps.
- Screenshots as the only home of a value someone needs to type.

---

## 5. One Home Per Fact

Doc rot is almost never a writing failure — it is a **duplication** failure. Every fact copied into a second file is a fact that will disagree with itself, and the copy nobody remembers is the one the reader finds.

The rule: **each fact has exactly one authoritative home, and everything else links to it.** Prefer the home the tooling already keeps honest.

| Fact | Authoritative home | Docs should |
|---|---|---|
| Available commands / scripts | the package manifest | name the command, not restate the whole script list |
| Env vars and their defaults | the env example / config schema | link it; document *meaning*, not the list |
| CLI flags | the CLI's own help output | show real usage; generate the exhaustive table if the tool can |
| API request/response shapes | the schema or type definitions | link or generate; hand-copied payloads drift silently |
| Supported runtime versions | the manifest / CI matrix | cite which one it read |
| Current architecture | one architecture doc + its diagram | other docs link to it rather than re-describing |
| What shipped when | the changelog (owner: `rolling-history`) | never re-narrate release history in the README |

When a duplicate is unavoidable (a quick start genuinely needs the install command inline), keep the copy **minimal and marked**: one line, plus a link to the home. And when you find an existing contradiction between two files, **fix the direction of truth, not just the wording** — say in the output which file you made authoritative and which now links to it.

---

## 6. The Public Surface — Reference and Docstrings

Reference documentation covers the **contract**, not the implementation. It is exempt from Guidelines §13's minimal-comments rule for exactly one reason: §13 governs inline comments aimed at a maintainer reading the body, while a docstring on an exported symbol is the interface's own documentation, aimed at a caller who will never open the file. Inside a function body, §13 still applies in full.

Document **every exported symbol**, and nothing that isn't. For each, in the project's own docstring convention:

1. **What it does and when to reach for it** — one sentence, task-framed. "Persists user preferences to local storage" beats "saves data".
2. **Parameters** — name, type, whether it is required, the default, and what the value *means*. A table when there are more than about three, matching the project's existing reference layout.
3. **Return value** — type and meaning, including the empty, null, and partial cases.
4. **Failure behaviour** — what it throws or returns on invalid input, on a missing dependency, on a timeout. **This is the half that is always missing and always needed**, and it is what separates a reference from a signature dump.
5. **Side effects** — I/O, global or shared state, cache writes, network calls, anything that makes the call non-obvious to reason about. Silence here reads as "pure"; say so if it isn't.
6. **One realistic example** — a call in the shape a real caller would write, using this project's own types and names.

For an HTTP or RPC contract, the same six with auth requirements, status codes (including the error ones), and pagination or rate-limit behaviour where they apply. Generate from the schema where the project has one; hand-written payload examples drift.

---

## 7. Audit Mode — Produce a Friction Log, Not a Verdict

Triggered by "audit", "review the docs", or a report that someone got stuck. **Read-only: write nothing.** The output is evidence, not opinion.

1. **Walk the path as the reader.** Start at the entry point they would start at, follow the instructions *literally*, and record every place the document stopped being sufficient — a missing prerequisite, a command that failed, a term never defined, a link that 404s, a choice with no guidance. This is the friction log, and it is the most valuable thing in the report because it is reproducible.
2. **Sweep the floor (§3) and the refuse list (§4)** over each target file, with `path:line` for every finding.
3. **Check truth against the code** — every command against the manifest, every path against the tree, every flag against the CLI, every documented symbol against the exports. Report drift as its own class; it is the highest-severity finding here because it is confidently wrong.
4. **Find the gaps by audience** (§1). Which reader has no page? A project with three reference pages and no quick start is failing its most numerous reader.

Report shape — cap each list at five, highest severity first (Guidelines §17):

- **Verdict** — one of `Blocked` (a reader following the docs cannot succeed) / `Rough` (they succeed after guessing) / `Usable` (succeeds, gaps are additive) / `Good` (nothing found above cosmetic). **Name the evidence that set it**, not a feeling. No letter grades and no invented score — an unmeasured number is a fabrication (Guidelines §15).
- **Friction log** — numbered, in the order the reader hits them, each with the concrete fix.
- **Drift** — statements the code contradicts, with both locations.
- **Missing artifacts** — the doc that should exist, and which reader is stranded without it.
- **Top rewrites** — at most three, in `current → improved` form so the user can judge the voice before you touch anything.

---

## 8. Modes of Invocation

| Ask | What this skill does |
|---|---|
| **Generate** a doc | §1 type → §2 ground truth → draft → §9 sweep. |
| **Audit** existing docs | §7. Read-only, friction log first, `path:line` on every finding. |
| **Reference** for a module, API, or CLI | §6 over the exported surface only. Generate from schema or types where the project can; hand-write the *when to use this*. |
| **Polish** | The floor only (§3) plus §4. No restructuring, no new sections, no scope growth. |
| **Explain / ADR** | Explanation type: the constraint, the options considered, the choice, and what it costs. Record it where the project keeps decisions; if it keeps none, ask before creating that convention. |
| **Release notes** | User-facing translation of what shipped — "fixed a crash when creating a profile", not "fix NPE in UserSvc" — grouped as features / fixes / **breaking**, with a migration guide for every breaking item and the required action stated as steps. The **changelog itself belongs to `rolling-history`**; this produces the human-facing notes from it, and never invents a version number or a date. |
| **Docstrings** | §6 across the public surface. Never a docstring on a private helper whose name already says it (Guidelines §13). |

---

## 9. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then confirm:

- [ ] Reader and doc type named, and the document serves exactly one of each (§1).
- [ ] Every command, path, flag, env var, and symbol traced to a file you read or a command you ran (§2, Guidelines §15).
- [ ] The happy path was executed — or the output says plainly that it wasn't.
- [ ] Floor swept (§3): prerequisites first, blocks runnable and tagged, headings task-shaped, links and anchors resolve, no time estimates.
- [ ] Refuse list (§4) clean — anything present is there because the brief earned it.
- [ ] No fact duplicated without a link to its home; any contradiction found was resolved by naming an authority (§5).
- [ ] Diagrams show a mechanism, carry a caption, and match the current structure.
- [ ] Nothing documented that does not exist yet; nothing unreleased mentioned without a label.
- [ ] Edits were surgical; no doc created that the project didn't have without asking.
- [ ] Verification stayed within two rounds (Guidelines §16).

If a gate fails, fix it. A confidently wrong doc costs more than a missing one.

---

## Relationship to Other Skills

- **Guidelines (Meta)** — everything here inherits from it, especially §3 surgical changes, §13 minimal comments (reconciled in §6), §15 honest output, §16 bounded passes, §18 self-critique.
- **Rolling History** — owns the changelog, the §Documentation Targets table, and the *verdict* on which docs a session reaches. When that verdict is anything other than `no change`, this skill does the writing. The two never both edit the changelog: that file is Rolling History's alone.
- **Planning Architect** — cite this skill on any plan step that ships a doc, and name the reader and doc type in the step itself.
- **Code Review Architect** — §3 and §4 are the source of documentation findings; report them with `path:line` and the same confidence gate as any other finding.
- **Design Architect** — for docs with a rendered surface (a docs site, a landing page), the craft floor and refuse list there govern the *presentation*; this skill governs the *content*.
- **Deployment Architect** — migration guides and upgrade instructions are written here from the facts that skill establishes; it owns the rollback plan, this owns the words a reader follows.
- **Testing Architect** — a documented example that must keep working belongs in the test suite. Say so when one qualifies.

---

_Skill Version: v1.0 — New skill. Closes the pack's last coverage gap: `rolling-history` could detect that a doc needed an edit but had no discipline for writing one, and every other stage assumed documentation was somebody else's problem. Consolidates three prior standalone prompts (documentation generation, documentation audit, technical reference / API) into one skill built around two failure modes rather than a template: docs written from the code outward that answer the wrong question, and docs that drift into confident lies. Hence §1 reader-and-type selection, §2 ground truth before writing, §5 one-home-per-fact drift control, and §7's friction log in place of a subjective grade. §6 reconciles reference docstrings with Guidelines §13. Release notes are covered; the changelog stays with `rolling-history`._
