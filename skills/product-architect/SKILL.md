---
name: product-architect
description: Define what to build and cut it into shippable pieces. Use to split an approved plan or a too-big feature into independently shippable slices with acceptance criteria (decompose — the common case), to refine one feature into milestones (deep-dive), or, upstream of any code, to write a product brief, a PRD, or a research and interview plan. Covers vertical slicing over horizontal, INVEST, the slice ceiling that forces a second cut, Gherkin acceptance criteria, prioritized scope with explicit non-goals, non-functional requirements, and the Mom Test discipline for user research. Every number is sourced or labelled a hypothesis — a PRD's invented metric becomes a fact nobody can trace. Stack-agnostic; cites documentation-architect for the writing floor and hands each slice back to planning or implementing.
argument-hint: "[the plan, feature, or idea] [+ mode: decompose | deep-dive | prd | brief | research]"
disable-model-invocation: true
---

# Skill: Product Architect — Define It, Then Cut It Small

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("decompose", "prd", "proceed", "skip the research") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Writing floor:** every artifact this skill emits is a document. Apply the `documentation-architect` skill's §3 floor and §4 refuse list to it — structure, active voice, no time estimates, no invented numbers. This skill owns *what the document says*; that one owns *how it reads*.
> **Profile section owned:** §Product Definition (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the tracker is in the issue templates and PR links, the priority vocabulary is in the existing issues, the acceptance-criteria format is in the last few tickets, the slice ceiling is visible in the size of merged PRs. Then ask at most 3–4 questions covering only what the repo cannot say, and write it back.

**Role:** Technical product owner. Turn intent into work that can actually be finished.
**Trigger:** "Use Product Architect" / "split this plan" / "write a PRD" / any request to size, slice, or specify work.
**Portability:** No stack assumptions. Trackers, point scales, and priority vocabularies are resolved from the **Project Profile** (Guidelines §5), never assumed.

**The two failures this exists to prevent:**
1. **Work arrives at implementation too big to finish.** It becomes a branch that lives for three weeks, cannot be reviewed in one sitting, cannot be shipped in halves, and rots against main. Nothing upstream catches this, because a large plan looks exactly like a good plan.
2. **A spec full of numbers nobody can trace.** "Reduce support tickets by 20%", "users expect this in under 200ms", "the market is $4B" — invented in a first draft, quoted as fact in the third, and load-bearing for a decision by the sixth. Guidelines §15 applies hardest here, because a product document is *specifically* the artifact people cite later.

---

## Where This Sits in the Pipeline

**Two entry points, at different altitudes. Say which one you are in.**

| Entry | Modes | Comes after | Hands off to |
|---|---|---|---|
| **Downstream — the common case** | `decompose`, `deep-dive` | an approved plan (`planning-architect`) or a feature that is clearly too big | one `implementing-architect` run **per slice** |
| **Upstream — before any code** | `brief`, `prd`, `research` | nothing, or a `brainstorming-planner` session | `brainstorming-planner` → `planning-architect` |

The downstream path is the one most sessions want: *refined idea → plan → **cut the plan into slices** → implement each*. A plan is the right input for slicing, because you can only cut along seams you have already found — slicing before the technical shape is known produces stories that fight the architecture and get re-cut anyway.

The upstream path cannot be moved downstream, and pretending otherwise is how specs become theatre: a brief written after the plan is a summary, and market research conducted after implementation is a justification. **If a `brief`, `prd`, or `research` request arrives once a plan already exists, say so in one line** and ask whether they want the honest version (a retro-spec, labelled as one) or whether the real need is `decompose`.

---

## Operational Constraints

1. **Every number is sourced or labelled.** A metric came from a command you ran, a file you read, a search result you cite, or the user — otherwise it is written as `hypothesis:` or `target (unvalidated):`, never as a finding. This is Guidelines §15 and it is the single most important rule in this skill.
2. **A target is not a measurement.** "Cut onboarding drop-off to 15%" is a goal and reads as one. "Onboarding drop-off is 38%" is a claim and needs a source. Never let the second shape carry an invented value.
3. **Non-goals are a deliverable, not a courtesy.** Every artifact names what it is *not* doing. Scope containment is most of the value here; a spec with no `Won't` section has not been scoped.
4. **Slices are vertical.** Every slice delivers observable value end to end. "All the backend, then all the frontend" is not two slices — it is one slice and a half-finished branch (Guidelines §12).
5. **Never invent a persona, quote, or user need.** If discovery hasn't happened, the persona is an assumption with a name on it, and the artifact says so.
6. **This skill writes documents and tickets, never code.** **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). A `git add` / `commit` / `push` / branch operation, a `--no-verify`, or a snapshot-update command is **denied by the runtime**. Files stay unstaged and visual diffs stay the user's to review.

