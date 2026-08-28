#!/usr/bin/env bash
# m-skills — SessionStart bootstrap.
#
# Fires once per session. Stays completely silent unless this project is missing
# .claude/PROJECT-PROFILE.md, in which case it detects what it can mechanically and
# hands Claude a verified starting point plus instructions for the judgment rows.
#
# Silent when: the profile exists · this isn't a project directory · the user opted out.
# Never writes anything unless M_SKILLS_AUTOPROFILE=1 is set.
#
# Output contract: plain-text stdout becomes Claude's context on SessionStart. The first
# character must not be '{' or the runtime parses it as a JSON directive.

set -uo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$PROJECT" 2>/dev/null || exit 0

PROFILE=".claude/PROJECT-PROFILE.md"
OPTOUT=".claude/.m-skills-no-bootstrap"

# Fingerprint of the inputs a profile is derived from. Used by BOTH paths: the
# drift check compares it against the marker in an existing profile, and the
# draft writer stamps it so that check has something to compare against later.
# $1 is the package.json script list (may be empty).
m_skills_fingerprint() {
  printf '%s' "$(printf '%s|' "$1" \
    "$(ls package.json Makefile pyproject.toml Cargo.toml go.mod 2>/dev/null | sort | tr '\n' ' ')" \
    "$(ls CHANGELOG.md README.md docs/*.md Documentation/*.md 2>/dev/null | sort | tr '\n' ' ')" \
    "$(ls Dockerfile vercel.json netlify.toml fly.toml Procfile serverless.yml 2>/dev/null | sort | tr '\n' ' ')")" \
  | cksum | cut -d' ' -f1
}

# ── Silence conditions ────────────────────────────────────────────────────────
[ -f "$OPTOUT" ] && exit 0

# ── Profile exists: check it still tells the truth ────────────────────────────
# A stale profile is worse than a missing one, because the skills TRUST it. Three
# signals, strongest first. A date alone is not one of them: an old profile can be
# perfectly accurate and a profile written this morning can already be wrong.
if [ -f "$PROFILE" ]; then
  DRIFT=""

  # 1. CLAIM CHECK (strongest — zero false positives). Every command and path the
  #    profile names is a falsifiable claim. Verify them against the repo as it is now.
  PKG_SCRIPTS=""
  if [ -f package.json ] && command -v node >/dev/null 2>&1; then
    PKG_SCRIPTS="$(node -e "const s=require('./package.json').scripts||{};console.log(Object.keys(s).join('\n'))" 2>/dev/null)"
  fi
  # backticked tokens only — prose is not a claim
  CLAIMS="$(grep -oE '`[^`]+`' "$PROFILE" 2>/dev/null | tr -d '`' | sort -u)"
  while IFS= read -r c; do
    [ -z "$c" ] && continue
    case "$c" in
      # a named script that no longer exists in the manifest
      npm\ run\ *|pnpm\ run\ *|yarn\ run\ *|bun\ run\ *)
        sc="${c##* run }"; sc="${sc%% *}"
        [ -n "$PKG_SCRIPTS" ] && ! printf '%s\n' "$PKG_SCRIPTS" | grep -qxF -- "$sc" \
          && DRIFT="$DRIFT
  - command \`$c\` is in the profile but \`$sc\` is no longer a script in package.json"
        ;;
      # a file path that no longer resolves. Match a known extension OR a slash, so
      # bare filenames like CHANGELOG.md are checked while version strings like 3.5.0
      # are not mistaken for paths.
      *.md|*.json|*.yml|*.yaml|*.toml|*.js|*.ts|*.cjs|*.mjs|*.sh|*.conf|*.lock|*/*)
        case "$c" in *'<'*|*'*'*|*' '*|http*|*'|'*) continue ;; esac
        [ ! -e "$c" ] && DRIFT="$DRIFT
  - path \`$c\` is named in the profile but does not exist"
        ;;
    esac
  done <<EOF
$CLAIMS
EOF

  # 2. FINGERPRINT (cheap change-detection). Hash the inputs the profile was derived
  #    from. Different hash = something it depends on moved; re-verify it.
  FP_NOW="$(m_skills_fingerprint "$PKG_SCRIPTS")"
  FP_OLD="$(grep -oE '<!-- m-skills-fingerprint: [0-9]+ -->' "$PROFILE" 2>/dev/null | grep -oE '[0-9]+' | head -1)"
  if [ -n "$FP_OLD" ] && [ "$FP_OLD" != "$FP_NOW" ]; then
    DRIFT="$DRIFT
  - the manifest/docs/deploy-config fingerprint changed since the profile was written"
  fi

  # 3. Clean? Say nothing. Silence is the common case and must stay free.
  [ -z "$DRIFT" ] && exit 0

  cat <<EOF
m-skills: \`.claude/PROJECT-PROFILE.md\` makes claims that no longer match this repo.
This matters because the skills TRUST that file — a stale row silently misroutes every
decision built on it.
$DRIFT

WHAT TO DO — not now, and do not interrupt what the user asked for. At a natural pause,
mention the drift in ONE line and offer to fix just those rows. Verify against the repo
before rewriting anything; do not regenerate the whole profile, and do not touch rows
that are still correct. If a row is genuinely gone, \`n-a\` is the honest value.
Record the new fingerprint as \`<!-- m-skills-fingerprint: $FP_NOW -->\` when you edit it.
EOF
  exit 0
fi

# Is this even a project? Bail on scratch directories so the pack never nags.
IS_PROJECT=0
for marker in package.json Makefile pyproject.toml Cargo.toml go.mod composer.json mix.exs build.gradle .git; do
  [ -e "$marker" ] && IS_PROJECT=1 && break
done
[ "$IS_PROJECT" -eq 0 ] && exit 0

# Greenfield? A repo with a manifest but almost no source is a project about to start,
# not a project to analyse. It gets a different message: nothing to detect, only to decide.
SRC_COUNT=$(find . -type f \
  \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' \
     -o -name '*.py' -o -name '*.rs' -o -name '*.go' -o -name '*.java' -o -name '*.rb' -o -name '*.php' \) \
  -not -path './node_modules/*' -not -path './.git/*' -not -path './vendor/*' -not -path './dist/*' \
  -not -path './build/*' -not -path './target/*' 2>/dev/null | head -20 | wc -l)
GREENFIELD=0
[ "$SRC_COUNT" -lt 3 ] && GREENFIELD=1

# ── Mechanical detection ──────────────────────────────────────────────────────
GATES="$(bash "$PLUGIN/skills/implementing-architect/check-quality.sh" --list 2>/dev/null \
         | sed 's/^Gate resolution.*$/(resolved from this project:)/')"

PM="unknown"
[ -f package-lock.json ] && PM="npm"
[ -f pnpm-lock.yaml ]    && PM="pnpm"
[ -f yarn.lock ]         && PM="yarn"
{ [ -f bun.lockb ] || [ -f bun.lock ]; } && PM="bun"
[ -f uv.lock ]     && PM="uv"
[ -f poetry.lock ] && PM="poetry"
[ -f Cargo.lock ]  && PM="cargo"
[ -f go.sum ]      && PM="go"

DEPS=""
if [ -f package.json ] && command -v node >/dev/null 2>&1; then
  DEPS="$(node -e "const p=require('./package.json');console.log(Object.keys({...p.dependencies,...p.devDependencies}).join(' '))" 2>/dev/null)"
fi

hint() { case " $DEPS " in *" $1 "*) printf '%s ' "$2" ;; esac; }
FRAMEWORKS="$(hint @angular/core Angular; hint react React; hint vue Vue; hint svelte Svelte; hint next Next.js; hint nuxt Nuxt)"
UI="$(hint tailwindcss Tailwind; hint daisyui DaisyUI; hint @mui/material MUI; hint bootstrap Bootstrap; hint @chakra-ui/react Chakra; hint shadcn-ui shadcn)"
TESTS="$(hint jest Jest; hint vitest Vitest; hint karma Karma; hint jasmine Jasmine; hint mocha Mocha; hint @playwright/test Playwright; hint cypress Cypress; hint @testing-library/react Testing-Library; hint @axe-core/playwright axe-core)"
I18N="$(hint i18next i18next; hint @ngx-translate/core ngx-translate; hint react-i18next react-i18next; hint vue-i18n vue-i18n)"

DOCS=""
for d in CHANGELOG.md README.md ARCHITECTURE.md DEPLOYMENT.md API.md TESTS.md CONTRIBUTING.md \
         docs/CHANGELOG.md docs/ARCHITECTURE.md docs/API.md docs/TESTS.md \
         Documentation/CHANGELOG.md Documentation/ARCHITECTURE.md Documentation/API.md Documentation/TESTS.md; do
  [ -f "$d" ] && DOCS="$DOCS $d"
done
[ -z "$DOCS" ] && DOCS=" (none found at the usual paths)"

COMMIT="no commitlint config found — infer the convention from git log"
for c in commitlint.config.js commitlint.config.cjs commitlint.config.mjs commitlint.config.ts .commitlintrc .commitlintrc.json .commitlintrc.js; do
  [ -f "$c" ] && COMMIT="$c — read the enforced types and subject-case rule from it" && break
done

CI=""
[ -d .github/workflows ] && CI="$(ls .github/workflows 2>/dev/null | head -5 | tr '\n' ' ')"
[ -z "$CI" ] && CI="(no GitHub workflows — check for other CI config)"

# ── Brownfield structural signals ─────────────────────────────────────────────
# On an existing project most profile rows ARE answerable from the repo. Find the
# evidence so nobody gets asked a question the filesystem already answers.
# One helper, no eval — eval re-parses escaped parens and silently breaks the find.
find_src() {
  find . \( -path ./node_modules -o -path ./.git -o -path ./vendor -o -path ./dist \
            -o -path ./build -o -path ./target -o -path ./.next -o -path ./coverage \) -prune \
       -o "$@" -print 2>/dev/null
}

# Where do tests live, and how many are there?
TEST_FILES="$(find_src -type f \( -name '*.spec.*' -o -name '*.test.*' -o -name 'test_*.py' \
              -o -name '*_test.go' -o -name '*_spec.rb' \) | head -200)"
TEST_COUNT="$(printf '%s\n' "$TEST_FILES" | grep -c . )"
if [ "$TEST_COUNT" -gt 0 ]; then
  TEST_SAMPLE="$(printf '%s\n' "$TEST_FILES" | head -3 | tr '\n' ' ')"
  if printf '%s\n' "$TEST_FILES" | grep -qE '^\./(tests?|spec|__tests__)/'; then
    TEST_PLACEMENT="a dedicated test tree"
  else
    TEST_PLACEMENT="beside the source"
  fi
  TESTS_FOUND="$TEST_COUNT files, $TEST_PLACEMENT — e.g. $TEST_SAMPLE"
else
  TESTS_FOUND="none found — no test layer established yet"
fi

# Styling / design-token evidence
STYLE_SIGNALS=""
for f in tailwind.config.js tailwind.config.ts tailwind.config.cjs theme.ts theme.js tokens.css \
         src/styles/tokens.css src/theme.ts src/styles/theme.ts panda.config.ts unocss.config.ts; do
  [ -f "$f" ] && STYLE_SIGNALS="$STYLE_SIGNALS $f"
done
CSSVARS="$(grep -rl -e '--color' -e '--space' -e ':root' --include='*.css' --include='*.scss' \
           --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build . 2>/dev/null | head -3 | tr '\n' ' ')"
[ -n "$CSSVARS" ] && STYLE_SIGNALS="$STYLE_SIGNALS $CSSVARS"
# same file can arrive from both passes
STYLE_SIGNALS="$(printf '%s\n' $STYLE_SIGNALS | sed 's|^\./||' | sort -u | tr '\n' ' ')"
[ -z "${STYLE_SIGNALS// /}" ] && STYLE_SIGNALS="(none found — design system may be undocumented or absent)"

# How does this thing deploy? These files answer most of §Deployment.
DEPLOY_SIGNALS=""
for f in Dockerfile docker-compose.yml docker-compose.yaml vercel.json netlify.toml fly.toml \
         railway.json render.yaml Procfile app.yaml serverless.yml wrangler.toml firebase.json \
         amplify.yml captain-definition .buildpacks Chart.yaml skaffold.yaml; do
  [ -f "$f" ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS $f"
done
[ -d k8s ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS k8s/"
[ -d .platform ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS .platform/"
DEPLOY_WF="$(grep -rliE 'deploy|release|publish' .github/workflows 2>/dev/null | head -3 | tr '\n' ' ')"
[ -n "$DEPLOY_WF" ] && DEPLOY_SIGNALS="$DEPLOY_SIGNALS $DEPLOY_WF"
[ -z "$DEPLOY_SIGNALS" ] && DEPLOY_SIGNALS=" (none found — deployment may be manual or undocumented)"

# Environment contract
ENV_SIGNALS=""
for f in .env.example .env.sample .env.template env.example .env.dist; do
  [ -f "$f" ] && ENV_SIGNALS="$ENV_SIGNALS $f"
done
[ -z "$ENV_SIGNALS" ] && ENV_SIGNALS=" (no env example file — the env contract is undocumented)"

# Repo shape
SHAPE="single package"
[ -f pnpm-workspace.yaml ] && SHAPE="monorepo (pnpm workspaces)"
[ -f turbo.json ]         && SHAPE="monorepo (turbo)"
[ -f nx.json ]            && SHAPE="monorepo (nx)"
[ -f lerna.json ]         && SHAPE="monorepo (lerna)"
[ -f go.work ]            && SHAPE="monorepo (go workspaces)"
grep -q '"workspaces"' package.json 2>/dev/null && [ "$SHAPE" = "single package" ] && SHAPE="monorepo (npm/yarn workspaces)"

# In a monorepo the packages usually differ in stack and gates, so name them —
# one flat profile is wrong for most of them (Guidelines §5, Packages section).
PACKAGES=""
case "$SHAPE" in monorepo*)
  for d in packages apps libs services modules; do
    [ -d "$d" ] || continue
    for pkg in "$d"/*/; do
      [ -f "$pkg/package.json" ] || [ -f "$pkg/Cargo.toml" ] || [ -f "$pkg/go.mod" ] || continue
      PACKAGES="$PACKAGES ${pkg%/}"
    done
  done
  PACKAGES="$(printf '%s' "$PACKAGES" | tr ' ' '\n' | grep -c . 2>/dev/null || echo 0) found:$PACKAGES"
  ;;
esac

# ── Optional: write the draft ─────────────────────────────────────────────────
WROTE=""
if [ "${M_SKILLS_AUTOPROFILE:-0}" = "1" ]; then
  mkdir -p .claude
  DRAFT_PKG_SCRIPTS=""
  if [ -f package.json ] && command -v node >/dev/null 2>&1; then
    DRAFT_PKG_SCRIPTS="$(node -e "const s=require('./package.json').scripts||{};console.log(Object.keys(s).join('\n'))" 2>/dev/null)"
  fi
  FP_NOW="$(m_skills_fingerprint "$DRAFT_PKG_SCRIPTS")"
  {
    echo "# Project Profile"
    # The drift check above looks for this marker; a draft without one can never
    # report fingerprint drift. Re-record it whenever the profile is edited.
    echo "<!-- m-skills-fingerprint: $FP_NOW -->"
    echo
    echo "> Draft written by the m-skills SessionStart bootstrap on $(date +%Y-%m-%d)."
    echo "> Rows below the divider are DETECTED facts. Rows marked TODO need someone to read the code."
    echo
    echo "## Identity"
    echo
    echo "- **Package manager:** \`$PM\`"
    echo "- **Stack:** ${FRAMEWORKS:-TODO — read a source file}"
    echo "- **Project:** TODO — one line on what this is"
    echo
    echo "## Commands (detected)"
    echo
    echo '```'
    echo "$GATES"
    echo '```'
    echo
    echo "## Conventions"
    echo
    echo "- **Design system / UI vocabulary:** ${UI:-TODO — open an existing component}"
    echo "- **Test layers in use:** ${TESTS:-TODO — no test deps detected}"
    echo "- **Localized?** ${I18N:-no i18n dependency detected — confirm}"
    echo "- **Test file placement:** TODO — open one existing test"
    echo "- **Coverage bar:** TODO"
    echo
    echo "## Documentation Targets"
    echo
    echo "Found:$DOCS"
    echo
    echo "## Commit Convention"
    echo
    echo "- $COMMIT"
    echo
    echo "## Guardrails Specific to This Project"
    echo
    echo "- **Do not touch:** TODO"
    echo "- **Known blind spots:** TODO — what a green pipeline does not prove here"
    echo
    echo "## Recurring Propagation Sites"
    echo
    echo "_(empty on day one — add a line each time a change lands somewhere the gates missed)_"
  } > "$PROFILE"
  WROTE="A DRAFT has been written to $PROFILE (M_SKILLS_AUTOPROFILE=1). Verify every row; complete the TODOs."
