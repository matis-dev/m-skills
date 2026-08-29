---
name: documentation-architect
description: Write, audit, and repair the documentation a project ships — README, quick start, how-to guides, architecture and decision records, API and CLI reference, docstrings on the public surface, migration guides, and user-facing release notes. Use when creating or rewriting any doc, when a reader got stuck, when docs have drifted from the code, or before shipping a change that alters setup, contracts, or structure. Covers reader-and-type selection (tutorial, how-to, reference, explanation), the documentation floor (time-to-first-success, runnable examples, CommonMark, resolving links, honest version facts), the refuse list of doc slop, one-home-per-fact drift control, diagrams that show a mechanism, and an audit mode that produces a friction log instead of a vibe. Stack-agnostic — resolves doc paths, format, and voice from the Project Profile. Cited by rolling-history, planning-architect, and code-review-architect.
argument-hint: "[doc or target] [+ mode: generate | audit | reference | polish | release-notes]"
---

# Skill: Documentation Architect — Docs That Survive Contact With a Reader

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("audit", "polish", "reference only", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Profile section owned:** §Documentation Standards (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo for the answers first** — the format is in the existing docs, the voice is in the README, the docstring convention is in the source, the site generator is in the manifest and config. Then fill it per **Guidelines §5.1–§5.4**. §Documentation Targets — *which* docs exist and when each is touched — is owned by `rolling-history`; read it, don't rewrite it.

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

The floor and the refuse list — prerequisites before the first command, runnable language-tagged blocks, every identifier traced to a file you read, task-shaped headings, resolving links, fixed terminology, sourced version facts, diagrams that show a mechanism, and the slop a document defaults to when nobody decided — live in the **`module-writing-floor`** skill. Load it and sweep the rendered document against it in one batched verification round.

It is shared with `product-architect`, `search-optimization-architect`, `rolling-history`, and `deployment-architect`, all of which emit documents a reader follows. This skill owns *which document to write and for whom*; that module owns *whether it reads*.

---

## 4. One Home Per Fact

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

## 5. What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/reference-docs.md` | Writing reference docs or docstrings on an exported surface. |
| `${CLAUDE_SKILL_DIR}/references/audit-mode.md` | Auditing existing docs. Read-only; produces a friction log, not a verdict. |
| `module-writing-floor` | Always, before emitting. The floor and the refuse list. |
| `module-findings` | Reporting audit findings and their banded verdict. |

---

## 7. Modes of Invocation

| Ask | What this skill does |
|---|---|
| **Generate** a doc | §1 type → §2 ground truth → draft → `module-writing-floor` → §7 sweep. |
| **Audit** existing docs | `references/audit-mode.md`. Read-only, friction log first, `path:line` on every finding. |
| **Reference** for a module, API, or CLI | `references/reference-docs.md` over the exported surface only. Generate from schema or types where the project can; hand-write the *when to use this*. |
| **Polish** | `module-writing-floor` only. No restructuring, no new sections, no scope growth. |
| **Explain / ADR** | Explanation type: the constraint, the options considered, the choice, and what it costs. Record it where the project keeps decisions; if it keeps none, ask before creating that convention. |
| **Release notes** | User-facing translation of what shipped — "fixed a crash when creating a profile", not "fix NPE in UserSvc" — grouped as features / fixes / **breaking**, with a migration guide for every breaking item and the required action stated as steps. The **changelog itself belongs to `rolling-history`**; this produces the human-facing notes from it, and never invents a version number or a date. |
| **Docstrings** | `references/reference-docs.md` across the public surface. Never a docstring on a private helper whose name already says it (Guidelines §13). |

---

## 8. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then confirm:

- [ ] Reader and doc type named, and the document serves exactly one of each (§1).
- [ ] Every command, path, flag, env var, and symbol traced to a file you read or a command you ran (§2, Guidelines §15).
- [ ] The happy path was executed — or the output says plainly that it wasn't.
- [ ] `module-writing-floor` swept: prerequisites first, blocks runnable and tagged, headings task-shaped, links and anchors resolve, no time estimates, refuse list clean.
- [ ] No fact duplicated without a link to its home; any contradiction found was resolved by naming an authority (§4).
- [ ] Diagrams show a mechanism, carry a caption, and match the current structure.
- [ ] Nothing documented that does not exist yet; nothing unreleased mentioned without a label.
- [ ] Edits were surgical; no doc created that the project didn't have without asking.
- [ ] Verification stayed within two rounds (Guidelines §16).

If a gate fails, fix it. A confidently wrong doc costs more than a missing one.

---

## Relationship to Other Skills

- **Guidelines (Meta)** — everything here inherits from it, especially §3 surgical changes, §13 minimal comments (reconciled in `references/reference-docs.md`), §15 honest output, §16 bounded passes, §18 self-critique.
- **Rolling History** — owns the changelog, the §Documentation Targets table, and the *verdict* on which docs a session reaches. When that verdict is anything other than `no change`, this skill does the writing. The two never both edit the changelog: that file is Rolling History's alone.
- **Planning Architect** — cite this skill on any plan step that ships a doc, and name the reader and doc type in the step itself.
- **Code Review Architect** — `module-writing-floor` is the source of documentation findings; report them with `path:line` and the same confidence gate as any other finding (`module-findings`).
- **Design Architect** — for docs with a rendered surface (a docs site, a landing page), `module-craft-floor` governs the *presentation*; this skill governs the *content*.
- **Deployment Architect** — migration guides and upgrade instructions are written here from the facts that skill establishes; it owns the rollback plan, this owns the words a reader follows.
- **Testing Architect** — a documented example that must keep working belongs in the test suite. Say so when one qualifies.

---

_Skill Version: v1.0 — New skill. Closes the pack's last coverage gap: `rolling-history` could detect that a doc needed an edit but had no discipline for writing one, and every other stage assumed documentation was somebody else's problem. Consolidates three prior standalone prompts (documentation generation, documentation audit, technical reference / API) into one skill built around two failure modes rather than a template: docs written from the code outward that answer the wrong question, and docs that drift into confident lies. Hence §1 reader-and-type selection, §2 ground truth before writing, §5 one-home-per-fact drift control, and §7's friction log in place of a subjective grade. `references/reference-docs.md` reconciles reference docstrings with Guidelines §13. Release notes are covered; the changelog stays with `rolling-history`._