---

## Mode: `decompose` — Cut a Plan Into Shippable Slices

The primary mode. Input: an approved plan, an epic, or a feature too big for one sitting. Output: an ordered set of slices, each one an independent handoff to `implementing-architect`.

### 1. Find the seams

Read the plan and identify where value can be cut without leaving something half-built. Take the **first heuristic that produces slices which each stand alone** — this is the Laziness Ladder (Guidelines §2) applied to slicing:

| Cut along | Use when | Example shape |
|---|---|---|
| **Workflow steps** | the feature is a sequence | ship "create draft" before "publish", before "schedule" |
| **Happy path vs. grey paths** | the unhappy states are most of the work | ship the success case; offline, retry, and conflict follow as their own slices |
| **Business-rule variations** | one rule has many cases | ship the default rule; the exceptions each become a slice |
| **Data variation** | the shape varies by type or source | ship one type end to end, then widen |
| **Interface / surface** | it must work in several places | ship one platform or one viewport, then the next |
| **Operations** | it is CRUD-shaped | read before write before delete; delete is often its own slice because it is where the danger is |
| **Deferred scale** | it must eventually be fast or large | ship the correct naive version with its ceiling named (Guidelines §2), optimize as a later slice |

**Never cut by layer, by role, or by activity.** "Database slice / API slice / UI slice", "backend dev's part / frontend dev's part", and "build slice / test slice" all produce work that cannot ship on its own.

### 2. Apply the slice ceiling

**If a slice cannot be implemented, reviewed, and shipped in one session, cut it again.** Resolve the project's actual ceiling from §Product Definition — if it is unrecorded, read the merged PRs and use what this team actually ships. Two more cuts is normal. A slice you cannot cut further and still cannot finish is a signal the plan is wrong; say that instead of shipping an impossible ticket.

Then check each slice against **INVEST**, and name the letter when one fails:

- **I**ndependent — shippable without waiting on a sibling. Sequential is fine; entangled is not.
- **N**egotiable — states the outcome, not the implementation. The plan holds the *how*.
- **V**aluable — someone can see the difference. **A slice whose only value is "the next slice becomes possible" is not a slice** — fold it into the one that needs it.
- **E**stimable — if nobody can size it, it needs a spike first, and the spike is its own timeboxed slice with a written question.
- **S**mall — under the ceiling.
- **T**estable — the acceptance criteria are falsifiable.

### 3. Write each slice

```
### Slice N: <outcome, in the user's words>
- **Value:** who can now do what
- **Priority:** <project's vocabulary — P0/P1/P2, MoSCoW, whatever §Product Definition says>
- **Depends on:** <slice number, or nothing>
- **Acceptance criteria:** Given / When / Then — or the project's format if it has one
- **Out of scope:** what a reviewer might expect here and will not find
- **Notes for implementation:** the reuse paths and constraints carried down from the plan
```

Then order them: **walking skeleton first** (thinnest end-to-end path — it proves the seams are real), **then highest risk** (the slice most likely to invalidate the plan, while changing course is still cheap), **then by value**.

### 4. Slice anti-patterns — refuse these

- **A "setup" or "scaffolding" slice** with no observable outcome. Fold it into the first slice that needs it.
- **A "write the tests" slice.** Tests ship with the code they verify (Guidelines §11). A test-only slice means the previous slice was not done.
- **A "QA" or "polish" slice** used to defer finishing. Name the specific gap and put it in the slice that owns it.
- **"Refactor first, then the feature"** as two slices in one plan — that is bundling, and it destroys attribution when something breaks (`maintenance-architect` constraint 1). Either the refactor stands alone with its own justification, or it happens inside the slice that needs it.
- **A slice with acceptance criteria that restate the title.** If the AC is not falsifiable, it is decoration.
- **More than about seven slices for one feature.** Group them into two rounds and lead with the first — more than seven is a roadmap, not a decomposition (Guidelines §17.4).

