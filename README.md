# m-skills — a modular Claude Code plugin

**A plugin for full-stack developers who use Claude to do their actual work.** It gives the everyday loop — brainstorm, plan, build, review, write it down — a fixed shape, so the model stops improvising the process and you stop re-typing the same instructions.

**The M is for modular.** You invoke an **architect** — one of 17 skills that own a stage of the work. The architect is a short spine: its constraints, its modes, its procedure. Everything else it might need is a **module** or a **reference file** it loads *on demand*, once it knows what this particular run is. A `decompose` run never reads the PRD sections. A design polish never reads the threat model. → [Architects and modules](#-architects-and-modules)

Two things fall out of that:

- **The always-loaded floor fell from 3,660 lines to 2,240** — a 39% cut in what gets read before the skill has decided anything, measured across V4.0's 16 architects. Narrow runs land well under the old cost: a `search-optimization-architect` technical pass is 222 lines against 332; a `design-architect` polish is 144 against 153.
- **One source of truth per rule.** The change-propagation protocol used to be written three times and the OWASP sink model three times, in files that had drifted apart. Each is now one module every architect loads, so a rule has one home instead of three copies that disagree — the bigger of the two wins. It also changes what a run reads, in both directions: a run that genuinely needs three modules reads more than the old monolith did, and gets the complete shared treatment where it used to get an abbreviated local copy. The numbers, up and down: [§ What a run actually loads](#what-a-run-actually-loads).

Nothing here is tied to a specific project. Every command, framework, and convention is resolved at runtime, so the same skills work in any repo.

### The five commands that are the whole point

Run them in order, one feature at a time. This is 90% of daily use:

| # | Feature stage | Command |
|---|---|---|
| 1 | **Brainstorm** it | `/m-skills:brainstorming-planner` |
| 2 | **Plan** it | `/m-skills:planning-architect` |
| 3 | **Implement** it | `/m-skills:implementing-architect` |
| 4 | **Code review** it | `/m-skills:code-review-architect` |
| 5 | **Document** it | `/m-skills:rolling-history` |

Then you run `git` yourself — the pack never does.

**Everything else is optional and exists for when you hit the thing it's for.** Design work, test strategy, a bug you can't find, a plan too big to ship in one go, docs that have drifted, a release, dependency upkeep — there's a skill for each, and you can ignore all of them until the day you need one. → [Which command do I want?](#which-command-do-i-want)

**Two sections get you going: [Install](#-install) and [Using it, day to day](#-using-it-day-to-day).** Everything after them is detail — read it when you need it, not now.

> **Agent asked to "set up the skills" / "install the template" in a project?** [§ Installation Task](#-installation-task-agent-instructions) is the job.
> **Want to know what each skill does?** [SKILLS_INDEX.md](SKILLS_INDEX.md).

---

## ⚡ Install

```
/plugin marketplace add matis-dev/m-skills
/plugin install m-skills@m-skills
```

That's the whole install — nothing to clone, nothing to copy. It pulls from [github.com/matis-dev/m-skills](https://github.com/matis-dev/m-skills); the full URL works in place of the shorthand, as does a local path if you're running your own fork.

Prefer the terminal? `claude plugin marketplace add matis-dev/m-skills && claude plugin install m-skills@m-skills` does the same thing, and `/plugin update m-skills` (or `claude plugin update m-skills`) picks up new versions later.

Every skill is now a command, in every project:

```
The everyday five:
/m-skills:brainstorming-planner   /m-skills:planning-architect
/m-skills:implementing-architect  /m-skills:code-review-architect
/m-skills:rolling-history

There when you need them:
/m-skills:design-architect        /m-skills:testing-architect
/m-skills:documentation-architect /m-skills:product-architect
/m-skills:debugging-architect     /m-skills:deployment-architect
/m-skills:maintenance-architect   /m-skills:security-architect
/m-skills:accessibility-architect /m-skills:search-optimization-architect
/m-skills:marketing-architect
```

Plus 14 **route commands** — `/m-skills:decompose`, `/m-skills:rollback`, `/m-skills:ui-audit` and so on — for when you already know which direction you want and don't need the architect to ask. → [§ Skipping the mode question](#skipping-the-mode-question)

They install at user scope, so they're in every project you open — no per-project copying.

**Check that it actually landed there.** The CLI prints the scope it *intended*; the record on disk is what the runtime uses, and the two can disagree if a previous install left stale state behind:

```bash
claude plugin list          # expect: Scope: user · Status: ✔ enabled
```

The symptom of a bad install is specific and confusing: **the command appears in the `/` menu and is selectable, but running it returns `Unknown command`.** That means the plugin is bound to one directory. Read the record, which is the authority:

```bash
python3 -c "import json;print(json.load(open('$HOME/.claude/plugins/installed_plugins.json'))['plugins']['m-skills@m-skills'])"
```

`"scope": "user"` with **no `projectPath`** is correct. A `projectPath` means it is local to that one project — `cd` there, remove it, and reinstall from anywhere:

```bash
cd <the projectPath it names>
claude plugin uninstall m-skills --scope local
claude plugin install m-skills@m-skills --scope user
```

Two things that are easy to lose an hour to: `uninstall` accepts `--scope` even though `--help` does not list it, and *local* scope resolves relative to your **current** directory — so the uninstall only works from inside the project it is bound to.

**There is no configuration step.** Open a project and the skills work — they read the stack from your lockfile, manifest, and CI config. The first session offers to save what it found to `.claude/PROJECT-PROFILE.md` so nothing has to be re-detected later; decline and everything still works. That file fills in gradually, a section at a time, as you actually use each skill — it is never a form to sit down and complete. → [§ Setting itself up](#-setting-itself-up)

> **Namespacing needs Claude Code ≥ 2.1.216** to autocomplete as `/m-skills:<name>`. On older versions the plugin installs and works, but the menu shows the bare `/<name>` form. `claude --version` to check.

**Only want it in one project?** Clone the repo and copy `skills/` → `<project>/.claude/skills/`, then drop the `m-skills:` prefix from every command. Worth it only when a project needs a modified copy — project skills silently override bundled ones of the same name, which the plugin route can't do. One caveat: the [route commands](#skipping-the-mode-question) resolve their architect through `${CLAUDE_PLUGIN_ROOT}`, which doesn't exist in copy mode — copying `commands/` → `<project>/.claude/commands/` gives you the right slash names, but you'll need to rewrite those paths to `.claude/skills/…` inside each file. The plugin route is the supported one.

---

## 🔄 Using it, day to day

You name a skill, it runs that one stage and stops. Nothing chains itself, and nothing touches git.

Commands below use the plugin form — in copy mode, drop the `m-skills:` prefix.

### Which command do I want?

**The everyday loop — one feature, in order.** If you only ever use these five, the pack has done its job.

| # | Situation | Command |
|---|---|---|
| 1 | Idea needs pressure-testing | `/m-skills:brainstorming-planner` → emits a Deep-Dive Execution Prompt |
| 2 | Prompt (or a request) needs a plan | `/m-skills:planning-architect` → fixed-shape plan, real commands, confirmation gate |
| 3 | Plan approved, build it | `/m-skills:implementing-architect` → gates + propagation protocols, stops on visual diffs |
| 4 | Read before staging | `/m-skills:code-review-architect` → one 0–100 score, writes no code |
| 5 | Feature done, write it down | `/m-skills:rolling-history` → changelog + commit brief as text |

**The rest — reach for one when you hit the thing it's for.** No order, no obligation.

| Situation | Command |
|---|---|
| Starting a project from nothing | `/m-skills:brainstorming-planner kickoff` → what to build, first slice, foundational decisions routed to their owners |
| Screen or component to design | `/m-skills:design-architect` → visitor mode, craft floor, refuse list |
| Tests to add or upgrade | `/m-skills:testing-architect` |
| Untrusted input, auth, secrets, or an advisory | `/m-skills:security-architect` → trust boundaries at plan time, the fix and its regression test after |
| Modal, menu, drag, async status, or an axe log | `/m-skills:accessibility-architect` → the accessible contract before it's built, WCAG 2.2 AA by default |
| Something is broken | `/m-skills:debugging-architect <symptom>` → reproduce, narrow, one hypothesis at a time, regression test before the fix |
| Plan is too big to ship in one go | `/m-skills:product-architect — decompose` → vertical slices, INVEST, acceptance criteria |
| PRD, product brief, or research plan needed | `/m-skills:product-architect — prd \| brief \| research` |
| README, guide, or API reference to write or fix | `/m-skills:documentation-architect` → reader + doc type, runnable examples, drift check |
| Ready to ship | `/m-skills:deployment-architect <env>` → runbook you paste, rollback plan first, post-deploy checks |
| Upkeep, advisories, upgrades | `/m-skills:maintenance-architect` → triaged by reachability, batched so a break is attributable |
| Site should be cited by AI search, not just ranked | `/m-skills:search-optimization-architect` → evidence-tiered audit, retrieval-shaped content, honest measurement |
| Built it, nobody knows about it | `/m-skills:marketing-architect` → positioning first, then where it goes and what that place demands |
| Fast feedback mid-work | `bash <skills>/implementing-architect/check-quality.sh` |

`guidelines-meta` is never invoked alone — every other skill opens by loading it.

### Skipping the mode question

Eight architects branch. `/m-skills:product-architect` opens by reading its mode table and working out whether this run is a decompose, a PRD, a brief, or a research plan — which is exactly what you want when the direction is undecided, and pure friction when it isn't.

**Route commands are the second door.** Each one pre-selects a route and starts there. No mode question, no modifier to type.

| Instead of | Type | Runs |
|---|---|---|
| `/m-skills:brainstorming-planner kickoff` | `/m-skills:kickoff` | greenfield — what to build, first slice, decisions routed to their owners |
| `/m-skills:product-architect — decompose` | `/m-skills:decompose` | vertical slices with acceptance criteria |
| `/m-skills:product-architect — prd` | `/m-skills:prd` | a durable spec |
| `/m-skills:product-architect — brief` | `/m-skills:brief` | one page: north star and anti-goals |
| `/m-skills:security-architect <x> — model` | `/m-skills:threat-model` | trust boundaries, read-only, before it's built |
| `/m-skills:accessibility-architect <x> — audit` | `/m-skills:a11y-audit` | WCAG 2.2 AA read with what wasn't tested stated |
| `/m-skills:design-architect <x> — audit` | `/m-skills:ui-audit` | craft floor + refuse list, `path:line`, writes nothing |
| `/m-skills:design-architect <x> — redesign` | `/m-skills:redesign` | replace the visual world, keep the product truth |
| `/m-skills:documentation-architect — audit` | `/m-skills:docs-audit` | friction log against the code, read-only |
| `/m-skills:documentation-architect — release-notes` | `/m-skills:release-notes` | user-facing notes, migration guide per break |
| `/m-skills:search-optimization-architect — audit` | `/m-skills:seo-audit` | tier-ordered, verified against fetched bytes |
| `/m-skills:marketing-architect — spread` | `/m-skills:spread` | funnel floor, then where it goes; drafts, never sends |
| `/m-skills:maintenance-architect — advisories only` | `/m-skills:advisories` | advisories triaged by reachability, batched |
| `/m-skills:deployment-architect — roll back` | `/m-skills:rollback` | restore first, resolved command, cause last |

**A route command narrows the route, never the discipline.** Constraints, guardrails, the git guards, and the pre-emit sweep all still apply — none of these is a `skip gates` modifier. The architects are unchanged and still take modifiers longhand; this is an extra door into the same room.

Routes deliberately left out: `security → harden`, `a11y → spec | build`, `docs → generate`, `design → polish`. Those are reached by *citation* from `planning-architect` and `implementing-architect` mid-run, not typed at a prompt — a command for them would sit in the menu and never be picked.

### The whole flow, in one picture

```mermaid
flowchart TD
    S1([Raw idea]):::entry --> BP
    S2([Empty repo]):::entry -- "kickoff mode" --> BP
    S3([Plan or story in hand]):::entry --> PA
    S4([Something is broken]):::entry --> DBG
    S5([Upkeep cadence]):::entry --> MNT
    S6([Brief, PRD, or research needed]):::entry -- "upstream modes" --> PROD

    subgraph PIPE["You trigger every stage &mdash; Claude never starts one"]
        BP["<b>/brainstorming-planner</b><br/>pressure-tests the idea<br/><i>out:</i> Deep-Dive Execution Prompt"]
        PA["<b>/planning-architect</b><br/>fixed-shape plan, real commands<br/><i>out:</i> plan + confirmation gate"]
        IA["<b>/implementing-architect</b><br/>gates in order + propagation protocols<br/><i>out:</i> code, left unstaged"]
        VIS["<b>Manual visual review</b><br/>you open the report, you run the update"]
        CR["<b>/code-review-architect</b><br/>one 0-100 score, writes no code<br/><i>out:</i> findings"]
        RH["<b>/rolling-history</b><br/><i>out:</i> changelog + commit brief as text"]
        GIT["<b>You run git</b><br/>stage · commit · push"]
        DEP["<b>/deployment-architect</b><br/>readiness gate, rollback plan first<br/><i>out:</i> runbook you run"]
        PROD["<b>/product-architect</b><br/>cuts the plan into shippable slices<br/><i>out:</i> INVEST slices + acceptance criteria"]

        BP --> PA --> IA --> VIS --> CR
        PA -- "too big for one session" --> PROD
        PROD -- "one slice at a time" --> IA
        CR -- "fix the findings" --> IA
        CR --> RH --> GIT --> DEP
    end

    DBG["<b>/debugging-architect</b><br/>reproduce → narrow → one hypothesis at a time<br/>regression test before the fix"]
    MNT["<b>/maintenance-architect</b><br/>advisories by reachability<br/>batched upgrades"]

    DBG -- "cause found" --> IA
    MNT -- "verify upgrade" --> IA

    PA -.-> CITE
    IA -.-> CITE
    CR -.-> CITE
    subgraph KNOW["Knowledge skills &mdash; also auto-loaded when the work is design-, test-, docs-, security-, or a11y-shaped"]
        CITE{{"cited at plan,<br/>implement, review"}}
        CITE -.-> DES["<b>/design-architect</b><br/>visitor mode · craft floor · refuse list"]
        CITE -.-> TST["<b>/testing-architect</b><br/>layers · placement · green-but-lying traps"]
        CITE -.-> DOC["<b>/documentation-architect</b><br/>reader &amp; doc type · runnable examples · drift"]
        CITE -.-> SEC["<b>/security-architect</b><br/>trust boundaries · secure sinks · the fix + its test"]
        CITE -.-> A11Y["<b>/accessibility-architect</b><br/>accessible contract · focus architecture · WCAG 2.2"]
    end

    RH -. "doc needs an edit" .-> DOC

    subgraph MODS["Modules &mdash; one home per rule, read only when a run reaches them"]
        MOD{{"9 shared modules"}}
        MOD -.-> MW["<b>propagation</b> · <b>threat-model</b> · <b>gate-battery</b><br/><i>what a green pipeline cannot prove</i>"]
        MOD -.-> MF["<b>craft-floor</b> · <b>operability-floor</b> · <b>writing-floor</b><br/><i>the floors a surface cannot fall below</i>"]
        MOD -.-> MR["<b>findings</b> · <b>evidence</b> · <b>handover</b><br/><i>how a result is reported and handed over</i>"]
    end

    PIPE -.-> MOD
    KNOW -.-> MOD

    GM["<b>guidelines-meta</b><br/>never invoked alone — every skill here opens by loading it"]
    GM -.-> PIPE

    classDef entry fill:#fef3c7,stroke:#b45309,color:#1f2937
    classDef stage fill:#dbeafe,stroke:#1d4ed8,color:#1f2937
    classDef manual fill:#fee2e2,stroke:#b91c1c,color:#1f2937
    classDef know fill:#ede9fe,stroke:#6d28d9,color:#1f2937
    classDef aside fill:#dcfce7,stroke:#15803d,color:#1f2937
    classDef meta fill:#f1f5f9,stroke:#475569,color:#1f2937
    classDef mod fill:#fff7ed,stroke:#c2410c,color:#1f2937
    class BP,PA,PROD,IA,CR,RH,DEP stage
    class VIS,GIT manual
    class DES,TST,DOC,SEC,A11Y,CITE know
    class DBG,MNT aside
    class GM meta
    class MOD,MW,MF,MR mod
    style PIPE fill:#f8fafc,stroke:#94a3b8,color:#334155
    style KNOW fill:#faf5ff,stroke:#a78bfa,color:#334155
    style MODS fill:#fffbeb,stroke:#fb923c,color:#334155
```

**Reading it:** solid arrows are steps *you* fire; dotted arrows are things loaded for you. The two red boxes are what the pack deliberately refuses to automate — **visual review** and **git** are yours, always. `debugging-architect` is entered from any stage, not only from the start, and `maintenance-architect` runs on a cadence rather than on discovery. The orange tier is the modular half: no architect carries those rules itself, and no run reads a module it does not reach.

### Or just say it in your own words

The verbose prompts you've been pasting still work verbatim — but each maps to a command plus a plain-language modifier. Modifiers are interpreted per **Guidelines §19**, so the same phrase means the same thing in every skill.

| What you used to paste | Now |
|---|---|
| "Please use /brainstorming-planner skill to help me come up with a clear instruction…" | `/m-skills:brainstorming-planner <the idea>` |
| "This is a brand-new empty project, please use /brainstorming-planner kickoff to guide the initial setup" | `/m-skills:brainstorming-planner kickoff` |
| "Here is the prompt from brainstorming, please make an implementation PLAN for it" | `/m-skills:planning-architect <prompt>` |
| "This plan is too big to ship in one go, please DECOMPOSE it into vertical slices" | `/m-skills:product-architect — decompose` |
| "PROCEED and IMPLEMENT it… but wait with the testing before I confirm" | `/m-skills:implementing-architect <plan> — tests later` |
| "Please take this story and IMPLEMENT it" | `/m-skills:implementing-architect <story>` |
| "Please FIX the findings" | `/m-skills:implementing-architect — fix the findings` |
| "CODE REVIEW of uncommitted changes… Skip testing, I just finished it in the other session" | `/m-skills:code-review-architect — skip gates` |
| "Make sure CHECK QUALITY runs green… coverage stays above 80… e2e passes" | `/m-skills:testing-architect — make gates green, hold coverage at 80` |
| "Please use /design-architect to review the UI and audit this screen against the craft floor" | `/m-skills:design-architect <target> — audit` |
| "Can you threat model this new endpoint and check for authentication or injection risks?" | `/m-skills:security-architect <feature> — model` |
| "Please fix the SQL injection vulnerability found in review and add a regression test" | `/m-skills:security-architect <finding> — remediate` |
| "Please audit this modal component to ensure it complies with WCAG 2.2 AA standards" | `/m-skills:accessibility-architect <screen> — audit` |
| "Here is the axe scan log with accessibility violations, please fix and remediate them" | `/m-skills:accessibility-architect <log> — remediate` |
| "The login API is failing with a 500 error, please REPRODUCE and DEBUG the root cause" | `/m-skills:debugging-architect <symptom>` |
| "This test is failing intermittently on CI, please investigate why it's flaky" | `/m-skills:debugging-architect <test> — flaky` |
| "We have high-severity security advisories from the package audit, please upgrade what's vulnerable" | `/m-skills:maintenance-architect — advisories only` |
| "The README setup instructions are out of date and broken, please audit the documentation" | `/m-skills:documentation-architect — audit` |
| "Please write a complete API reference with runnable examples for this module" | `/m-skills:documentation-architect <module> — reference` |
| "Please check if the release is safe for production" | `/m-skills:deployment-architect prod` — it never deploys; you get the runbook either way |
| "Production is throwing errors after the deploy, please ROLL BACK to the previous version" | `/m-skills:deployment-architect — roll back` → the resolved rollback command, for you to run |
| "Please audit our site content so AI search and answer engines can properly cite our pages" | `/m-skills:search-optimization-architect — audit` |
| "This repo is finished — where do I post it so people actually find it?" | `/m-skills:marketing-architect — spread` → it drafts the posts; you send them |
| "Run /rolling-history, skip the tests, already handled" | `/m-skills:rolling-history — skip gates` |

**The modifier contract:** a modifier narrows scope, never the honesty bar. "Skip gates" means the output says *"gates not run this session; reported green by the user"* — it never prints a ✅ nobody observed. And no phrasing unlocks git: "ship it", "commit it", "just push" all still stop at unstaged files.

---

## 🧩 Architects and modules

Three tiers. Which tier a piece of guidance belongs to is decided by one question: **does every invocation of the owning skill need it?**

| Tier | What it is | How many | Loaded |
|---|---|---|---|
| **Architects** | the skills you invoke — they own a stage of the work and carry its constraints | 17 | on invocation |
| **Modules** | a block two or more architects would otherwise each restate | 9 | when an architect names one |
| **References** | material one architect or module needs in *some* runs — a mode's procedure, an evidence table, an output template | 53 files | when the run reaches it |

A module is addressed **by name** (`module-propagation`), because a name is the only identifier that resolves identically in a plugin install and a copied one. A reference is a plain markdown file inside its architect's own directory, read with the Read tool.

**What never leaves an architect's `SKILL.md`:** its Operational Constraints, its mode table, and its before-emitting checklist. That is deliberate. This pack's own history is a record of rules that failed to bind because they were only prose the model had to be holding — which is why the strictest ones are hooks now. A constraint moved into a file that is sometimes not read is a constraint that sometimes does not apply, so constraints stay put and only reference material moves.

### The module catalog

| Module | What it owns | Architects that load it |
|---|---|---|
| `module-propagation` | Protocols A/B/C — the mirror sites a green pipeline cannot catch when shared shape, a public API, or an external origin changes | planning · implementing · code-review · debugging · deployment · security |
| `module-threat-model` | OWASP Top 10:2025 mapped to sink shapes, trust boundaries, secure construction, the review sweep, triage, regression targets | security · code-review · testing · planning · implementing · maintenance |
| `module-gate-battery` | The gate order and one-batch rule, the result table, the green-but-lying traps, the manual stop on a visual diff | implementing · testing · code-review · deployment · maintenance · debugging |
| `module-craft-floor` | Contrast, spacing, type, depth, motion, states, targets, browser surfaces, copy, responsive range, token discipline | design · code-review · accessibility · maintenance · search-optimization |
| `module-operability-floor` | Native-first construction, the ARIA contract, focus management, live regions — the half no scanner sees | accessibility · design · code-review · testing · planning · implementing |
| `module-findings` | The finding shape, the ≥80 confidence gate, the false-positive list, severities, banded verdicts | code-review · security · accessibility · documentation · search-optimization · maintenance · debugging |
| `module-evidence` | Never invent an identifier; every number sourced or labelled; the dated evidence-base format | security · accessibility · search-optimization · product · documentation · marketing |
| `module-handover` | The runbook shape, *what it does / how you know it worked*, and the short forms for commits, reverts, rollbacks | deployment · security · product · rolling-history · maintenance · debugging · marketing |
| `module-writing-floor` | The floor for any document a project ships, plus the refuse list of doc slop | documentation · product · search-optimization · rolling-history · deployment · marketing |

Modules are hidden from the `/` menu (`user-invocable: false`) — you never invoke one directly. They point at each other freely but **never load each other**: one level of composition, so there is no load order to debug.

### What a run actually loads

Measured, in lines, by adding up the files each invocation reads. Honest in both directions:

| Invocation | Before | Now |
|---|---|---|
| `search-optimization-architect` — technical pass | 332 | **222** |
| `design-architect` — polish | 153 | **144** |
| `security-architect` — model | 187 | **179** |
| `product-architect` — decompose | 216 | **225** |
| `security-architect` — remediate | 187 | **202** |
| `debugging-architect` — flaky | 209 | **266** |
| `implementing-architect` — change touching shared shape | 194 | **283** |
| `deployment-architect` — prod release | 325 | **372** |
| `code-review-architect` — diff with shared shape *and* a security sink | 318 | **636** |

The bottom rows are the honest half. They go up because the module carries the *full* treatment where the architect previously carried an abbreviated copy — `code-review-architect`'s old security pass was 62 lines against the shared model's fuller one. That run now costs more and is better; it is not a saving and is not sold as one. What is unambiguously smaller is the floor: **2,240 lines of architect spine, down from 3,660**, and no run pays for a mode it did not pick.

---

## 🔒 The non-negotiables

These hold in every skill, in every project:

1. **No git automation.** Claude runs **no git command that writes** — staging, committing, pushing, branching, tagging, merging, pulling, fetching, rebasing, stashing, `--no-verify`, force ops, all of it — and no `gh` command that publishes. Files stay unstaged, even when you say "ship it"; you get the exact command to paste. Read-only git stays fully open (`status`, `diff`, `log`, `show`, `blame`, and the listing forms), because reviewing a branch is built on it.
2. **No auto-updating golden files or visual baselines.** The diff gets surfaced with its report path; the update command is yours.
3. **Tests ship with the code.** No "tests TBD".
4. **Honest output.** Every number, path, and command is one that was read or run. A placeholder beats a plausible invention.
5. **Bounded verification.** Build → one batched inspection → one fix batch → at most one confirm round → stop.
6. **Never weaken a test to get it green.**

---

## 📦 What's in here

| Path | What it is | Goes where |
|---|---|---|
| [`LICENSE`](LICENSE) | MIT — the license this pack ships under | stays put |
| [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) | License notices for the absorbed sources | stays put |
| `.claude-plugin/plugin.json` | Plugin manifest | stays put — read on install |
| `.claude-plugin/marketplace.json` | Single-plugin marketplace catalog | stays put — read by `/plugin marketplace add` |
| `hooks/hooks.json` | Wires all eight hooks | stays put |
| `scripts/lib/hook-json.sh` | Shared hook plumbing — payload parsing, decision emitters, the opt-out check | stays put |
| `scripts/profile-bootstrap.sh` | Detects the stack when no profile exists yet | stays put |
| `scripts/adhd-always-on.sh` | Applies the reply protocol session-wide when its flag is set | stays put |
| `scripts/guard-mutations.sh` | **Denies** git mutations, golden-file updates, catastrophic `rm`/`dd` | stays put |
| `scripts/guard-outward.sh` | **Denies** a deploy, publish, migration, infra apply, or `gh` write — you get a runbook instead | stays put |
| `scripts/guard-secrets.sh` | **Denies** writes into secret-bearing files; reads and `.env.example` untouched | stays put |
| `scripts/skill-preamble.sh` | Injects the resolved gates, §9/§10/§15/§19, and the skill's composition map when a pack skill starts; resolves a route command to the architect it routes into, so the map is right and the preamble lands once | stays put |
| `scripts/warn-test-weakening.sh` | Flags a newly added `.skip` / `.only` in a test file | stays put |
| `scripts/advise-propagation.sh` | Prompts the Protocol A sweep when a shared-shape file is edited | stays put |
| `tests/run-tests.sh` | The pack's own test suite — 558 assertions, no dependencies | stays put |
| `commands/*.md` | The 14 route commands — thin pre-routed entries into one architect's mode | plugin: stays put · copy-mode: → `<project>/.claude/commands/`, paths rewritten |
| `skills/<architect>/SKILL.md` | An architect's spine — constraints, modes, procedure | plugin: stays put · copy-mode: → `<project>/.claude/skills/` |
| `skills/module-*/` | The 9 shared modules, addressed by name | same |
| `skills/*/references/*.md` | On-demand material, read via `${CLAUDE_SKILL_DIR}` | same |
| `skills/guidelines-meta/PROJECT-PROFILE.template.md` | The profile the skills fill in as you work | → `<project>/.claude/PROJECT-PROFILE.md` |
| `CLAUDE.template.md` | Always-on guards, loaded every session | → `<project>/CLAUDE.md` |
| `settings.template.json` | Permission allowlist + git denylist | → `<project>/.claude/settings.local.json` |
| `skills/implementing-architect/check-quality.sh` | Runnable gate pipeline (profile → conf → auto-detect) | ships inside `skills/` |
| `SKILLS_INDEX.md` | Architect and module catalog, pipeline diagram, provenance | reference |

The 17 architects: `guidelines-meta`, `brainstorming-planner`, `planning-architect`, `product-architect`, `design-architect`, `testing-architect`, `security-architect`, `accessibility-architect`, `implementing-architect`, `debugging-architect`, `code-review-architect`, `documentation-architect`, `rolling-history`, `deployment-architect`, `maintenance-architect`, `search-optimization-architect`, `marketing-architect`.

The 9 modules: `module-propagation`, `module-threat-model`, `module-gate-battery`, `module-craft-floor`, `module-operability-floor`, `module-findings`, `module-evidence`, `module-handover`, `module-writing-floor`.

The 14 route commands: `kickoff`, `decompose`, `prd`, `brief`, `threat-model`, `a11y-audit`, `ui-audit`, `redesign`, `docs-audit`, `release-notes`, `seo-audit`, `spread`, `advisories`, `rollback`. → [§ Skipping the mode question](#skipping-the-mode-question)

**Who invokes what** — pipeline stages are yours to trigger; knowledge skills load themselves when relevant:

| Skill | Invocation |
|---|---|
| `brainstorming-planner`, `planning-architect`, `product-architect`, `implementing-architect`, `debugging-architect`, `code-review-architect`, `rolling-history`, `deployment-architect`, `maintenance-architect`, `search-optimization-architect`, `marketing-architect` | `disable-model-invocation: true` — **you** trigger them, Claude never starts one on its own |
| `design-architect`, `testing-architect`, `documentation-architect`, `security-architect`, `accessibility-architect` | Both — you can call them, and Claude loads them when the work is design-, test-, docs-, security-, or accessibility-shaped |
| `guidelines-meta` | `user-invocable: false` — background knowledge, loaded by the other skills, hidden from the `/` menu |

---

## 🔧 Setting itself up

### The profile, filled as you go

**The profile is progressive, not a questionnaire.** It is never "finished", and a half-filled one is the normal state — most of it *cannot* be known at install time. A project with no UI has no design system; one that has never shipped has no rollback mechanism; an empty repo has no commit convention.

So each section is owned by the skill that needs it, and gets filled the first time that skill runs:

| Profile section | Owner | Filled when |
|---|---|---|
| Identity, Commands | SessionStart hook | first session — auto-detected |
| Conventions | `implementing-architect` / `testing-architect` | first code or tests |
| Design | `design-architect` | first UI work |
| Security | `security-architect` | first untrusted input, authorization, or secret |
| Accessibility | `accessibility-architect` | first interactive surface, or first a11y gate run |
| Documentation Targets, Commit Convention | `rolling-history` | first changelog entry |
| Documentation Standards | `documentation-architect` | first doc written or audited |
| Product Definition | `product-architect` | first time work is specified or sliced |
| Deployment | `deployment-architect` | first deploy, or first "is this ready?" |
| Guardrails, Propagation Sites | any skill — chiefly `debugging-architect` | whenever something is learned the hard way |
| Packages *(monorepos)* | whichever skill first works in a package | resolved from the paths being touched |

A skill fills **only its own** section, in at most 3–4 questions, and never front-loads questions for work that isn't happening yet. An unknown row is `n-a`, `TODO`, `pending: <when>`, or `assumed: <value>` — never blank and never invented.

**On a brand-new project** the hook detects that there's nothing to detect (fewer than three source files) and offers a conversation rather than a form:

> *"Project looks new — want to start with `/m-skills:brainstorming-planner kickoff`?"*

**Kickoff Mode** is the greenfield entry point. It establishes what's being built and for whom, identifies the smallest genuinely useful slice, routes each foundational decision to the skill that owns it, defers everything else as `pending`, and ends with a plan for that first slice. Setup falls out of the conversation instead of preceding it.

Five questions maximum before it starts proposing — a wrong default is cheap to change on day one, and proposing-then-being-corrected beats interrogating someone into boredom. Greenfield rows get **decided**, not discovered, and `design-architect` on a project with no interface runs in **Establish** mode: it decides the visual world rather than matching one that doesn't exist.

Declining is a first-class outcome. If you'd rather just start coding, the owning skills ask when they actually need something.

**On an established project the order is investigate → then ask.** The hook sweeps for structural evidence — repo shape, where tests live and how many, styling and design-token files, deployment config (`Dockerfile`, `vercel.json`, `fly.toml`, `k8s/`, a CI workflow named deploy…), the env contract (`.env.example`), docs, commit config — and hands Claude pointers rather than conclusions. Claude then **opens those files** and fills everything the code answers.

Only what the repo genuinely cannot say gets asked, and it's a short list: intent, who's allowed to fire a production deploy, where production secrets live, the coverage bar the team wants, the rollback they'd actually perform. **Asking about something the repo already answers is treated as a defect** — as is writing `pending` on a row whose answer was sitting in an unopened file.

| Situation | Behavior |
|---|---|
| Profile already exists **and still true** | **Silent.** No output, no cost. |
| Profile exists but has drifted | Names the specific stale rows and offers to fix only those |
| Not a project directory | **Silent.** Never nags in scratch folders. |
| `.claude/.m-skills-no-bootstrap` present | **Silent** forever. |
| Brand-new project | Says what little is knowable, then offers `brainstorming-planner kickoff` — never a questionnaire |
| Established project, no profile | Sweeps for structural evidence (~0.5s), Claude reads the files it points at, then asks only the residue |

**It does not write files by default** — it proposes, you decide. `M_SKILLS_AUTOPROFILE=1` writes a draft instead; detected rows filled, everything else marked.

> **Why `SessionStart` and not install-time:** the `Setup` hook event only fires on `claude --init` / `--maintenance`, not on `/plugin install`. `SessionStart` is what actually runs when you open a project — and it's the right place anyway, since the plugin installs once while the profile is per-project and grows over months. The `Setup` event is wired to the same script so `claude --init` works in CI.

### Monorepos

A repo with several packages usually has several *stacks*. The hook enumerates workspace packages (pnpm / turbo / nx / lerna / npm-yarn workspaces / go.work) rather than just noting that a monorepo exists, and the profile carries a §Packages table for what differs. Skills then **resolve the package from the paths they're touching**, read its rows first, and fall back to the shared rows — with a change spanning packages taking the **union** of their constraints, not the loosest. If one package requires an a11y gate, a change touching it runs that gate even though its sibling has none.

### Enforcement: the rules that are no longer advice

Prose in a skill only binds while the model has that file in context. That was fine for
judgment calls and wrong for the pack's hardest rules: `guidelines-meta` §9 (run no git
command that writes) and §10 (never auto-accept a golden update) were restated across
10 skill files and enforced **nowhere** — `settings.template.json` is a template
you copy by hand, and its prefix matching cannot see inside `cd x && git commit`, `git -C .
push`, or `bash -c "git add ."` anyway.

Six hooks close that gap. Three **guards** decide, three **advisories** inform.

| Hook | Event | Decision | Converts |
|---|---|---|---|
| `guard-mutations.sh` | `PreToolUse` · Bash | **deny** | §9 git guards, §10 golden updates, plus `rm -rf /`-class commands |
| `guard-outward.sh` | `PreToolUse` · Bash | **deny** | `deployment-architect` constraint 2 — deploy, publish, migrate, infra apply; plus `gh` writes (PRs, issues, releases, secrets) under §9 |
| `guard-secrets.sh` | `PreToolUse` · Write/Edit/NotebookEdit/Bash | **deny** | `security-architect` constraint 5 — writes into `.env`, `*.pem`, `id_rsa`, … |
| `skill-preamble.sh` | `UserPromptExpansion` + `PostToolUse` · Skill | inject | the resolved gate table and §9/§10/§15/§19, so 16 skills stop re-deriving them |
| `warn-test-weakening.sh` | `PostToolUse` · Write/Edit | advise | the never-weaken rule — a **newly added** `.skip` / `.only` in a test file |
| `advise-propagation.sh` | `PostToolUse` · Write/Edit | advise | `implementing-architect` Protocol A, once per shared-shape file per session |

Three properties are deliberate and worth knowing before you rely on them:

- **The guards fail closed; the advisories fail open.** A guard that cannot parse its input
  denies rather than waving the command through — allowing on failure is exactly the
  fail-open pattern `code-review-architect` Phase 4 flags under OWASP A10. A missed advisory
  costs nothing, so it exits quietly.
- **Reads are never blocked.** `guard-secrets.sh` denies *writes* into `.env`; `cat .env` and
  every `.env.example` variant stay open in both directions, because `guidelines-meta` §5,
  `deployment-architect` Phase 0, and `profile-bootstrap.sh` all read the env contract. A
  guard that blocked reads would break the pack itself.
- **Read-only git and `gh` stay open.** `status`, `diff`, `log`, `show`, `blame`, `rev-parse`,
  `merge-base`, and the *listing* forms of `branch` / `tag` / `remote` / `stash` are untouched, as
  are `gh pr view|list|diff|checks`, `gh issue view|list`, and `gh run view|list`. The review and
  history skills are built on them, so a guard that closed them would break the pack — the same
  asymmetry as reads on `.env`.

**Turning it off.** One flag file releases all three guards, per project or globally:

| Flag file | Scope |
|---|---|
| `.claude/.m-skills-no-guards` | This project only |
| `~/.claude/.m-skills-no-guards` | Every project |

Every denial names that file in its reason, so you never have to remember it. The advisories
respect the same flag; the preamble injection does not, since it is context rather than
enforcement.

**Dependencies.** The hook scripts need `jq` **or** `python3` — parsing a shell command out of
JSON with `sed` is how a guard gets bypassed by a quoted newline. Everything else in the pack,
`tests/run-tests.sh` included, remains bash + coreutils only.

**What deliberately stayed prose.** Hooks that cannot decide correctly are worse than no hook.
The design craft floor and refuse list judge a *rendered* result, so no script can check them.
§15 honest output cannot verify a number's provenance. Confidence gates, scoring bands, and
mode selection are judgment. And a `Stop` hook that re-runs the suite until green was rejected
outright: it is the open loop §16 forbids, and it overrides the §19 `skip gates` / `tests
later` modifiers it structurally cannot see.

### Session-wide reply protocol

`guidelines-meta` §17 (the reply protocol — lead with the action, numbered steps, one next step, cap lists at five, no preamble, plus a pre-send check) applies whenever a pack skill is running. To apply it to **everything** — ordinary questions, debugging, anything that never touches a skill — create a flag file. A second `SessionStart` hook (`scripts/adhd-always-on.sh`) then injects §17 each session. Opt-in only: no flag, silent exit, 25ms.

| Flag file | Scope |
|---|---|
| `~/.claude/.m-skills-adhd-always` | Every project |
| `.claude/.m-skills-adhd-on` | This project only |

It fires on `startup`, `resume`, **`clear`, and `compact`** — a context clear is exactly where a session-only setting lapses without you noticing, which is the working-memory tax §17 exists to remove. "Stop adhd mode" turns it off for the current session without touching the flag.

There is no `/i-have-adhd` command, deliberately: an output style is influence, not something to remember to invoke.

---

## 🎯 The design in two paragraphs

**Modular.** You invoke an architect; it works out what this run needs and reads only that. Guidance that two or more architects share is extracted into a module addressed by name, so a rule has one home instead of three copies that drift — the failure this pack kept shipping fixes for. Guidance one architect needs in only some runs becomes a reference file it reads on demand. Constraints never move: they stay in the architect's own file, because a rule that is sometimes not loaded is a rule that sometimes does not apply.

**Portable.** Skills name **roles**, never commands. Where an ordinary skill would hardcode `npm run lint`, these say `<lint>` and resolve it — from `.claude/PROJECT-PROFILE.md` if it exists, otherwise by auto-detecting from `package.json` / `Makefile` / `pyproject.toml` / `Cargo.toml` / `go.mod` / CI config. **A role with no command is `n-a`, never invented.** Same for conventions: instead of "use DaisyUI", the rule is "use the project's committed design system, read from the profile". Every concrete tool or filename that appears in a skill is explicitly labeled a disposable illustration of a category — so the pack doesn't rot into a catalogue of one codebase's details.

---

## 🚀 Installation Task (agent instructions)

**Goal:** a target project where the skills are invocable, the profile is filled with *verified* values, and the guards load every session.

### Step 1 — Get the skills in place

**Default route — install from the public repo.** Check `claude plugin list` for `m-skills` first; if it's absent, install it:

```
claude plugin marketplace add matis-dev/m-skills
claude plugin install m-skills@m-skills
```

The commands are then available as `/m-skills:<name>` in every project, and there is no `skills/` copy to make. Steps 2–5 still apply — the profile is per-project regardless.

**Fallback — copy into the project** (only when it needs a modified copy, or the machine is offline). Clone `https://github.com/matis-dev/m-skills`, then:

```
<pack>/skills/                 → <project>/.claude/skills/
<pack>/CLAUDE.template.md      → <project>/CLAUDE.md              (merge if one exists — never overwrite)
<pack>/settings.template.json  → <project>/.claude/settings.local.json  (merge if one exists)
```

`CLAUDE.md` and `settings.local.json` are copied in **both** modes — the plugin ships skills, not project guards. Get them from the clone, or from the installed plugin under `~/.claude/plugins/`.

If `<project>/CLAUDE.md` already exists, **merge**: add the guards and conventions sections, keep everything the project already documented. Same for `settings.local.json` — union the `allow` lists, keep the `deny` list.

### Step 2 — Detect the project's reality

Read, don't assume. In this order:

1. **Package manager** — from the lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock*` → bun, else npm. Non-JS: `uv.lock` / `poetry.lock` / `Cargo.toml` / `go.mod` / `Makefile`.
2. **Gate commands** — the manifest's script block, or Make targets, or the language's standard tooling.
3. **CI config** (`.github/workflows/*`) — the gates CI actually runs are the gates that matter. If CI runs something the manifest doesn't expose, CI wins.
4. **Test layers** — which frameworks are installed, and where existing tests live (beside the source? a mirrored tree?). Open one existing test and match its style.
5. **Design system** — the component library, token file, or styling convention actually in use. Open one existing component.
6. **Doc targets** — which of changelog / README / architecture / deployment / API / test docs exist, and at which paths.
7. **Commit convention** — from a commitlint/husky config if present, else infer from `git log --oneline -30`. Record the **subject case** exactly; getting this wrong makes every commit bounce.
8. **Blind spots** — what a green pipeline does *not* prove here (e.g. type-check not covering template/markup bindings; visual baselines passing for a consistently-broken resource).

### Step 3 — Write the profile

Fill `<project>/.claude/PROJECT-PROFILE.md` from the template. Rules:

- **Only values you verified.** A command you didn't find in a real file does not go in the file.
- **Absent gate → `n-a`.** Do not invent a script name to fill a row.
- **Leave "Recurring Propagation Sites" empty** on day one. It gets one line each time a change lands somewhere the gates didn't catch — after a month it's the most valuable section in the file.

### Step 4 — Verify

1. Run `check-quality.sh --list` — prints what it resolved, runs nothing. Every row should match the profile or read `n-a`.
   - plugin mode: `bash ${CLAUDE_PLUGIN_ROOT}/skills/implementing-architect/check-quality.sh --list`
   - copy mode: `bash .claude/skills/implementing-architect/check-quality.sh --list`
2. Run one cheap gate (usually `<lint>`) to confirm the command is real.
3. Confirm the skills are discoverable — copy mode: each `SKILL.md` has `name` + `description` frontmatter at `.claude/skills/<name>/SKILL.md`. Plugin mode: `claude plugin list` shows `m-skills` enabled **at user scope**, and `installed_plugins.json` carries no `projectPath` for it (see [§ Install](#-install)). A plugin bound to one directory looks installed everywhere and dispatches nowhere else.
4. Invoke one skill and confirm the preamble hook fired — the injected block names the modules and reference files that skill composes from. No block means the hooks are not loading, whatever `plugin list` says.

### Step 5 — Report

State: files written, gates resolved (with commands), gates marked `n-a` and why, anything you could not determine and need the user to confirm. Do not claim a gate works if you didn't run it.

### Guards during installation

- **Never run `git add`, `git commit`, `git push`, `git checkout`, `git switch`, `git tag`, or any force op.** Leave everything unstaged. This holds for the install itself.
- **Never overwrite an existing `CLAUDE.md` or `settings.local.json`** — merge.
- **Never install a dependency** as part of setup.
- **Never fabricate** a command, path, or convention to make the profile look complete.

---

## 📝 Copy-paste prompt

Hand this to an agent in the project you want set up — it needs nothing else, not even a clone:

```
Install the m-skills pack into this project.

1. If `claude plugin list` doesn't show m-skills, install it from the public repo:
     claude plugin marketplace add matis-dev/m-skills
     claude plugin install m-skills@m-skills
   Only copy `skills/` → `.claude/skills/` instead if I've said I want a project-local
   modified copy.
2. Either way, merge `CLAUDE.template.md` into `./CLAUDE.md` and `settings.template.json` into
   `.claude/settings.local.json` — never overwrite what's already there. Both files ship with
   the plugin (`~/.claude/plugins/`) as well as in the repo.
3. Detect this project's real stack: package manager from the lockfile, gate commands from the
   manifest and CI config, test layers and file placement from an existing test, design system from
   an existing component, doc paths by looking, commit convention from the commitlint config or
   `git log`. Read, don't assume.
4. Write `.claude/PROJECT-PROFILE.md` from
   `skills/guidelines-meta/PROJECT-PROFILE.template.md` using only values you verified.
   A gate that doesn't exist is `n-a` — do not invent script names.
5. Verify with `check-quality.sh --list`, then run the lint gate once to prove it's real.
6. If you installed the plugin, confirm `claude plugin list` shows it at **user** scope and that
   `~/.claude/plugins/installed_plugins.json` has no `projectPath` for it — a local-scope install
   shows in the `/` menu and then fails with `Unknown command` in every other project.
7. Report what you wrote, what resolved, what's `n-a`, and what you need me to confirm.

Do not run any git command that mutates state. Leave everything unstaged.
```

---

## 🧪 Testing the pack itself

```
bash tests/run-tests.sh        # 558 assertions, ~10s, no dependencies
bash tests/run-tests.sh -v     # show every passing assertion
RUN_EVALS=1 bash tests/run-tests.sh   # adds model-in-the-loop checks (costs tokens)
```

Three layers, cheapest first:

1. **Structure** — frontmatter matches directory names, invocation flags are what they should be, no skill references a sibling by hardcoded path, every internal link resolves, doc counts match reality, manifests are valid JSON and agree on version, `claude plugin validate --strict` passes. Plus the module tier's own invariants: every cited module and reference file exists, every module has at least two citers, no module loads another, and **each module's content appears in exactly one file** — the assertion that stops a deleted duplicate from being pasted back.
2. **Behaviour** — the scripts against real fixture projects: gate resolution across pnpm/npm/Rust/empty, config-overrides-detection, `--list` executing nothing, all four silence conditions, the greenfield/brownfield boundary, `node_modules` exclusion, the structural sweep, drift detection and its false-positive guards, §17 extraction boundaries.
3. **Eval** — opt-in, model-in-the-loop. Checks that a skill's non-negotiables survive contact with a real model (asked to "commit it for me", does it still refuse?). `claude plugin eval` will replace this layer once it's generally available; it isn't in 2.1.158.

The suite is **mutation-tested** — reintroducing the `eval`/`find` bug, the wrong pnpm audit flag, dropping a `disable-model-invocation` flag, restoring a module's text into an architect, or deleting a load-bearing rule (the 3-hypothesis ceiling, rollback-before-deploy, never-weaken-a-test, no-upgrade-with-refactor) each make it fail. A suite that can't fail is decoration.

That last group exists because those four rules are the ones whose removal makes a skill *dangerous* rather than merely worse, and prose has no compiler. An earlier version of that check passed on the version footer instead of the actual constraint — so each is now anchored to its numbered line.

---

## 🔗 What this pack absorbed, and from where

**Everything here is influence, not inventory.** No source ships as a separate command — each is folded into the skill that had the gap, so the surface stays at nine skills no matter how many sources get absorbed. Every source is credited with its real link and its actual license.

The point of absorbing rather than stacking: these sources cover blind spots in the pipeline skills. A planning skill has no opinion about contrast ratios; a review skill has no opinion about how its own findings should be shaped. Folding the answer into `guidelines-meta` or `design-architect` means every skill inherits it without anyone invoking anything.

| Source | License | Folded into | What was taken |
|---|---|---|---|
| **[Andrej Karpathy — notes on agent coding](https://x.com/karpathy/status/2015883857489522876)** | n/a — public post | `guidelines-meta` **Part A** | The four behavioral rules: surface assumptions before coding, minimum code that solves the problem, surgical edits only, and give success criteria rather than instructions. |
| **[ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)** | MIT | `guidelines-meta` **§17** (+ optional session-wide hook) | The whole ruleset: five cognitive facts, ten rules, the forbidden opener/recap/closer lists, six break-the-rules cases, and the pre-send check. |
| **[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)** | none declared | `guidelines-meta` **§17** | The compression half of the reply protocol — drop filler, hedging, and pleasantries while leaving code, commits, and security warnings uncompressed. |
| **[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)** | MIT | `guidelines-meta` **§2** | The Laziness Ladder — does it need to exist at all → stdlib → native/framework → installed dependency → one clear line → only then new code. |
| **[`code-simplifier` agent, anthropics/claude-code](https://github.com/anthropics/claude-code/blob/main/plugins/pr-review-toolkit/agents/code-simplifier.md)** | none declared | `guidelines-meta` **§2** | No nested ternaries; preserve behavior exactly when simplifying — change how, never what; don't trade debuggability for fewer lines. |
| **[pbakaus/impeccable](https://github.com/pbakaus/impeccable)** | Apache 2.0 | [`design-architect`](skills/design-architect/SKILL.md) §1–2 · `guidelines-meta` **§16** | Visitor modes (Persuade / Operate / Read / Experience), the craft floor, the browser-surfaces insight, brief-wins, refinement-vs-redesign, and "verify in bounded passes, not a loop". |
| **[nutlope/hallmark](https://github.com/nutlope/hallmark)** | MIT | [`design-architect`](skills/design-architect/SKILL.md) §3–5 · `guidelines-meta` **§15, §18** | The refuse list and slop gates, structural-fingerprint variety, token discipline, redrawn-chrome and glyph-icon tells, "no invented metrics", and the six-axis pre-emit self-critique. |
| **[`code-review` plugin, anthropics/claude-code](https://github.com/anthropics/claude-code/tree/main/plugins/code-review)** | none declared | [`code-review-architect`](skills/code-review-architect/SKILL.md) §7 | The confidence gate — post only findings you'd rate ≥ 80, plus the explicit false-positive filter list. |
| **[`security-guidance` plugin, anthropics/claude-code](https://github.com/anthropics/claude-code/tree/main/plugins/security-guidance)** | none declared | [`code-review-architect`](skills/code-review-architect/SKILL.md) Phase 4 · [`testing-architect`](skills/testing-architect/SKILL.md) §2 | The threat model by sink category — injection, unsafe deserialization, insecure DOM APIs — plus the loop-closer: every finding becomes a failing-first regression test. |

The two design sources overlap deliberately — impeccable is stronger on *what to verify on the built result*, hallmark on *what to refuse before you build it*. Both are distilled to rules about the rendered output, so they apply on any stack rather than only the one they shipped for.

**On the licenses:** `caveman` and the Anthropic plugins carry no declared SPDX license, so what's absorbed from them is the *idea* — restated in this pack's own words — not copied text. The MIT and Apache sources permit reuse and are credited accordingly; `i-have-adhd` is the one whose structure is followed closely, and it's MIT. The notices those licenses require are in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md); this pack itself is [MIT](LICENSE).

### If you ever want a source's full surface

Any of these installs standalone and coexists with this plugin — namespacing keeps commands distinct. Worth it only when you want their *tooling*, not their judgment: impeccable ships 23 sub-commands, a 59-rule deterministic detector, and live browser iteration; hallmark ships 21 themes and a study/DNA-extraction workflow; `security-guidance` runs real-time pattern matching on every edit, which no amount of written guidance replicates. What's absorbed here is the judgment. `i-have-adhd` is the one never worth installing alongside — §17 is already its full ruleset, so you'd just get it twice.
