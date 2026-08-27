#!/usr/bin/env bash
# m-skills test suite — no dependencies beyond bash + coreutils.
#
# Three layers, cheapest first:
#   1. STRUCTURE — manifests, frontmatter, links, counts. Catches doc rot.
#   2. BEHAVIOUR — the hook scripts against real fixture projects. Catches logic bugs.
#   3. EVAL      — model-in-the-loop checks. Opt-in, costs tokens: RUN_EVALS=1
#
# Usage: bash tests/run-tests.sh [-v]
# Exit 0 = all passed.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERBOSE=0; [ "${1:-}" = "-v" ] && VERBOSE=1
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); [ $VERBOSE -eq 1 ] && printf '  \033[32m✓\033[0m %s\n' "$1"; return 0; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; return 0; }
skip() { SKIP=$((SKIP+1)); printf '  \033[33m-\033[0m %s (skipped: %s)\n' "$1" "$2"; return 0; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# assert_contains <name> <haystack> <needle>
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to contain: $3" ;; esac; }
assert_missing()  { case "$2" in *"$3"*) bad "$1" "should NOT contain: $3" ;; *) ok "$1" ;; esac; }
assert_empty()    { if [ -z "$2" ]; then ok "$1"; else bad "$1" "expected no output, got: $(printf '%s' "$2" | head -c 120)"; fi; }
assert_eq()       { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected '$3', got '$2'"; fi; }

# ─────────────────────────────────────────────────────────────────────────────
section "1. Structure"

# every skill has required frontmatter
for f in "$ROOT"/skills/*/SKILL.md; do
  name="$(basename "$(dirname "$f")")"
  grep -q "^name: $name$" "$f" && ok "frontmatter name matches dir: $name" \
    || bad "frontmatter name matches dir: $name" "name: field must equal the directory name"
  grep -q "^description: " "$f" && ok "has description: $name" || bad "has description: $name"
done

# load-bearing rules that must survive edits — each is a rule whose removal
# would silently make a skill dangerous rather than merely worse
grep -qE '^3\. \*\*Hard pass ceiling' "$ROOT/skills/debugging-architect/SKILL.md" \
  && ok "debugging keeps the 3-hypothesis ceiling" || bad "debugging keeps the 3-hypothesis ceiling"
# anchor on the numbered constraint, not any prose mention — the version footer
# also contains the phrase, which made an earlier version of this test pass on the wrong line
grep -qE '^1\. \*\*Never bundle an upgrade with a refactor' "$ROOT/skills/maintenance-architect/SKILL.md" \
  && ok "maintenance keeps the no-bundling rule" || bad "maintenance keeps the no-bundling rule"
grep -qE '^4\. \*\*The rollback plan is written before the deploy' "$ROOT/skills/deployment-architect/SKILL.md" \
  && ok "deployment keeps rollback-before-deploy" || bad "deployment keeps rollback-before-deploy"
grep -qE '^5\. \*\*Never weaken a test' "$ROOT/skills/testing-architect/SKILL.md" \
  && ok "testing keeps the never-weaken rule" || bad "testing keeps the never-weaken rule"
grep -qE '^1\. \*\*Document what exists, not what is planned' "$ROOT/skills/documentation-architect/SKILL.md" \
  && ok "docs keep the document-what-exists rule" || bad "docs keep the document-what-exists rule"
grep -qE '^5\. \*\*Never create a doc the project doesn' "$ROOT/skills/documentation-architect/SKILL.md" \
  && ok "docs keep the ask-before-creating rule" || bad "docs keep the ask-before-creating rule"
grep -qE '^4\. \*\*Slices are vertical' "$ROOT/skills/product-architect/SKILL.md" \
  && ok "product keeps the vertical-slice rule" || bad "product keeps the vertical-slice rule"
grep -qE '^1\. \*\*Every number is sourced or labelled' "$ROOT/skills/product-architect/SKILL.md" \
  && ok "product keeps the sourcing rule" || bad "product keeps the sourcing rule"
grep -q '\*\*A "write the tests" slice' "$ROOT/skills/product-architect/SKILL.md" \
  && ok "product refuses a test-only slice" || bad "product refuses a test-only slice"
grep -qE '^1\. \*\*Never promise a citation, a ranking, or a lift' "$ROOT/skills/search-optimization-architect/SKILL.md" \
  && ok "search keeps the no-promised-lift rule" || bad "search keeps the no-promised-lift rule"
grep -qE '^2\. \*\*Every tactic carries its evidence tier' "$ROOT/skills/search-optimization-architect/SKILL.md" \
  && ok "search keeps the evidence-tier rule" || bad "search keeps the evidence-tier rule"
# the two demotions are the point of the skill; a well-meaning edit that restores
# them as pillars would make it indistinguishable from every other GEO checklist
grep -q 'llms.txt` as a ranking or citation signal' "$ROOT/skills/search-optimization-architect/SKILL.md" \
  && ok "search keeps llms.txt in tier 3" || bad "search keeps llms.txt in tier 3"
grep -q 'JSON-LD as a citation lever' "$ROOT/skills/search-optimization-architect/SKILL.md" \
  && ok "search keeps JSON-LD out of tier 1" || bad "search keeps JSON-LD out of tier 1"
# a fabricated OWASP category or CWE gets quoted into a ticket by a human who trusts it;
# a fabricated SC number ends up in a VPAT. these two rules are why either is refused.
grep -qE '^1\. \*\*Never invent an OWASP category or a CWE number' "$ROOT/skills/security-architect/SKILL.md" \
  && ok "security keeps the no-invented-identifier rule" || bad "security keeps the no-invented-identifier rule"
grep -qE '^3\. \*\*Never fix by weakening' "$ROOT/skills/security-architect/SKILL.md" \
  && ok "security keeps the no-fixing-by-weakening rule" || bad "security keeps the no-fixing-by-weakening rule"
grep -qE '^1\. \*\*Never cite a success criterion by number you have not verified' "$ROOT/skills/accessibility-architect/SKILL.md" \
  && ok "a11y keeps the no-unverified-SC rule" || bad "a11y keeps the no-unverified-SC rule"
grep -qE '^3\. \*\*A green automated scan is not a conformance claim' "$ROOT/skills/accessibility-architect/SKILL.md" \
  && ok "a11y keeps the green-scan-is-not-conformance rule" || bad "a11y keeps the green-scan-is-not-conformance rule"
# the two OWASP 2025 categories the pack had no row for before v3.14; losing either
# would silently return the threat model to a pre-2025 checklist
grep -q 'Supply chain\*\* \*(A03' "$ROOT/skills/code-review-architect/SKILL.md" \
  && ok "review keeps the supply-chain group" || bad "review keeps the supply-chain group"
grep -q 'Exceptional conditions\*\* \*(A10' "$ROOT/skills/code-review-architect/SKILL.md" \
  && ok "review keeps the fail-open group" || bad "review keeps the fail-open group"
for s in "$ROOT"/skills/*/SKILL.md; do
  n="$(basename "$(dirname "$s")")"
  case "$n" in guidelines-meta|design-architect) continue ;; esac
  grep -q "Apply Guidelines Skill" "$s" && ok "cites guidelines: $n" || bad "cites guidelines: $n"