fi

# ── Greenfield: nothing to detect, only to decide ─────────────────────────────
if [ "$GREENFIELD" -eq 1 ]; then
cat <<EOF
m-skills: this looks like a project that has not really started yet ($SRC_COUNT source files found).
No \`.claude/PROJECT-PROFILE.md\` exists, and there is very little to detect from.

What is knowable now:

- Package manager: $PM
- Gate resolution:
$GATES
- Dependency hints: ${FRAMEWORKS:-none}${UI:+, }${UI:-}${TESTS:+, }${TESTS:-}

WHAT TO DO WITH THIS — do not interrupt whatever the user actually asked for.

A greenfield profile is filled by DECIDING, not detecting, and the decisions belong to whichever
skill first needs them — never to a questionnaire up front (Guidelines §5):

- Writing the first code or tests → \`testing-architect\` / \`implementing-architect\` establish §Conventions.
- Building the first screen → \`design-architect\` runs in Establish mode and writes §Design.
- First deploy → \`deployment-architect\` writes §Deployment.
- First changelog entry → \`rolling-history\` writes §Documentation Targets and §Commit Convention.

So do NOT offer to fill the profile. Offer the conversation instead — at a natural pause, in ONE line:

  "Project looks new — want to start with /m-skills:brainstorming-planner kickoff? It works out what
   you're building and the first slice, and the setup falls out of that."

That skill's Kickoff Mode is the greenfield entry point: it establishes what is being built, routes each
foundational decision to the skill that owns it, defers the rest as \`pending\`, and ends with a plan for
the first slice. If the user would rather just start coding, that is fine too — say nothing more and let
the owning skills ask when they actually need something.
EOF
exit 0
fi

# ── Hand it to Claude ─────────────────────────────────────────────────────────
cat <<EOF
m-skills: this project has no \`.claude/PROJECT-PROFILE.md\`, so the pack's skills would
auto-detect their commands every session instead of reading them once.

Mechanically detected just now (verified from real files — safe to trust):

- Package manager: $PM
- Gate resolution:
$GATES
- Framework hints (from the manifest): ${FRAMEWORKS:-none detected}
- UI / design system hints: ${UI:-none detected}
- Test tooling hints: ${TESTS:-none detected}
- i18n hints: ${I18N:-none detected}
- Repo shape: $SHAPE${PACKAGES:+
- Workspace packages: $PACKAGES
  (each may differ in stack, gates, and deploy target — the profile needs a §Packages
   table, and skills resolve the package from the paths they touch, not from the root)}
- Docs found:$DOCS
- Commit convention: $COMMIT
- CI workflows: $CI
- Tests: $TESTS_FOUND
- Styling / token evidence:$STYLE_SIGNALS
- Deployment evidence:$DEPLOY_SIGNALS
- Env contract:$ENV_SIGNALS

$WROTE

WHAT TO DO WITH THIS — do not act on it now, and do not interrupt whatever the user
actually asked for. At a natural pause, offer in ONE line: "No PROJECT-PROFILE.md here —
want me to write one? ~2 min." Then:

- Only if they say yes: fill the template at $PLUGIN/skills/guidelines-meta/PROJECT-PROFILE.template.md
  and write it to .claude/PROJECT-PROFILE.md. Fill every row the repo can answer — the detected values
  above plus whatever the files they point at reveal. Mark a row \`pending: <when>\` ONLY when the answer
  genuinely does not exist yet (no deploy has ever happened, no UI exists); its owning skill fills it
  when that moment arrives (Guidelines §5). A row left \`pending\` because nobody opened the file is a
  defect, not a deferral.
- **This is an existing project, so investigate before you ask.** The signals above are pointers,
  not answers. Open the files they point at: a test (placement, framework, style), a component and
  a token/style file (design system), the changelog (format), the deploy config and CI workflow
  (how it ships), the env example (what config it needs). Almost every profile row is answerable
  from the repo.
- **Only then ask** — and only for what the code genuinely cannot say: intent, preferences, who
  fires a deploy, where production secrets live, the coverage bar the team wants, the rollback
  they would actually perform. Asking a question the repo already answers is a defect.
- Never invent a value to fill a row — an absent gate is \`n-a\`.
- If they decline, create .claude/.m-skills-no-bootstrap so this never asks again.
EOF
exit 0
