---
name: product-architect
description: Use to cut an approved plan into shippable vertical slices (decompose), refine one feature into milestones (deep-dive), or — upstream of code — write a brief, PRD, or research plan. Enforces the slice ceiling, INVEST, and Gherkin acceptance criteria. Every number is sourced or labelled a hypothesis.
argument-hint: "[the plan, feature, or idea] [+ mode: decompose | deep-dive | prd | brief | research]"
disable-model-invocation: true
---

# Skill: Product Architect — Define It, Then Cut It Small

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Writing floor:** every artifact this skill emits is a document. Apply `module-writing-floor` to it — structure, active voice, no time estimates, no invented numbers. This skill owns *what the document says*; that module owns *how it reads*.
> **Profile section owned:** §Product Definition (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo first** — the tracker is in the issue templates and PR links, the priority vocabulary is in the existing issues, the acceptance-criteria format is in the last few tickets, the slice ceiling is visible in the size of merged PRs. Then fill it per **Guidelines §5.1–§5.4**.

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

1. **Every number is sourced or labelled** — `module-evidence` §2. A metric came from a command you ran, a file you read, a search result you cite, or the user — otherwise it is written as `hypothesis:` or `target (unvalidated):`, never as a finding. This is Guidelines §15 and it is the single most important rule in this skill.
2. **A target is not a measurement.** "Cut onboarding drop-off to 15%" is a goal and reads as one. "Onboarding drop-off is 38%" is a claim and needs a source. Never let the second shape carry an invented value.
3. **Non-goals are a deliverable, not a courtesy.** Every artifact names what it is *not* doing. Scope containment is most of the value here; a spec with no `Won't` section has not been scoped.
4. **Slices are vertical.** Every slice delivers observable value end to end. "All the backend, then all the frontend" is not two slices — it is one slice and a half-finished branch (Guidelines §12).
5. **Never invent a persona, quote, or user need.** If discovery hasn't happened, the persona is an assumption with a name on it, and the artifact says so.
6. **This skill writes documents and tickets, never code.** **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open.

---

## Modes — Read One

Name the mode in one line, then read only its file. A `decompose` run has no use for the PRD sections, and loading them is how a decomposition acquires a ceremonial spec.

| Mode | Read | Produces |
|---|---|---|
| **`decompose`** *(the common case)* | `${CLAUDE_SKILL_DIR}/references/decompose.md` | Vertical slices with acceptance criteria, one per `implementing-architect` run |
| **`deep-dive`** | `${CLAUDE_SKILL_DIR}/references/deep-dive.md` | One feature refined into three milestones |
| **`prd`** | `${CLAUDE_SKILL_DIR}/references/prd.md` | A durable spec, only when the work genuinely needs one |
| **`brief`** | `${CLAUDE_SKILL_DIR}/references/brief.md` | One page: north star and anti-goals |
| **`research`** | `${CLAUDE_SKILL_DIR}/references/research.md` | Landscape, gaps, and Mom Test interview scripts |

Also load `module-writing-floor` before emitting — every artifact here is a document someone reads.

---

## Guardrails

1. **No git, ever** (Guidelines §9) — including creating tickets in a tracker. Filing an issue notifies people and is theirs to send, so the deliverable is the ticket **text**, ready to paste (`module-handover` §4). The plugin's `guard-outward.sh` hook denies `gh issue create` for this reason; a tracker with no CLI is the same rule on the honour system.
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
- [ ] The writing passes `module-writing-floor` — structure, active voice, no time estimates.
- [ ] Closing line names exactly one next action and the skill that owns it (Guidelines §17.3).

---

_v1.0 — version history in CHANGELOG.md_