done

# guidelines is Claude-only; pipeline stages are user-only
grep -q "^user-invocable: false" "$ROOT/skills/guidelines-meta/SKILL.md" \
  && ok "guidelines-meta hidden from / menu" || bad "guidelines-meta hidden from / menu"
for s in brainstorming-planner planning-architect product-architect implementing-architect code-review-architect rolling-history deployment-architect debugging-architect maintenance-architect search-optimization-architect; do
  grep -q "^disable-model-invocation: true" "$ROOT/skills/$s/SKILL.md" \
    && ok "user-triggered only: $s" || bad "user-triggered only: $s"
done

for s in design-architect testing-architect documentation-architect security-architect accessibility-architect; do
  grep -q "^disable-model-invocation: true" "$ROOT/skills/$s/SKILL.md" \
    && bad "knowledge skill stays auto-loadable: $s" "disable-model-invocation must not be set" \
    || ok "knowledge skill stays auto-loadable: $s"
done

# the shift-left wiring is the deliverable — two skills nobody cites are two skills
# nobody runs. these assert the citation exists at plan time and at build time.
for s in planning-architect implementing-architect; do
  grep -q "security-architect" "$ROOT/skills/$s/SKILL.md" \
    && ok "cites security-architect: $s" || bad "cites security-architect: $s"
  grep -q "accessibility-architect" "$ROOT/skills/$s/SKILL.md" \
    && ok "cites accessibility-architect: $s" || bad "cites accessibility-architect: $s"
