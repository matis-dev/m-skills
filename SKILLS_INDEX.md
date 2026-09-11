# Skills & Protocols — Modular Pack

A drop-in set of development skills: brainstorm → plan → implement → review → log, with design craft and test strategy cited throughout. **Project-agnostic by construction** — every command, path, framework, and convention is resolved at runtime from a one-time `.claude/PROJECT-PROFILE.md`, not hardcoded here.

**Three tiers.** You invoke an **architect** (17 of them, below). An architect is a short spine — constraints, modes, procedure — that loads **modules** and **reference files** on demand once it knows what the run is. The 9 modules hold what two or more architects would otherwise each restate; the 56 reference files hold what one architect needs in only some runs. → [Modules](#-modules)

Every architect is **invocable** — as `/m-skills:<name>` when installed as a plugin, or `/<name>` when copied into a project's `.claude/skills/`. Modules are never invoked directly. Where an architect branches into routes, a **route command** enters one of them directly and skips the mode question. → [Route Commands](#-route-commands)

Full install instructions live in [README.md](README.md); this file is the catalog.

---

## 🚀 Install

**As a plugin (recommended)** — namespaced commands that can't collide, available in every project:

```
/plugin marketplace add matis-dev/m-skills
/plugin install m-skills@m-skills
```

**Or copy into one project** — clone [matis-dev/m-skills](https://github.com/matis-dev/m-skills) and copy `skills/` → `.claude/skills/`.

Then, in the target project either way:

1. Copy `skills/guidelines-meta/PROJECT-PROFILE.template.md` → `.claude/PROJECT-PROFILE.md` and fill it in **once** (10 minutes). Commands, design system, test layers, doc paths, commit rules, known blind spots.
2. Copy `CLAUDE.template.md` → the repo root as `CLAUDE.md` so the non-negotiable guards load in every session, not only when a skill is invoked.
3. *(Optional)* Create `.claude/quality-gates.conf` from the template at the bottom of `check-quality.sh` — only needed for a command the profile's §Commands table cannot express. It is read as `KEY="value"` data, not sourced as shell, so nothing in it executes. Resolution order is **profile → conf → auto-detection**, and an env var passed on the invocation outranks all three.

**Step 1 mostly does itself, and never all at once.** The profile is **progressive**: each section is owned by the skill that needs it and filled the first time that skill runs — `design-architect` writes §Design at the first screen, `deployment-architect` writes §Deployment at the first deploy. A `SessionStart` hook fills the auto-detectable part (§Identity, §Commands) on first session; on a brand-new project it detects that there is nothing to detect and explicitly doesn't interrogate you. A half-filled profile is the correct state, not an unfinished one.

**Some rules are no longer advice.** `guidelines-meta` §9 (run no git command that writes, and no `gh` command that publishes) and §10 (never auto-accept a golden update) are enforced by a `PreToolUse` hook that **denies** the call, not by prose the model has to be holding in context — as are writes into secret-bearing files (`security-architect` 5) and deploys, publishes, and migrations (`deployment-architect` 2), which come back as a copy-paste runbook instead. Read-only git, read-only `gh`, and every `.env.example` stay open. One flag file, `.claude/.m-skills-no-guards`, releases all of it. See the README's *Enforcement* section for what deliberately stayed prose.

**Skip step 1 entirely and everything still works** — skills auto-detect from `package.json` / `Makefile` / `pyproject.toml` / `Cargo.toml` / `go.mod` and CI config. The profile just makes it a one-time cost instead of a per-session one.

**Who invokes what:** the pipeline stages carry `disable-model-invocation: true` — you trigger them, and Claude never *starts* one unasked. It does **offer**: when a message clearly matches one, a `SessionStart` hook has it ask rather than guess, and your pick is what starts the skill. On by default; `.claude/.m-skills-no-suggest` turns it off (see [README](README.md#suggesting-a-skill)). `design-architect`, `testing-architect`, `documentation-architect`, `security-architect`, and `accessibility-architect` stay auto-loadable because their knowledge is useful mid-task. `guidelines-meta` and every `module-*` are `user-invocable: false` — loaded by another skill, hidden from the `/` menu.

---

## 📋 Architects

### 📜 Meta (cited by every other skill)

- **[Guidelines (Meta)](skills/guidelines-meta/SKILL.md)** — Single source of truth for behavioral principles. Karpathy core + the portability layer. Never invoked alone; every pipeline skill opens by citing it.
  Key sections: **§5 Project Profile** (the indirection that makes this pack portable), §2 Laziness Ladder, §9 git guards, §15 Honest Output (no fabricated metrics, commands, or paths), §16 Bounded Verification Passes (build → one inspection → one fix batch → stop), **§17 Reply Protocol** (the full [i-have-adhd](https://github.com/ayghri/i-have-adhd) ruleset — action first, numbered steps, one next step, lists capped at 5, forbidden openers/closers, pre-send check; optionally applied session-wide via a flag file), §18 Pre-Emit Self-Critique (six axes), §19 Invocation Modifiers.
  - **[Project Profile template](skills/guidelines-meta/PROJECT-PROFILE.template.md)** — the one file you fill in per project.

### 🧠 Strategy & Planning

- **[Brainstorming Planner](skills/brainstorming-planner/SKILL.md)** — Socratic probing, SCAMPER, 5 Whys, inversion, cost-of-being-wrong, and error-first grey-path design. Emits a Deep-Dive Execution Prompt carrying resolved stack, gates, reuse paths, grey paths, and explicit non-goals. **Kickoff Mode** makes it the greenfield entry point: establishes what is being built and the smallest useful slice, routes each foundational decision to the skill that owns it, defers the rest as `pending`, and only then pressure-tests the first slice — setup falls out of the conversation rather than preceding it.
- **[Product Architect](skills/product-architect/SKILL.md)** — Defines what to build and cuts it into pieces that can actually ship. **Five modes at two altitudes.** *Downstream of the plan (the common case):* **`decompose`** — cuts an approved plan into vertical, independently shippable slices using the first seam that holds (workflow step, happy path vs. grey paths, business-rule variation, data variation, surface, CRUD operation, deferred scale), enforces a **slice ceiling** that forces a second cut, checks INVEST and names the failing letter, and refuses the four ceremonial slices (setup, test-only, QA, refactor-bundled); **`deep-dive`** — one feature into three milestones. *Upstream, before any code:* **`prd`** (prioritized scope with a mandatory `Won't`, NFRs, grey paths, Gherkin acceptance criteria), **`brief`** (one-page north star and anti-goals), **`research`** (market and competitive landscape, plus Mom Test interview scripts — past behaviour over stated intent, interest distinguished from commitment). **Every number is sourced or labelled a hypothesis**, which is the deliberate correction to the "data-backed" framing that invites fabrication. Slicing sits *after* planning because you can only cut along seams a plan has already found.
- **[Planning Architect](skills/planning-architect/SKILL.md)** — Consumes that prompt; produces a fixed-shape, project-aware plan with reused utilities, per-step model-tier routing, `[VISUAL]` tags, real verification commands, and a confirmation gate. Cites Testing Architect for every test line and Design Architect for every UI step. Includes the **change-propagation surface** protocol.

### 🎨 Design

- **[Design Architect](skills/design-architect/SKILL.md)** — Interface craft and anti-slop. Visitor modes (Persuade / Operate / Read / Experience), then **§2 Direction** — ground in the subject's material world, pick a named structure from a 21-entry catalog (nine of them for Operate/Read surfaces), derive palette and type pairing by a fixed construction order, name the signature moment, and emit a ten-line brief before any code; the craft floor (contrast, spacing, type, depth, motion, states, browser surfaces, copy, responsive), the refuse list of AI-default patterns, token discipline, structural variety against your own previous output, and a gate sweep before emitting. Distilled from `pbakaus/impeccable` + `nutlope/hallmark`, framework-agnostic.

### 🧪 Test Strategy

- **[Testing Architect](skills/testing-architect/SKILL.md)** — How tests are designed, placed, and authored. Layer resolution from the profile, setup/mocking discipline, security-regression TDD cases for the review threat model, and **§3 the green-but-lying traps** (fake-timer flush illusions, compiler-silenced fixtures, hand-maintained test doubles, gates with blind spots). Cited by Planning and Implementing.

### 🔒 Security

- **[Security Architect](skills/security-architect/SKILL.md)** — Design, build, and repair software so the vulnerability never gets written. Exists because security previously lived almost entirely in Code Review's Phase 4 — 30 of 100 score points, in the one skill that **writes no code by charter**, so a flagged vulnerability had nowhere to be fixed and nothing at all owned thinking about the sink *before* it was written. Four modes matched to when they fire: **`model`** at plan time (the point of the skill — where untrusted data enters, where privilege changes, where data leaves, and the control at each crossing), **`harden`** while the sink is being written, **`remediate`** on a confirmed finding, **`triage`** on an advisory. **§1 anchors to OWASP Top 10:2025 and maps every category to the sink shape you can grep for**, which is what surfaced the two rows the old checklist had no equivalent of: **A03 supply chain** (unpinned actions, a build step executing a fetched script, a lockfile nobody read) and **A10 mishandling of exceptional conditions** — a `catch` that swallows an authorization failure, a permission check that fails *open*. A10 is invisible to every scanner, because fail-open code is working code until the day the thing it calls is down. Constraint 1 is the load-bearing one: **never invent an OWASP category or a CWE number** — in this domain a fabricated identifier gets quoted into a ticket by a human who trusts it, so a described weakness with no ID is correct work and a confident wrong `CWE-000` is a defect. Also: reachability before severity (which forbids both performing urgency and dodging work), no fixing by weakening, and no fix without a regression test that **fails against the unpatched code**.

### ♿ Accessibility

- **[Accessibility Architect](skills/accessibility-architect/SKILL.md)** — Interfaces that can actually be operated — by keyboard, screen reader, magnification, and imprecise pointers. The pack's thinnest coverage relative to its consequences: contrast and focus-visible in Design's craft floor, a scan and a keyboard walk in Testing §5, and an `<a11y>` gate in the profile that **no skill owned interpreting**. **§3 focus management is why this could not be folded into `design-architect`** — a focus trap with no exit, focus never returned to the trigger after a dialog closes, a client-side route change that announces nothing: each produces **zero automated violations**, because there is no violating node to find. They are unreachable from a fix-the-log workflow and have to be decided at plan time, which is what `spec` mode is for. **§1 covers WCAG 2.2's nine new criteria**, none of which the pack touched before — SC 2.5.8 target size (**24×24**, not the 44×44 that belongs to AAA), SC 2.5.7's single-pointer alternative to any drag, SC 2.4.11 focus not obscured by your own sticky header, and SC 3.3.8's ban on cognitive-function auth (which is why blocking paste into a one-time-code field is a failure). §2 is native-element-first, with the full contract a `role` obliges you to supply spelled out — six things `<button>` gives you free. Constraint 3 stops a green scan from becoming a compliance claim; **Constraint 4 requires every barrier to name who it blocks**, which is what stops a rule from being negotiated.

### 🛠️ Implementation & Quality

- **[Implementing Architect](skills/implementing-architect/SKILL.md)** — Plan-driven implementer + quality validator. Runs the profile's gates in order, then the **Change Propagation Protocols** — A shared data shape, B public API & test doubles, C external origins & configuration — which cover exactly what a green pipeline can't prove. Never auto-updates golden files. Never stages, commits, or pushes.
- **[Quality Check Script](skills/implementing-architect/check-quality.sh)** — One-shot runnable pipeline. Resolves each gate from `.claude/PROJECT-PROFILE.md` first (the authority, per Guidelines §5), then `.claude/quality-gates.conf`, then auto-detection from the manifest; a blank, `n-a`, or still-`<placeholder>` profile row falls through rather than becoming an invented command. `--list` shows what it resolved, and from where, without running anything. Surfaces visual diffs; never updates baselines.

### 🩺 Diagnosis

- **[Debugging Architect](skills/debugging-architect/SKILL.md)** — Finds the cause without spiralling. Reproduce before theorising, **narrow before hypothesising**, one falsifiable prediction per pass, and a hard **three-hypothesis ceiling** that forces a stop-and-reassess instead of a fourth guess — Guidelines §17's debug-spiral clause made binding. No speculative fixes, no fixing by weakening, probes reverted. Separate disciplines for flaky failures (prove a *rate*; never retry a race away) and unreproducible reports (ship instrumentation, not a guess). Phase 6 closes the incident→prevention loop: a gate that should have caught it gets written into the profile's blind spots.

### 🔍 Review

- **[Code Review Architect](skills/code-review-architect/SKILL.md)** — Read-only unified review of a working tree, branch diff, or PR. Merges maintainability, performance, security, correctness, and **design craft** into **one 0–100 score** with a banded verdict. Runs the static gates, a full threat model by sink category, the change-propagation audit, and a **confidence gate** that drops any finding below 80% certainty rather than padding. **Writes no code.**

### 🚀 Release

- **[Deployment Architect](skills/deployment-architect/SKILL.md)** — Takes a reviewed change set to production safely. Resolves hosting model, environments, deploy and rollback mechanisms from the profile's §Deployment; runs a readiness gate, then a **pre-flight risk pass** over the four things a green pipeline structurally cannot see — per-environment config, pre-existing data, caches that outlive the deploy, and the absence of a way back. The **rollback plan is a hard gate written before deploying**, including an honest list of what rollback does *not* undo. Post-deploy verification runs against the real environment. Never fires an irreversible action without confirmation naming the target env; never touches git, release tags included.

### 🧹 Upkeep

- **[Maintenance Architect](skills/maintenance-architect/SKILL.md)** — Dependency health and rot control, on a cadence rather than on discovery. Triages advisories by **reachability** rather than headline severity (which forbids both performing urgency and dodging work), batches upgrades so a break is attributable — one class per batch, never two majors, **never an upgrade bundled with a refactor** — with the lockfile as the rollback. The rot sweep reports what no gate reports because nothing fails: suppressions, permanently-skipped tests masquerading as coverage, unused dependencies, dead code, stale TODOs, doc drift. Deliberate non-upgrades are recorded in the profile with a revisit condition.

### 📝 Documentation & Logging

- **[Documentation Architect](skills/documentation-architect/SKILL.md)** — Writes, audits, and repairs the docs a project ships. **§1 reader-and-doc-type selection** (tutorial / how-to / reference / explanation) because mixing types is the structural failure that makes accurate docs useless; §2 ground truth — every command, path, flag, and symbol traced to a file actually read, since a fabricated code sample is *executed* by the reader; §3 the documentation floor (prerequisites before the install command, runnable language-tagged blocks, task-shaped headings, resolving links, no time estimates); §4 the refuse list of doc slop; **§5 one-home-per-fact**, because rot is a duplication failure rather than a writing one; §6 the public surface, where failure behaviour and side effects are the halves always missing; §7 an **audit mode that produces a reproducible friction log** and a banded verdict backed by evidence rather than an invented score. Release notes and migration guides live here; the changelog stays with Rolling History.
- **[Rolling History](skills/rolling-history/SKILL.md)** — Updates the project's changelog to reflect current state, then assesses whether README / architecture / deployment / API / test docs also need a surgical edit (most sessions: none). Produces a **commit brief as text only**, valid against the project's own commit convention. Never executes git.

### 🔎 Search Visibility

- **[Search Optimization Architect](skills/search-optimization-architect/SKILL.md)** — Makes a web property retrievable, extractable, and citable by AI search engines and agents. Built around **§2 the evidence ladder**, which sorts every tactic into *load-bearing* (the first HTTP response contains the content, the crawler is allowed in, position in the document, fan-out coverage, off-site presence), *plausible* (atomic answers, self-contained chunks, statistics and quotations, schema for what it actually earns), and *theater* (`llms.txt` as a ranking signal, JSON-LD as a citation lever, keyword density, one-size "AI SEO"). That ladder is the pack's §15 honesty rule applied to a market that runs on unfalsifiable claims — it deliberately demotes two tactics the industry sells as pillars, and says why with a dated, attributed **§10 evidence base**. Also: the island test and the 40–60 word atomic answer, a rendering audit run against *fetched bytes* rather than the rendered DOM, retrieval-vs-training crawl policy as two separate decisions, query fan-out mapping as the prioritization input in place of keyword volume, and **§6 a measurement protocol with a fixed prompt set, ≥7–8 runs per prompt, medians with spreads, and per-engine segmentation** — because a single-run visibility score is noise. Never projects a citation, a ranking, or a lift.

### 📣 Getting Found by People

- **[Marketing Architect](skills/marketing-architect/SKILL.md)** — Plans how a finished project gets found, tried, and kept by humans, where `search-optimization-architect` covers being found by machines. Built around **§2 the funnel floor** — positioning → the artifact → placement → response → retention — with one rule: a failure at an earlier link cannot be compensated by more volume at a later one, so a run walks the floor in order and stops at the first break, which is often *not* a channel question. That ordering is empirical rather than rhetorical: the one event study that put these factors against each other found launch outcomes dominated by a project's pre-existing baseline and the reception of the post, not by the channel or the label on it. Also: **§1 an audience table** that never assumes the project is a repo, so a trade association is as reachable as a package registry; **§3 rules of entry**, where every community is read live before it enters an output because a removed post is a bad day and a ban is the channel gone permanently; the evergreen directory layer first, because unlike a launch it does not decay; and a **dated evidence base whose most useful property is its asymmetry** — the measured findings are modest and caveated while every large exciting number in the market is vendor-reported, secondary, or folklore. Two depths as modes, not two skills: `spread` is the light default, `campaign` the heavy door that opens by saying when it is the wrong instrument. Drafts every post and publishes none; never projects a number.

---

## 🧩 Modules

Shared blocks, addressed by name, loaded by an architect when a run reaches them. Never invoked directly. A module with fewer than two citing architects does not exist — it belongs inline.

| Module | What it owns | Loaded by |
|---|---|---|
| **[module-propagation](skills/module-propagation/SKILL.md)** | Protocols **A** (shared data shape), **B** (public API & test doubles), **C** (external origins & configuration) — the mirror sites a green pipeline structurally cannot catch, plus the review-time audit and the grep-vs-semantic-site rule for moved bounds. Previously written three times, in three files that drifted. | planning · implementing · code-review · debugging · deployment · security |
| **[module-threat-model](skills/module-threat-model/SKILL.md)** | OWASP Top 10:2025 mapped to the **sink shape you can grep for**, including the two categories a pre-2025 checklist has no row for — A03 supply chain and A10 fail-open error handling. Then trust boundaries at plan time, secure construction at write time, the review sweep, reachability-first triage, and the regression targets. | security · code-review · testing · planning · implementing · maintenance |
| **[module-gate-battery](skills/module-gate-battery/SKILL.md)** | The gate order and the one-batch rule, the result table, the **green-but-lying traps** by name, the manual stop when a visual baseline fails, and an explicit list of what a green pipeline still does not prove. Holds the procedure only — the commands come from the profile. | implementing · testing · code-review · deployment · maintenance · debugging |
| **[module-craft-floor](skills/module-craft-floor/SKILL.md)** | Contrast against the *computed* background, spacing on the scale, type, depth, motion, the full state set, 24×24 targets, browser surfaces, copy, the 320–1920 range, token discipline. Judged on the built result. | design · code-review · accessibility · maintenance · search-optimization |
| **[module-operability-floor](skills/module-operability-floor/SKILL.md)** | Native-element-first, the six-part contract an ARIA role obliges you to supply, focus management (overlays, disclosure, single-page routing), live regions, and the a11y refuse list. **Almost everything in it produces zero automated violations**, which is why it is decided at plan time rather than fixed from a log. | accessibility · design · code-review · testing · planning · implementing |
| **[module-findings](skills/module-findings/SKILL.md)** | The shape of one finding (severity, category, location, consequence, fix, **owner**), the ≥80 confidence gate with its false-positive list and its severe-but-unverified bucket, severity→deduction, and banded verdicts backed by evidence rather than an invented score. | code-review · security · accessibility · documentation · search-optimization · maintenance · debugging |
| **[module-evidence](skills/module-evidence/SKILL.md)** | Never invent an identifier — an OWASP category, CWE, or WCAG criterion you are unsure of is described and left unnumbered, because that number is the part a human downstream trusts. Every figure sourced or labelled `hypothesis` / `target` / `baseline unknown`, with no third option. The dated evidence-base format, whose third column is what stops a simulator result being quoted as a field result. | security · accessibility · search-optimization · product · documentation · marketing |
| **[module-handover](skills/module-handover/SKILL.md)** | What to do when a run reaches an action it must not perform: the runbook shape, one step per command with *what it does* and *how you know it worked*, and the short forms for a commit brief, a lockfile revert, a rollback with its one-way doors named, and a ticket left as text. The handover **is** the deliverable. | deployment · security · product · rolling-history · maintenance · debugging · marketing |
| **[module-writing-floor](skills/module-writing-floor/SKILL.md)** | The floor for any document a project ships — prerequisites before the first command, runnable blocks, every identifier traced to a file actually read, task-shaped headings, resolving links, no time estimates — plus the refuse list of doc slop. | documentation · product · search-optimization · rolling-history · deployment · marketing |

**One level of composition.** A module may point at a sibling; it never instructs loading one. There is no load order to debug, and the test suite asserts it.

## 🎯 Route Commands

An architect that branches opens by picking a route — right when the direction is undecided, friction when it isn't. These 15 commands pre-select one and start there.

| Command | Architect | Route it enters |
|---|---|---|
| **`/m-skills:kickoff`** | [brainstorming-planner](skills/brainstorming-planner/SKILL.md) | Kickoff — a project that does not exist yet |
| **`/m-skills:decompose`** | [product-architect](skills/product-architect/SKILL.md) | `decompose` — vertical slices, one per implementing run |
| **`/m-skills:prd`** | [product-architect](skills/product-architect/SKILL.md) | `prd` — a durable spec |
| **`/m-skills:brief`** | [product-architect](skills/product-architect/SKILL.md) | `brief` — one page, north star and anti-goals |
| **`/m-skills:threat-model`** | [security-architect](skills/security-architect/SKILL.md) | `model` — trust boundaries at plan time, read-only |
| **`/m-skills:a11y-audit`** | [accessibility-architect](skills/accessibility-architect/SKILL.md) | `audit` — banded verdict, and what wasn't tested |
| **`/m-skills:ui-audit`** | [design-architect](skills/design-architect/SKILL.md) | Audit — brief or stamp present, craft floor + refuse list, writes nothing |
| **`/m-skills:redesign`** | [design-architect](skills/design-architect/SKILL.md) | Redesign — replace the look, keep the product truth |
| **`/m-skills:code-review-architect-uncommitted`** | [code-review-architect](skills/code-review-architect/SKILL.md) | Working tree — `git diff HEAD`, staged + unstaged, gates opt-in |
| **`/m-skills:docs-audit`** | [documentation-architect](skills/documentation-architect/SKILL.md) | Audit — friction log, `path:line`, read-only |
| **`/m-skills:release-notes`** | [documentation-architect](skills/documentation-architect/SKILL.md) | Release notes — from the changelog, never invented |
| **`/m-skills:seo-audit`** | [search-optimization-architect](skills/search-optimization-architect/SKILL.md) | Audit — tier-ordered, verified against fetched bytes |
| **`/m-skills:spread`** | [marketing-architect](skills/marketing-architect/SKILL.md) | `spread` — funnel floor, then placement; drafts only |
| **`/m-skills:advisories`** | [maintenance-architect](skills/maintenance-architect/SKILL.md) | Advisories only — triaged by reachability, batched |
| **`/m-skills:rollback`** | [deployment-architect](skills/deployment-architect/SKILL.md) | Rollback — restore first, cause last |

**A route command narrows the route, never the discipline.** It states the mode, names the one reference file to read, and closes the alternatives. It restates no constraint and duplicates no procedure — the architect is still the only copy, and every guardrail and guard still applies. One pre-applies a modifier: `code-review-architect-uncommitted` starts in `skip gates`, because a mid-work read of the working tree is not a merge gate — and it names the skipped battery in every run rather than lowering the bar quietly.

The routes without a command — `security → harden`, `a11y → spec | build`, `docs → generate`, `design → polish` — are reached by citation from planning and implementing mid-run, not typed at a prompt.

## 🔄 The Pipeline

```
Brainstorming → Planning ─┬─→ Implementing → (manual visual review) → Code Review
                          ├─→ Testing Architect  (cited at plan + implement + review)
                          ├─→ Design Architect   (cited at plan + implement + review, UI work)
                          ├─→ Security Architect (cited at plan `[SEC]` + implement + review)
                          ├─→ Accessibility Architect (cited at plan `[A11Y]` + implement + review)
                          └─→ Documentation Architect (cited at plan + review; writes what Rolling History flags)

Planning ──→ Product Architect (decompose) ──→ one Implementing run per slice
             ⬑ brief · prd · research enter here from nothing, upstream of Brainstorming
                                              ↓
                                  Rolling History → Deployment
                                  ⬑ every step cites Guidelines (Meta) ⬏

Every architect above loads modules on demand:
   propagation · threat-model · gate-battery       ← what a green pipeline cannot prove
   craft-floor · operability-floor · writing-floor ← the floors a surface cannot fall below
   findings · evidence · handover                  ← how a result is reported and handed over
```


1. **Refining an idea?** → **Brainstorming Planner**. Challenges assumptions, forces grey paths, emits a Deep-Dive Execution Prompt.
2. **Turning it into a plan?** → Paste that prompt into **Planning Architect**. Fixed-shape plan, real commands, model routing, confirmation gate.
2b. **Plan too big to ship in one go?** → **Product Architect**, `decompose`. Vertical slices, slice ceiling, INVEST, acceptance criteria — one `implementing-architect` run per slice. Its `brief` / `prd` / `research` modes are upstream instead, and say so if invoked after a plan exists.
3. **Implementing an approved plan?** → **Implementing Architect**. Gates in order, propagation protocols, stops on visual diffs. Never touches git.
4. **Designing or reworking a screen?** → **Design Architect**, alone or cited from a plan step.
5. **Adding or upgrading tests without a fresh plan?** → **Testing Architect** directly.
5b. **Untrusted input, an auth change, a secret, or an advisory?** → **Security Architect**. At plan time it maps the trust boundary; at write time it builds the sink correctly; on a finding it writes the fix *and* the regression test that fails without it. Code Review can only describe.
5c. **A modal, menu, drag, async status, or an axe log?** → **Accessibility Architect**. The accessible contract is decided with the interaction, not retrofitted — focus destination on open **and** on close is the line most often skipped, and no scanner will ever tell you.
6. **Reviewing visual diffs?** → **Manual, always.** Open the report, inspect, run the update command yourself if intended.
7. **Want a quality + security read before staging?** → **Code Review Architect**. One score, one verdict, no code written.
8. **Closing a session?** → **Rolling History**. Changelog + commit brief as text; you run the git command. When its doc-impact verdict is anything but `no change`, **Documentation Architect** writes the edit.
8b. **A doc to write, or a reader who got stuck?** → **Documentation Architect**, alone or cited. Audit mode is read-only and returns a friction log.
9. **Something broken?** → **Debugging Architect**, at any stage. Reproduce → narrow → one hypothesis at a time → regression test before the fix → guard so it cannot recur silently.
10. **Shipping it?** → **Deployment Architect**. Readiness gate, pre-flight risk pass, a rollback plan written *before* the deploy, then verification against the real environment. Nothing irreversible fires without your confirmation for that specific environment.

**Upkeep?** → **Maintenance Architect** on a cadence — weekly patches, monthly minors and a rot sweep, quarterly majors one at a time, and a reachable advisory immediately and alone.

**Public site nobody can find inside an AI answer?** → **Search Optimization Architect**. Diagnose in tier order — fetchable, allowed, content in the bytes, ranking for the fan-out set, present off-site — and stop at the first total failure. Most "why aren't we cited" questions end at step three.

**Fast feedback during implementation?** → `check-quality.sh` (see README for the exact path). Full pipeline before claiming done.

---

## 📌 Core Principles Across All Skills

1. **No Git Automation (STRICT)** — never `git add`, `git commit`, `git push`, `git checkout`, `git switch`, `--no-verify`, or any force op. Files stay **unstaged**. The user owns version control end to end, even when they say "ship it".
2. **Stay on the Active Branch** — no checkouts, switches, or branch creation.
3. **Project Conventions Win** — the committed design system, idiom, and topology outrank any default in these skills. Read a sibling file before writing a new one.
4. **Reuse Before Create** — extend what exists; cite paths.
5. **Tests Are Part of the Deliverable** — no "tests TBD". Testing Architect for the *how*.
6. **Manual Golden Review** — never auto-accept a snapshot or baseline update.
7. **Surgical Changes** — every changed line traces to a stated goal.
8. **Goal-Driven Execution** — verifiable success criteria per step.
9. **Honest Output** — every number, path, and command is one you read or ran. Placeholders beat plausible fabrications.
10. **Bounded Verification** — build → one batched inspection → one fix batch → at most one confirm round → stop.
11. **Lead With the Action** — first line is the thing to do; lists capped at 5; end with exactly one next step.
12. **Don't Ship Slop** — six-axis self-critique before emitting; the refuse list applies to every user-facing surface.
13. **Fail Closed, and Never Fix by Weakening** — every security decision denies on its error path and logs it; no fix disables a check, widens a permission, relaxes a scan rule, or weakens a test to reach green.
14. **Never Invent an Identifier** — an OWASP category, a CWE, or a WCAG success criterion you are not certain of is described in words and left unnumbered. These end up quoted in tickets, VPATs, and procurement answers by people who trust them (§15, sharpened).

---

## 🔗 Provenance

Ideas absorbed so the source plugins can stay switched off:

| Source | Where it landed |
|---|---|
| Karpathy coding observations | Guidelines Part A |
| ponytail (laziness) | Guidelines §2 — Laziness Ladder |
| caveman (terse output) | Guidelines §17 — compression half of the Reply Protocol |
| code-simplifier | Guidelines §2 — no nested ternaries, preserve behavior exactly |
| official code-review | Code Review §7 — confidence gate + false-positive filters |
| security-guidance | Code Review Phase 4 + Testing Architect §2 (TDD closes the loop) |
| [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) (MIT) | Guidelines **§17** in full — five cognitive facts, ten rules, forbidden opener/recap/closer lists, six break-the-rules cases, pre-send check. Optionally applied session-wide by a hook; never a separate command |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Design Architect §1, §3 (visitor modes, craft floor, browser surfaces), §2 and `references/palette-and-type.md` (brief before build, roles not swatches), §Constraints (brief wins, refine vs. redesign); Guidelines §16 (bounded passes) |
| Prior standalone product prompts (PRD · product brief · user story generation · market research + competitive analysis · user research script · feature deep dive) | Product Architect — the five modes; the sourcing rule in §Constraints 1–2 is a deliberate correction to their "data-backed" framing |
| Prior standalone doc prompts (generation · audit · technical reference) | Documentation Architect — §1–§3 (audience + artifact types + CommonMark and no-time-estimate rules), §6 (per-symbol reference structure), §7 (the friction log and rewrite pairs) |
| [nutlope/hallmark](https://github.com/nutlope/hallmark) | Design Architect §4–5 and `references/` (refuse list, named structures adapted from the macrostructure catalog, variety stamp, palette construction order, gate sweep, token discipline); Guidelines §15 (no invented metrics), §18 (six-axis self-critique) |

---

_Last Updated: 2026-09-06 — release history in [CHANGELOG.md](CHANGELOG.md)_
