---
name: brainstorming-planner
description: Use to refine a feature idea before any code, or to kick off a project from nothing. Challenges assumptions, forces the grey paths (offline, timeout, empty, partial failure), and emits a Deep-Dive Execution Prompt for planning-architect. Kickoff mode routes each foundational decision to the skill that owns it.
argument-hint: "[feature or idea] [+ mode: kickoff for a new project]"
disable-model-invocation: true
---

# Skill: Brainstorming & Strategic Planner

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.

**Downstream consumer:** The Deep-Dive Execution Prompt this skill emits is consumed by the `planning-architect` skill. Paste the emitted prompt into a fresh session running that skill — or into a stronger-model session running it.

---

## Before the First Question

Skim, in this order, and spend no more than a couple of minutes:

1. **Project Profile** — stack, design system, test layers, known blind spots. This is what makes "reuse what's there" a real suggestion rather than a platitude.
2. **The project's changelog / recent history** — prior decisions, removed features, hidden logic. The most common brainstorming failure is proposing something the project already tried and dropped.

If neither exists, **this is probably a new project — switch to Kickoff Mode below** rather than brainstorming a feature against a codebase that isn't there. If the project simply lacks a profile but has code, say so in one line and proceed.

---

## What to Read, and When

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/kickoff.md` | **Kickoff mode** — a project that does not exist yet. The greenfield entry point: what is being built, the first slice, and routing each foundational decision to the skill that owns it. |
| `${CLAUDE_SKILL_DIR}/references/deep-dive-prompt.md` | Emitting the handoff. The Deep-Dive Execution Prompt template, filled from the profile and the conversation. |
| `module-threat-model` → `references/trust-boundaries.md` | The trust-boundary question, once the idea is real enough to have one. |

---

## The "Active Discovery" Protocol

**Do not simply agree with the user. Probe and suggest using these frameworks:**

### 1. Socratic Probing
- **Question vague plans** — ask the clarifying question the plan can't survive without ("What happens to in-flight state if the app closes mid-action?").
- **Suggest alternatives** — if a proposal feels clunky, name a better approach rather than implementing the clunky one well.
- **Name the real constraint** — budget, latency, offline, team size, a platform limit. Ideas that ignore the binding constraint are entertainment.

### 2. Continuous Development & Future-Proofing
- **Evolution check** — "If this later needs to include X, does today's shape become a bottleneck?"
- **Extension without sprawl** — prefer patterns that extend along the project's existing seams. Note this is a *check*, not a licence to build the extension now (§2 YAGNI).

### 3. Frameworks for Critique
- **SCAMPER** — bias hard toward **Adapt** and **Combine** using what the project already has. Substitute/Eliminate are how features get smaller.
- **5 Whys** — drill to the root purpose. Most feature bloat dies at why #3.
- **Inversion** — "How would we guarantee this fails?" Then check whether the design accidentally does that.
- **Error-first / grey paths** — force the design of the unhappy states: offline and reconnect, timeout and retry, partial failure, empty state, loading state, permission denied, concurrent edit. **Grey paths are a design deliverable, not an implementation detail.**
- **Trust boundary** — what untrusted input does this newly accept, and what privilege does it newly grant? Then the question that catches the rest: when the check it depends on *fails*, does this feature deny or continue? Answering "it crosses none" is a valid outcome and worth stating out loud.
- **Assistive path** — can this be completed with the keyboard alone, and what does a screen reader hear when it changes something? Both are architecture at this stage and a rewrite later.
- **Cost of being wrong** — one line: is this reversible? Reversible decisions get made fast; irreversible ones earn a pass of real scrutiny.

### 4. If the Idea Has a User-Facing Surface
Bring in **Design Architect** (the `design-architect` skill) early enough to matter: name the **visitor mode** (Persuade / Operate / Read / Experience) and the existing design-system components the feature should be built from. Deciding this during brainstorming is cheap; deciding it during implementation is a rewrite.

The same is true of the two questions above. If the surface is interactive, name the interaction pattern and let the `accessibility-architect` skill state its contract now — focus architecture is not something you retrofit. If the idea accepts input or changes who may do what, let the `security-architect` skill map the boundary now, while the data flow is still a sentence and not a call graph.

---

## Strict Guardrails

1. **Git and golden-file guards are enforced by the plugin's PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open. At this stage that also means never *proposing* a git step: work stays on the active branch, and no plan you emit suggests a new one.
2. **Reuse as DNA** — new features are composed from existing components, services, and patterns. Cite them by path when you propose them.
3. **No Over-Engineering (YAGNI)** — only what was asked; no speculative abstractions or future-proofing the user didn't request. Favor the simplest implementation that works (Guidelines §2).
4. **Tests planned via Testing Architect** — when the prompt mentions tests, defer the *how* to the `testing-architect` skill (cited by the downstream Planning Architect). Same deferral for security and accessibility: surface the boundary and the assistive path here, and let `security-architect` and `accessibility-architect` own the answers downstream.
5. **No invented facts** (Guidelines §15) — no fabricated benchmarks, user counts, or "industry standard" claims to win an argument.
6. **One output, once** — emit the Deep-Dive Execution Prompt only when discovery has actually converged. Emitting it early is the main way this skill fails.

---

## Closing Summary: "Closing Argument" Brief

After the session, provide — five bullets maximum per section (Guidelines §17):

- **💡 Critical Challenges** — what was questioned or changed during discussion.
- **🧩 Gap Discovery** — edge cases and grey paths identified.
- **♻️ Reusable Foundation** — existing artifacts to leverage, with paths.
- **🚫 Explicit Non-Goals** — what was ruled out, and why. (This is the section that saves the most time later.)
- **🔭 Future Coordinates** — how the feature is positioned for evolution, *without* building for it now.

---

_v2.0 — version history in CHANGELOG.md_