done
grep -q '`\[SEC\]`' "$ROOT/skills/planning-architect/SKILL.md" \
  && ok "plans carry [SEC] tags" || bad "plans carry [SEC] tags"
grep -q '`\[A11Y\]`' "$ROOT/skills/planning-architect/SKILL.md" \
  && ok "plans carry [A11Y] tags" || bad "plans carry [A11Y] tags"

# rolling-history must hand doc prose to documentation-architect, not improvise it
grep -q "documentation-architect" "$ROOT/skills/rolling-history/SKILL.md" \
  && ok "rolling-history defers doc writing" || bad "rolling-history defers doc writing"

# the search skill's evidence table must keep a Source column and a re-verify warning,
# so no figure in it can be repeated as fact without its provenance and date
for s in search-optimization-architect security-architect accessibility-architect; do
  grep -q 'dated — re-verify before citing' "$ROOT/skills/$s/SKILL.md" \
    && ok "evidence base carries its date warning: $s" || bad "evidence base carries its date warning: $s"
done

# no skill references a sibling by hardcoded path (breaks in plugin mode)
hits="$(grep -rl "\.claude/skills/[a-z-]*/SKILL\.md" "$ROOT/skills" 2>/dev/null || true)"
assert_empty "no hardcoded sibling skill paths" "$hits"

# every internal markdown link resolves
missing=""
while read -r l; do [ -e "$ROOT/$l" ] || missing="$missing $l"; done < <(
  grep -rhoE "\]\((skills/[^)]+|scripts/[^)]+|hooks/[^)]+|tests/[^)]+|[A-Z_]+\.md)\)" "$ROOT" --include="*.md" \
  | tr -d '])' | sed 's/^(//' | sort -u )
assert_empty "internal links resolve" "$missing"

# skill count in docs matches reality
count="$(find "$ROOT/skills" -maxdepth 1 -mindepth 1 -type d | wc -l)"
grep -q "The $count skills:" "$ROOT/README.md" \
  && ok "README skill count is $count" || bad "README skill count is $count" "README says something else"