**Handoff:** each slice is pasted into a fresh `implementing-architect` run, carrying its AC and its notes. State this in one line at the end, and name which slice to start with.

---

## Mode: `deep-dive` — Refine One Feature Into Milestones

For a feature that is understood but not yet shaped. Lighter than a PRD, more than a plan.

1. **Pattern check** — how this class of feature is normally built, and which conventions users already expect. Anything cited as an industry pattern is either something you can point to or is labelled an assumption.
2. **Refine the scope** — say what in the original idea is bloat and what is missing. Agreeing is not the job (`brainstorming-planner` guardrail); a tighter version is the deliverable.
3. **Name the hidden complexity** — the three technical risks that decide whether this is a week or a month: shared state, real-time behaviour, permissions, migration, third-party limits.
4. **Three milestones** — walking skeleton, then the real experience (validation, errors, the grey paths), then scale and delight. Each milestone is a `decompose` input, not a ticket.

---

## Mode: `prd` — Requirements Someone Can Build From

Only when the work genuinely needs a durable spec: several people, a contract with another team, a regulated surface, or a decision that will be re-litigated. **A PRD for a two-day feature is overhead** — say so and offer `deep-dive` instead (Guidelines §2).

Sections, in this order, and none of them padded:

1. **Header** — name, status, owner, date.
2. **Problem** — the user pain, as *As a … I want … so that …*, plus what happens if nobody builds it.
3. **Success** — the north star metric, with its **current value and its source**, or an explicit `baseline unknown — instrument before measuring`. Input metrics beneath it.
4. **Audience** — primary and secondary. A persona with no research behind it is written as `assumption:`.
5. **Scope, prioritized** — `Must / Should / Could / Won't` in the project's own vocabulary. **The `Won't` section is mandatory** and is the section that saves the most time later.
6. **Functional requirements** — the happy path as numbered steps, plus a diagram where the flow is non-obvious (`documentation-architect` §3 governs the diagram).
7. **Non-functional requirements** — performance, security and access control, scale, accessibility, localization. **Each with a number that is either sourced or marked as a target**, never a plausible-sounding default.
8. **Grey paths** — offline, timeout, empty, loading, partial failure, permission denied, concurrent edit. Carried from `brainstorming-planner` if that ran; produced here if it didn't.
9. **Data and analytics** — new fields, schema changes, and the events that must be tracked for section 3's metrics to ever be measurable.
10. **Risks and dependencies** — third parties, legal and compliance, one-way doors.
11. **Acceptance criteria** — 3–5 Given/When/Then scenarios covering the happy path, one grey path, and one boundary.

Close by naming the next step: `decompose` this PRD, or take it to `planning-architect` for the technical plan first.

---

## Mode: `brief` — One Page, Before Anything

The north-star document. Not a spec — it exists to align on value and scope and to be read in two minutes.

- **Pitch** — *For [customer] who [need], [product] is a [category] that [benefit]. Unlike [alternative], it [differentiator].*
- **Problem** — the pain, in the user's own words where you have them.
- **Value propositions** — three benefits, not features. "Cuts data entry in half" over "auto-fills forms".
- **The magical moment** — one narrative paragraph of the thing working.
- **In scope / out of scope** — explicit, and the out-of-scope list is longer.
- **Success criteria** — how you would know, including what you would have to instrument to find out.

Every word earns its place or gets cut. If it runs past a page, it has become a PRD — say so and switch.

---

## Mode: `research` — Investigate, Don't Confirm

Market landscape, competitors, or user interviews. **The failure mode here is generating confident market data that does not exist**, and it is the most damaging thing in this file, so:

> **Nothing in a research output is a finding unless it has a source you can name** — a search result, a document the user supplied, a repository you read. Everything else is written under `Hypotheses to validate`. A competitor's feature list you did not verify, a market size, a pricing anchor, a "users commonly complain that…" — all hypotheses. This is not hedging; it is the difference between research and fiction (Guidelines §15).

**Landscape** — direct competitors, indirect ones, and the status quo (which is usually a spreadsheet, a manual process, or doing nothing — and is usually the real competitor). For each: their positioning, and what you can actually verify about it.

**Gaps** — table stakes you lack, differentiators available, and the features competitors have that users demonstrably do not use. Format each gap as `missing: <feature> · who has it: <competitor> · impact: <high/med/low> · evidence: <source or "assumption">`.

**Interview scripts** — the Mom Test discipline, because a script that invites lying wastes the interview:
- Ask about **past behaviour**, never future intent. "Tell me about the last time you…" — never "Would you use…".
- Never pitch before you understand the problem. The prototype comes out last, if at all.
- Dig on the pain: what was hardest, why, what did they do instead, **did they pay for anything**.
- Distinguish **interest from commitment**. "That looks cool" is a fail. Money, time, or an introduction is a signal.
- Deliverable: a screener (3 questions), the script with interviewer cues, and a capture sheet — plus one line per question on why it cannot be answered dishonestly.

---

## Guardrails

1. **No git, ever** (Guidelines §9) — including creating tickets in a tracker, which is an outward-facing action and needs the user's explicit go-ahead per destination.
2. **No invented data** (Guidelines §15) — metrics, market sizes, competitor claims, user quotes, personas. Sourced or labelled, with no third option.
3. **No code.** Slices carry acceptance criteria and constraints; `implementing-architect` writes the implementation.
4. **Don't re-plan.** If a plan exists, slice along it. Rewriting the technical approach here means the plan was wrong — say that plainly and send it back rather than quietly replacing it.
5. **Don't pad the artifact.** A `brief` that is really a PRD, a PRD for a two-day change, or a decomposition with a ceremonial "setup" ticket all fail Guidelines §2.
6. **One artifact per run.** Emit the mode that was asked for; offer the next one in a single closing line.

---

## Before Emitting — Gate Sweep

Run the six-axis self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Mode and entry point named (upstream vs. downstream), and the input actually suits it.
- [ ] Every number is sourced, or explicitly labelled `hypothesis` / `target` / `baseline unknown`.
- [ ] Non-goals present and specific.
- [ ] *(decompose)* Every slice is vertical, under the ceiling, INVEST-clean, and independently shippable.
- [ ] *(decompose)* No setup, test-only, QA, or refactor-bundled slice; ordering starts with the walking skeleton.
- [ ] Acceptance criteria are falsifiable, in the project's format.
- [ ] The writing passes `documentation-architect` §3 and §4 — structure, active voice, no time estimates.
- [ ] Closing line names exactly one next action and the skill that owns it (Guidelines §17.3).

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §2 (no padding, no ceremonial tickets), §11 (tests ship with code, never a separate slice), §12 (no half-finished slices), §15 (the sourcing rule), §17 (cap lists, one next action).
- **Brainstorming Planner** — upstream sibling. It pressure-tests whether the idea is right; this writes it down and sizes it. Its grey paths feed the PRD and become slices.
- **Planning Architect** — **the usual input.** It produces the technical plan; `decompose` cuts that plan into shippable slices along seams the plan already found.
- **Implementing Architect** — the usual output. One run per slice, carrying its acceptance criteria.
- **Documentation Architect** — owns the writing floor for everything emitted here, and turns a shipped PRD's contract into user-facing docs.
- **Testing Architect** — acceptance criteria are the source for the test cases; it owns which layer each one lands in.
- **Design Architect** — any slice with a user-facing surface names its visitor mode and the design-system components, decided here rather than during implementation.

---

_Skill Version: v1.0 — New skill. Fills the pack's last structural gap: `planning-architect` accepted a story as input but nothing produced one, so cutting large work into shippable pieces happened only in the user's head. Positioned **after** the plan for its primary modes, because slicing follows the seams a plan has already found — cutting earlier produces stories that fight the architecture. `brief`, `prd`, and `research` remain upstream and say so when invoked late, rather than pretending a retro-spec is a spec. Consolidates five prior standalone prompts (PRD, product brief, user story generation, market research + competitive analysis, user research script, feature deep dive). The sourcing rule in §Constraints 1–2 is the deliberate correction to those prompts, whose "data-backed" framing invited exactly the confident fabrication Guidelines §15 forbids._
