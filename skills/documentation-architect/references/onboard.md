# Reference: Onboard Mode

*`documentation-architect` reference — read when the run needs it.*

## Onboard Mode — An Existing Project Meets the Pack

Triggered by `/m-skills:onboard`, or offered when this skill is invoked bare in a project with no `.claude/PROJECT-PROFILE.md` or no §Documentation Targets. The project has code and usually docs; the pack has recorded nothing about either. The run is done when `rolling-history` and every other skill can start from the profile instead of re-detecting — one sitting instead of a question per skill over the next month.

**Writes exactly two things:** `.claude/PROJECT-PROFILE.md`, and — only on a yes — a changelog. Existing docs are read, never edited (constraints 4–5). Onboard is the one run allowed to fill sections other skills own (Guidelines §5.1): it records what the repo *says*; each owner still decides what the repo cannot say.

### 0. Decide which case this is

| Found | Do |
|---|---|
| The bootstrap opened with 🚨 or ⚠️ | Raise it with the user before anything else, as it instructs, then continue. |
| Fewer than three source files | Greenfield — stop and offer `/m-skills:kickoff`. There is nothing to adopt. |
| No profile | Steps 1–5 in full. |
| A profile already exists | Keep every row that still verifies. Fix drifted rows, fill `TODO` and blank rows the repo now answers, then steps 3–5. Never regenerate a profile someone has edited. |
| Monorepo | Resolve the packages first (Guidelines §5, Monorepos) and fill §Packages before the shared rows. |

### 1. Sweep, then open what it points at

Start from the bootstrap's detection block — pointers, not answers (Guidelines §5.3). Open at least:

- the manifests and CI workflows — the commands, and the gate order CI actually runs;
- one test file — framework, placement, naming;
- one component and the token or style file, if there is a UI;
- the deploy config and the env example — hosting, environments, the config contract. Never a real `.env`: the bootstrap already named which exist and whether git tracks or ignores them;
- the auth middleware or guard layer and where data access happens, if the app has users;
- any commitlint or husky config, and `git log --oneline -50`.

### 2. Fill the profile from the template

Copy the template to `.claude/PROJECT-PROFILE.md`. Every row gets a value traced to a file you opened, or the right Guidelines §5.2 state. A `pending` row whose answer sat in an unopened file is a defect. The rows that trip people:

- **§Commands is machine-read** by `check-quality.sh` — keep the table shape, one role per row, `n-a` for an absent gate.
- **§Design** — tokens, component vocabulary, themes, palette, and type are read from what ships. The direction brief does not exist yet: `pending: next UI work (design-architect)`. No UI at all → `no — n-a the rest`.
- **§Deployment** — the mechanism rows come from the deploy config. Who fires a deploy, the rollback anyone would really perform, and recovery time are questions for step 4.
- **§Search Visibility, §Distribution** — `n-a` when the project is not a public web property or not something people need to find; otherwise `pending: first <that> work`.
- **§Guardrails** — generated dirs, vendored code, and applied migrations go under *Do not touch*. Recurring Propagation Sites stays empty.
- **§Security → Secrets come from** — the env files the bootstrap named, with their git status (`ignored`, `not ignored`, `tracked — rotation pending`). Values are never read.
- Delete §Packages in a single-package repo.
- Put `<!-- m-skills-fingerprint: <n> -->` under the title, with `<n>` from `profile-bootstrap.sh --fingerprint`, so drift detection works from the first session.

### 3. Adopt the docs that already exist

The part only this skill can do.

1. **Inventory** every doc the project ships: root `*.md`, `docs/`, `Documentation/`, ADR folders, per-package READMEs, an OpenAPI or schema file, a docs-site config (`mkdocs.yml`, `docusaurus.config.*`, `.vitepress/`).
2. **Map them to §Documentation Targets at their real paths.** `docs/system-design.md` is the Architecture row whatever it is called. A doc whose claims the code can invalidate but that fits no row gets a row of its own; one that cannot drift (a license, a code of conduct) is left out. Where `rolling-history` must mirror a format, name it in *Updated when* — `Keep a Changelog, newest first`.
3. **§Documentation Standards** from one representative doc and one exported module: markup, generator and its build command, docstring convention, diagram convention, and one quoted sentence for voice.
4. **§Commit Convention** from the enforcing config; with none, from the log, quoting the evidence — `41 of 50 subjects match type: lower-case`. A log with no pattern is `free`, not a convention you picked.
5. **The changelog.**
   - It exists → record its path and format. `rolling-history` appends from here.
   - It is missing → ask once: *"No changelog here. Create `CHANGELOG.md` with a current-state baseline so rolling-history can take over? Past history stays in git log."* On yes, write a `Current state — last synced <date>` section — what the project is today, each bullet traced to a file — and one dated entry recording the adoption. **No backfilled releases**: history rebuilt from commit subjects is a summary nobody verified. On no, write the row as `n-a — declined <date>`.
6. **One bounded truth pass.** Check the README's install and run commands against the manifest, and resolve every relative link. Contradictions go in the report as drift, with both locations; fixing them is a separate run. The full friction log is `/m-skills:docs-audit`.

### 4. Ask the residue — once, together

Gather every row only a person can answer into **one batch of at most five questions**, each naming the row it fills. Anything past five, or not needed before the next skill runs, stays `TODO`. Write the answers back before reporting.

### 5. Report

```text
Onboarded shop-api — profile written, 4 docs adopted.

Profile  38 rows from the repo · 9 n-a · 4 pending · 2 TODO
         TODO  Deployment → rollback mechanism (nobody has rolled back yet)
         TODO  Conventions → coverage bar (CI enforces none)

Docs     Changelog     CHANGELOG.md           Keep a Changelog, newest first
         README        README.md
         Architecture  docs/system-design.md
         API           openapi.yaml           generated by `pnpm run openapi` — never hand-edit
         missing       Deployment, Tests      operators have no runbook

Drift    README.md:42  `pnpm dev` — package.json has no `dev` script (it has `start`)

Next     /m-skills:rolling-history at the end of your next working session
         /m-skills:docs-audit for the full friction log
```

Cap each list at five (Guidelines §17). Say which rows came from files and which from answers — an inferred row is never reported as verified.