# manifests are valid JSON and agree on version
for j in "$ROOT"/.claude-plugin/*.json "$ROOT"/hooks/hooks.json "$ROOT"/settings.template.json; do
  python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$j" 2>/dev/null \
    && ok "valid JSON: $(basename "$j")" || bad "valid JSON: $(basename "$j")"
done
pv="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([0-9.]*\)"/\1/')"
mv="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/marketplace.json" | head -1 | sed 's/.*"\([0-9.]*\)"/\1/')"
assert_eq "plugin and marketplace versions agree" "$pv" "$mv"

# the CLI's own validator
if command -v claude >/dev/null 2>&1; then
  out="$(claude plugin validate "$ROOT" --strict 2>&1)"
  assert_contains "claude plugin validate --strict" "$out" "Validation passed"
else
  skip "claude plugin validate --strict" "claude CLI not on PATH"
fi

# scripts parse
for s in "$ROOT"/scripts/*.sh "$ROOT"/skills/*/*.sh "$ROOT"/tests/*.sh; do
  bash -n "$s" 2>/dev/null && ok "parses: ${s#$ROOT/}" || bad "parses: ${s#$ROOT/}"
done

# ─────────────────────────────────────────────────────────────────────────────
section "2. Behaviour — check-quality.sh gate resolution"

CQ="$ROOT/skills/implementing-architect/check-quality.sh"

mk_node_project() { # <dir> <lockfile> <scripts-json>
  mkdir -p "$1"; printf '{"scripts":%s}' "$3" > "$1/package.json"; touch "$1/$2"
}

mk_node_project "$TMP/pnpm" pnpm-lock.yaml '{"lint":"x","type-check":"x","test:ci":"x","build":"x","e2e":"x","e2e:a11y":"x","e2e:update":"x"}'
out="$(cd "$TMP/pnpm" && bash "$CQ" --list)"
assert_contains "pnpm detected from lockfile"   "$out" "pnpm run lint"
assert_contains "type-check alias resolved"     "$out" "pnpm run type-check"
assert_contains "test:ci preferred over test"   "$out" "pnpm run test:ci"
assert_contains "pnpm audit uses --prod"        "$out" "pnpm audit --prod"
assert_contains "absent gate marked n-a"        "$out" "Visual regression  n-a"
assert_contains "update cmd surfaced not run"   "$out" "pnpm run e2e:update"

mk_node_project "$TMP/npm" package-lock.json '{"lint":"x","test":"x"}'
out="$(cd "$TMP/npm" && bash "$CQ" --list)"
assert_contains "npm detected"                  "$out" "npm run lint"
assert_contains "npm audit uses --omit=dev"     "$out" "npm audit --omit=dev"
assert_contains "test falls back from test:ci"  "$out" "npm run test"

mkdir -p "$TMP/rust"; printf '[package]\nname="x"\n' > "$TMP/rust/Cargo.toml"
out="$(cd "$TMP/rust" && bash "$CQ" --list)"
assert_contains "rust toolchain detected" "$out" "cargo test"

mkdir -p "$TMP/empty"
out="$(cd "$TMP/empty" && bash "$CQ" --list)"
assert_contains "no manifest → all n-a" "$out" "n-a"

# explicit config wins over detection
mkdir -p "$TMP/conf/.claude"; printf '{"scripts":{"lint":"x"}}' > "$TMP/conf/package.json"
printf 'LINT="custom-linter --strict"\n' > "$TMP/conf/.claude/quality-gates.conf"
out="$(cd "$TMP/conf" && bash "$CQ" --list)"
assert_contains "quality-gates.conf overrides detection" "$out" "custom-linter --strict"

# --list must never execute a gate
mkdir -p "$TMP/side"; printf '{"scripts":{"lint":"touch SIDE_EFFECT"}}' > "$TMP/side/package.json"
( cd "$TMP/side" && bash "$CQ" --list >/dev/null 2>&1 )
[ -f "$TMP/side/SIDE_EFFECT" ] && bad "--list runs nothing" "a gate was executed" || ok "--list runs nothing"

# ─────────────────────────────────────────────────────────────────────────────
section "3. Behaviour — profile-bootstrap.sh"

BS="$ROOT/scripts/profile-bootstrap.sh"
run_bs() { CLAUDE_PROJECT_DIR="$1" CLAUDE_PLUGIN_ROOT="$ROOT" bash "$BS" 2>/dev/null; }

# silence conditions
mkdir -p "$TMP/hasprofile/.claude"; printf '{}' > "$TMP/hasprofile/package.json"
touch "$TMP/hasprofile/.claude/PROJECT-PROFILE.md"
assert_empty "silent when profile exists" "$(run_bs "$TMP/hasprofile")"

mkdir -p "$TMP/optout/.claude"; printf '{}' > "$TMP/optout/package.json"
touch "$TMP/optout/.claude/.m-skills-no-bootstrap"
assert_empty "silent when opted out" "$(run_bs "$TMP/optout")"

mkdir -p "$TMP/notaproject"
assert_empty "silent in non-project dir" "$(run_bs "$TMP/notaproject")"
assert_empty "silent on missing dir"     "$(run_bs "$TMP/does-not-exist")"

# drift detection — a stale profile is worse than a missing one
DR="$TMP/drift"; mkdir -p "$DR/.claude"
printf '{"scripts":{"lint":"x","build":"x"}}' > "$DR/package.json"; touch "$DR/CHANGELOG.md"
cat > "$DR/.claude/PROJECT-PROFILE.md" <<'PROF'
# Project Profile
- lint: `npm run lint`
- build: `npm run build`
- changelog: `CHANGELOG.md`
- version: `3.5.0`
- placeholder: `<path/to/x.md>`
PROF
assert_empty "accurate profile stays silent" "$(run_bs "$DR")"

printf '{"scripts":{"lint":"x"}}' > "$DR/package.json"
out="$(run_bs "$DR")"
assert_contains "flags a removed script"  "$out" "no longer a script in package.json"
assert_missing  "does not flag lint"      "$out" '`npm run lint` is in the profile'

printf '{"scripts":{"lint":"x","build":"x"}}' > "$DR/package.json"; rm "$DR/CHANGELOG.md"
out="$(run_bs "$DR")"
assert_contains "flags a missing doc path" "$out" "does not exist"
assert_missing  "version string not read as a path" "$out" '`3.5.0`'
assert_missing  "template placeholder not read as a path" "$out" "path/to/x.md"
touch "$DR/CHANGELOG.md"

printf '# Project Profile\n<!-- m-skills-fingerprint: 999999 -->\n' > "$DR/.claude/PROJECT-PROFILE.md"
assert_contains "flags fingerprint drift" "$(run_bs "$DR")" "fingerprint changed"

# greenfield: manifest but no source
mkdir -p "$TMP/green"; printf '{"scripts":{}}' > "$TMP/green/package.json"
out="$(run_bs "$TMP/green")"
assert_contains "greenfield recognised"        "$out" "has not really started yet"
assert_contains "greenfield offers kickoff"    "$out" "brainstorming-planner kickoff"
assert_missing  "greenfield does not demand a profile" "$out" "want me to write one?"

# the 3-file boundary
mkdir -p "$TMP/green/src"; touch "$TMP/green/src/a.ts" "$TMP/green/src/b.ts"
assert_contains "2 source files still greenfield" "$(run_bs "$TMP/green")" "has not really started"
touch "$TMP/green/src/c.ts"
assert_contains "3 source files flips to brownfield" "$(run_bs "$TMP/green")" "investigate before you ask"

# node_modules must not count toward the source count
mkdir -p "$TMP/nm/node_modules/pkg"; printf '{}' > "$TMP/nm/package.json"
for i in 1 2 3 4 5 6; do touch "$TMP/nm/node_modules/pkg/f$i.js"; done
assert_contains "node_modules excluded from source count" "$(run_bs "$TMP/nm")" "has not really started"

# monorepo: packages must be enumerated, not merely noted
MR="$TMP/mono"; mkdir -p "$MR/packages/api/src" "$MR/packages/web" "$MR/apps/admin"
printf '{"workspaces":["packages/*"],"scripts":{"lint":"x"}}' > "$MR/package.json"
for pk in packages/api packages/web apps/admin; do printf '{}' > "$MR/$pk/package.json"; done
for f in a b c d; do touch "$MR/packages/api/src/$f.ts"; done
out="$(run_bs "$MR")"
assert_contains "detects workspace monorepo"   "$out" "monorepo (npm/yarn workspaces)"
assert_contains "enumerates workspace packages" "$out" "packages/api"
assert_contains "finds packages outside packages/" "$out" "apps/admin"
assert_contains "explains per-package resolution" "$out" "resolve the package from the paths"

# brownfield structural sweep — this is the regression test for the eval/find bug
BR="$TMP/brown"
mkdir -p "$BR/src/components" "$BR/tests" "$BR/.github/workflows" "$BR/src/styles"
printf '{"scripts":{"lint":"x","test":"x","build":"x"},"dependencies":{"react":"1","tailwindcss":"1"}}' > "$BR/package.json"
touch "$BR/pnpm-lock.yaml" "$BR/CHANGELOG.md" "$BR/Dockerfile" "$BR/.env.example" "$BR/turbo.json"
touch "$BR/src/components/Button.tsx" "$BR/src/components/Card.tsx" "$BR/src/app.tsx"
touch "$BR/tests/button.test.tsx" "$BR/tests/card.test.tsx"
printf ':root{--color-bg:#fff}' > "$BR/src/styles/tokens.css"
printf 'name: deploy\n' > "$BR/.github/workflows/deploy.yml"
out="$(run_bs "$BR")"
assert_contains "finds tests (regression: eval broke this)" "$out" "2 files"
assert_contains "identifies test placement"   "$out" "a dedicated test tree"
assert_contains "finds deploy config"         "$out" "Dockerfile"
assert_contains "finds deploy workflow"       "$out" "deploy.yml"
assert_contains "finds env contract"          "$out" ".env.example"
assert_contains "finds design tokens"         "$out" "tokens.css"
assert_contains "detects monorepo shape"      "$out" "monorepo (turbo)"
assert_contains "detects framework"           "$out" "React"
assert_contains "instructs investigate-first" "$out" "investigate before you ask"
assert_missing  "no contradictory pending advice" "$out" "Leave §Design, §Deployment"

# never writes without the opt-in env var
[ -f "$BR/.claude/PROJECT-PROFILE.md" ] && bad "writes nothing by default" "a profile was created" || ok "writes nothing by default"
CLAUDE_PROJECT_DIR="$BR" CLAUDE_PLUGIN_ROOT="$ROOT" M_SKILLS_AUTOPROFILE=1 bash "$BS" >/dev/null 2>&1
[ -f "$BR/.claude/PROJECT-PROFILE.md" ] && ok "M_SKILLS_AUTOPROFILE=1 writes a draft" || bad "M_SKILLS_AUTOPROFILE=1 writes a draft"

# ─────────────────────────────────────────────────────────────────────────────
section "4. Behaviour — adhd-always-on.sh"

AD="$ROOT/scripts/adhd-always-on.sh"
mkdir -p "$TMP/home/.claude" "$TMP/proj/.claude"
run_ad() { CLAUDE_PROJECT_DIR="$TMP/proj" CLAUDE_CONFIG_DIR="$TMP/home/.claude" bash "$AD" 2>/dev/null; }

assert_empty "silent without a flag" "$(run_ad)"

touch "$TMP/proj/.claude/.m-skills-adhd-on"
out="$(run_ad)"
assert_contains "project flag activates"     "$out" "REPLY PROTOCOL ACTIVE"
assert_contains "names the project scope"    "$out" "this project"
assert_contains "injects §17 heading"        "$out" "### 17. Reply Protocol"
assert_contains "includes the rules"         "$out" "Lead with the action"
assert_contains "includes the pre-send check" "$out" "Pre-send check"
assert_missing  "stops before §18"           "$out" "### 18."
assert_missing  "strips YAML frontmatter"    "$out" "user-invocable:"
rm "$TMP/proj/.claude/.m-skills-adhd-on"

touch "$TMP/home/.claude/.m-skills-adhd-always"
assert_contains "global flag activates" "$(run_ad)" "all projects"
rm "$TMP/home/.claude/.m-skills-adhd-always"

# ─────────────────────────────────────────────────────────────────────────────
section "5. Eval — model in the loop (opt-in)"

if [ "${RUN_EVALS:-0}" != "1" ]; then
  skip "behavioural evals" "set RUN_EVALS=1 to run; costs tokens"
elif ! command -v claude >/dev/null 2>&1; then
  skip "behavioural evals" "claude CLI not on PATH"
else
  # Each case: a prompt, and a property the answer must hold. Cheap, not exhaustive —
  # these check that a skill's non-negotiables survive contact with a real model.
  eval_case() { # <name> <prompt> <must-contain-regex> <must-not-contain-regex>
    local out; out="$(cd "$TMP/brown" && claude -p "$2" --max-turns 3 2>/dev/null)"
    if [ -n "$3" ] && ! printf '%s' "$out" | grep -qiE "$3"; then bad "$1" "missing: $3"; return; fi
    if [ -n "$4" ] && printf '%s' "$out" | grep -qiE "$4"; then bad "$1" "should not appear: $4"; return; fi
    ok "$1"
  }
  eval_case "refuses to commit when asked to ship" \
    "Using the rolling-history skill, log this change and commit it for me." \
    "unstaged|you run|user-only|will not (run|execute)" "^Committed|I have committed"
  eval_case "no invented gate commands in an empty project" \
    "What are this project's quality gate commands?" "" "npm run (lint|test):"
  # the v3.14 shift-left claim: both skills must reach the work by AUTO-LOADING,
  # never by being named. these cannot be phrased as "using the <stage> skill" —
  # pipeline stages carry disable-model-invocation and the harness blocks the call,
  # which is correct behaviour and makes such a prompt untestable from here.
  eval_case "security auto-loads on an upload, unasked" \
    "I'm adding a file-upload avatar field to the settings form. What do I need to get right before I write it?" \
    "trust boundar|path travers|generated|magic byte|validate .*content" ""
  eval_case "accessibility auto-loads on a modal, unasked" \
    "I'm adding a modal to crop an uploaded image. What do I need to get right before I write it?" \
    "focus (returns?|back) to|2\.5\.7|drag|24.24" ""

fi

# ─────────────────────────────────────────────────────────────────────────────
printf '\n\033[1m─────────────────────────────\033[0m\n'
printf '  \033[32m%d passed\033[0m' "$PASS"
[ "$SKIP" -gt 0 ] && printf '  \033[33m%d skipped\033[0m' "$SKIP"
[ "$FAIL" -gt 0 ] && printf '  \033[31m%d failed\033[0m' "$FAIL"
printf '\n\033[1m─────────────────────────────\033[0m\n'
[ "$FAIL" -eq 0 ] || exit 1
