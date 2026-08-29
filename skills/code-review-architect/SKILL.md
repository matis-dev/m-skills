---
name: code-review-architect
description: Review a change set (working tree, branch diff, or PR) for maintainability, performance, security, correctness, and design craft, ending in one merged 0-100 score and verdict. Use when the user asks to review this branch, review a PR, or wants a quality and security read before staging. Runs the project's static gates, a full threat model (injection, untrusted deserialization, storage, authz and IDOR, path traversal, dependency advisories, secrets, logging), the change-propagation audit, and a confidence gate that drops findings below 80 percent certainty. Stack-agnostic — resolves gates and conventions from the Project Profile. Read-only, writes no code.
argument-hint: "[branch, PR#, or empty for working tree] [+ modifiers: skip gates]"
disable-model-invocation: true
---

# Skill: Code Review Architect — Quality, Security & Craft Review

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("tests later", "skip gates", "fix the findings", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Remediation is elsewhere.** This skill writes no code (§Constraints). A security finding is fixed by the `security-architect` skill; an accessibility barrier by the `accessibility-architect` skill; a test gap by the `testing-architect` skill. Name the owning skill on the finding so the fix has somewhere to go — a review that ends in a list nobody can act on is half a deliverable.

**Role:** Lead Reviewer. Evaluate a change set against the project's conventions and produce one unified verdict covering **maintainability, performance, security, correctness, and design craft**.
**Trigger:** "Use Code Review Architect" / "Review this branch" / "Review PR #N".
**Output:** A markdown review in the fixed shape at `${CLAUDE_SKILL_DIR}/references/output-format.md`, ending in a single combined score and verdict.
**Portability:** The procedure is universal. Gates, conventions, and blind spots come from the **Project Profile** (Guidelines §5).

---

## Operational Constraints (Strict)

1. **Read-only.** Writes no production code. May read freely and run gates; every fix is the user's call.
2. **Git and golden-file guards are enforced by the plugin's PreToolUse hook**, not merely stated here (Guidelines §9, §10). Any git command that writes — and any `gh` command that publishes — is **denied by the runtime**, as is `--no-verify` and any snapshot-update command. Read-only inspection stays open. Files stay unstaged and visual diffs stay the user's to review. Restate the guard inside the review output.
3. **No scope creep in findings.** Comment only on the change set unless an issue *outside* the diff is directly load-bearing for it. If you stray, label it `[OUT-OF-DIFF]` and justify in one line.
4. **Findings follow `module-findings`** — the citation requirement, the confidence gate (post only what you'd rate ≥ 80), the false-positive list, the "worth a second look" bucket for severe-but-unverified items, the severity bands, and the verdict rules. Load it before writing a single finding.
5. **Tests evaluated via Testing Architect**; **UI evaluated via Design Architect.** Don't invent ad-hoc critique in either domain.
6. **No finding without a location and an owner.** Every one carries `path/to/file:42` and names the skill that writes its fix, since this one writes none.
7. **Every number is real** (Guidelines §15). Coverage percentages, advisory counts, and line references come from output you actually saw.
8. **Bounded** (Guidelines §16). One gate batch, one diff pass, one synthesis. Don't re-read the diff hunting for a fifth Medium.

---

## Mandatory Considerations

Every review addresses each dimension explicitly. Silence on one is itself a finding ("not assessed because…").

1. **Maintainability** — readability, intent-revealing naming, dead code, duplication vs. reuse, abstraction level, comment hygiene (Guidelines §13), typing discipline, adherence to the project's existing idiom.
2. **Performance** — algorithmic cost on the hot path, N+1 queries or writes, bundle/binary impact, lazy boundaries, subscription/listener/handle leaks, list rendering keys, asset weight, avoidable re-computation, caching correctness.
3. **Security** — the threat model in Phase 4, anchored to OWASP Top 10:2025 via the `security-architect` skill §1.
4. **Correctness & Tests** — does the change do what it claims? Tests paired with code (Guidelines §11)? Coverage on new branches? Green-but-lying traps (`module-gate-battery` §3)?
5. **Design craft & accessibility** — for UI-visible diffs, `module-craft-floor` and the `design-architect` refuse list, plus `module-operability-floor`.
6. **Project conventions** — the committed design system, architecture topology, and idioms from the profile.
7. **Inherited guards** — the change set itself contains no committed git/CI bypasses, no auto-update of golden files, no `--no-verify` traces in scripts.
8. **Goal trace** — every change line traces to a stated objective. Flag drive-by edits.
9. **One unified verdict** — all dimensions collapse into a single 0–100 score so the user reads one number, not five.

---

## What to Read, and When

| Read | When |
|---|---|
| `module-gate-battery` | Phase 2 — the gate order, the one-batch rule, the result table. |
| `module-propagation` | Phase 3 — when shape, an API, or an origin changed. |
| `module-threat-model` | Phase 4 — the whole security pass. |
| `module-craft-floor` + `module-operability-floor` | Phase 3, UI-visible diffs only. |
| `module-findings` | Before writing a single finding. Confidence gate, severities, bands. |
| `${CLAUDE_SKILL_DIR}/references/output-format.md` | Assembling the review. |

---

## Procedure (5 Phases)

### Phase 1 — Scope & Intake
- Identify the change set: working tree, branch vs. its base, or a specific PR.
- Run, in parallel where independent: `git status`, `git diff <base>...HEAD`, `git log <base>..HEAD --oneline`.
- Read the full diff. Group by area (module / view / service / test / config / docs).
- Read commit messages and any PR description for **stated intent**. Record the claimed goals — they anchor Phase 5's goal trace.

### Phase 2 — Static Gates
Run them per the `module-gate-battery` skill — its order, its one-batch rule, its result table. Never auto-update a visual baseline (§4 there).

A failing gate is captured verbatim under Findings → Correctness/Tests, at minimum **High**.

### Phase 3 — Quality Pass (Maintainability + Performance + Craft)

Walk the diff file by file, against `${CLAUDE_SKILL_DIR}/references/quality-pass.md` — naming and reuse, abstraction level, YAGNI, dead code, comment hygiene, typing, user-facing text, doc drift, hot-path cost, leaks, N+1, bundle weight, and the UI craft and operability floors.

Then, on top of that pass:

### Phase 4 — Security Pass

Load the `module-threat-model` skill and run its **§4 review sweep** over the diff. Each item is yes/no/n-a; any "yes" is a finding with severity, and a group with no findings is explicitly noted clean rather than omitted. Group headings carry their **OWASP Top 10:2025** anchor — cite the category only when you are certain of it, and describe the weakness without an identifier when you are not (Guidelines §15).

**If the plan carried `[SEC]` tags, start there.** Verify the trust boundaries the plan named actually got their controls, at the place the plan said. That is a cheaper and more reliable pass than re-deriving the threat model from the diff, and a boundary the plan named but the diff does not implement is a finding on its own.

> **Findings are described here; the fix is written by the `security-architect` skill** (`remediate` mode), with the regression test that fails against the unpatched code. Reachability is part of the finding, not an afterthought: state the path from an attacker-controlled input to the sink, or state that you could not establish one. The severity bands for this pass are in that module's §4.

### Phase 5 — Synthesis
- Trace every diff hunk to a stated goal. Drive-bys → Maintainability finding.
- Collect Testing Architect and Design Architect findings.
- Collapse everything into the unified scale.

---

## Scoring (One Merged Scale)

| Dimension | Max | What it measures |
|---|---|---|
| Maintainability | 25 | Readability, reuse, abstraction level, conventions, comment hygiene, dead code, propagation completeness |
| Performance | 15 | Hot-path cost, leaks, N+1, bundle/asset weight, rendering hygiene |
| Security | 30 | The Phase 4 threat model, anchored to OWASP Top 10:2025 |
| Correctness & Tests | 20 | Gates pass, coverage on new code, paired tests, green-but-lying traps |
| Design Craft | 10 | `module-craft-floor`, the refuse list, and `module-operability-floor` on UI-visible changes (**re-weight to Maintainability when the diff has no UI**) |
| **Total** | **100** | |

### Severity, deductions, and bands

All three are in `module-findings` §3–§4: the five severity levels with their deductions, the four verdict bands, and the **hard override** — any Critical forces 🔴 Block regardless of total, and the override is stated in the verdict line.

A dimension floors at 0. Dimensions sum to `Total / 100`, and every deduction traces to a listed finding.

---

## Quality Checklist (before claiming "Review complete")

- [ ] Scope explicit (base/head, file count, stated goals).
- [ ] Every gate in the profile run and recorded; none invented.
- [ ] Every finding has a `path:line`, a severity, a category, and a concrete fix.
- [ ] Security pass covered every Phase 4 section, supply chain and exceptional conditions included; clean sections noted explicitly.
- [ ] Any `[SEC]` / `[A11Y]` commitments the plan made were verified as landed, not re-derived from scratch.
- [ ] Every OWASP category or CWE cited is one you are certain of; uncertain ones described without an identifier.
- [ ] Each finding names the skill that owns its fix (this one writes no code).
- [ ] Change-propagation audit performed when shape / API / origin changed.
- [ ] `module-findings` applied: every posted finding self-rated ≥ 80, located, and owned; false positives dropped; severe-but-unverified routed to "Worth a second look".
- [ ] Design craft **and** accessibility operability assessed for UI-visible diffs (or the dimension re-weighted and said so).
- [ ] Test findings sourced from Testing Architect patterns.
- [ ] Coverage numbers and advisory counts copied from real output, never estimated.
- [ ] Score breakdown sums to total; deductions trace to listed findings; verdict band matches; Critical override stated if applied.
- [ ] Verdict and next action lead the document (Guidelines §17).
- [ ] No code written; no git/CI/golden mutations performed.

---

## When to Use This Skill

- After Implementing Architect declares a change set ready, **before** the user stages or commits.
- On any branch needing a unified quality + security read.
- On a PR — fetch it with the platform CLI, then run the procedure against its diff range.
- Direct invocation with no plan: still produce the full review; the goal trace notes "no stated goals — inferred from commit messages."

---

## Relationship to Other Skills

- **Guidelines (Meta)** — every principle here inherits from it.
- **Testing Architect** — cited for all test-quality findings.
- **Design Architect** — cited for all UI craft findings.
- **Planning Architect** — if the review surfaces a structural problem too big for a follow-up fix, recommend a fresh plan.
- **Implementing Architect** — applies approved fixes under user control; this skill never edits code.

---

_Skill Version: v2.0 — Genericized: gates, conventions, doc targets, and blind spots resolve from the Project Profile (Guidelines §5); framework-specific review rows (utility-CSS purge, one framework's change detection, one API doc) replaced by stack-neutral equivalents. Threat model restated by sink category rather than by one app's shape, keeping prototype pollution, IDOR, path traversal, and the policy-declared-in-two-places blind spot. Adds a fifth scored dimension, Design Craft, sourced from the new Design Architect (re-weighted away when the diff has no UI), a consolidated change-propagation audit covering shape/API/origin, the no-estimated-numbers rule, and a verdict-first output shape. Prior v1.6 — API-doc drift check; v1.5 — confidence gate + deserialization/IDOR/path-traversal groups; v1.4–v1.2 — YAGNI pass, i18n/CSP/service-API checks, field-change propagation_
