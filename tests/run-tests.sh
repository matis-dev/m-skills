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
grep -qE '^3\. \*\*Never weaken a test' "$ROOT/skills/testing-architect/SKILL.md" \
  && ok "testing keeps the never-weaken rule" || bad "testing keeps the never-weaken rule"
grep -qE '^1\. \*\*Document what exists, not what is planned' "$ROOT/skills/documentation-architect/SKILL.md" \
  && ok "docs keep the document-what-exists rule" || bad "docs keep the document-what-exists rule"
grep -qE '^5\. \*\*Never create a doc the project doesn' "$ROOT/skills/documentation-architect/SKILL.md" \
  && ok "docs keep the ask-before-creating rule" || bad "docs keep the ask-before-creating rule"
grep -qE '^4\. \*\*Slices are vertical' "$ROOT/skills/product-architect/SKILL.md" \
  && ok "product keeps the vertical-slice rule" || bad "product keeps the vertical-slice rule"
grep -qE '^1\. \*\*Every number is sourced or labelled' "$ROOT/skills/product-architect/SKILL.md" \
  && ok "product keeps the sourcing rule" || bad "product keeps the sourcing rule"
grep -rq '\*\*A "write the tests" slice' "$ROOT/skills/product-architect/" \
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
grep -rq 'Supply chain\*\* \*(A03' "$ROOT/skills/module-threat-model/" \
  && ok "threat model keeps the supply-chain group" || bad "threat model keeps the supply-chain group"
grep -rq 'Exceptional conditions\*\* \*(A10' "$ROOT/skills/module-threat-model/" \
  && ok "threat model keeps the fail-open group" || bad "threat model keeps the fail-open group"
for s in "$ROOT"/skills/*/SKILL.md; do
  n="$(basename "$(dirname "$s")")"
  case "$n" in guidelines-meta|design-architect|module-*) continue ;; esac
  grep -q "Apply Guidelines Skill" "$s" && ok "cites guidelines: $n" || bad "cites guidelines: $n"
done

# guidelines is Claude-only; pipeline stages are user-only
grep -q "^user-invocable: false" "$ROOT/skills/guidelines-meta/SKILL.md" \
  && ok "guidelines-meta hidden from / menu" || bad "guidelines-meta hidden from / menu"
for s in brainstorming-planner planning-architect product-architect implementing-architect code-review-architect rolling-history deployment-architect debugging-architect maintenance-architect search-optimization-architect marketing-architect; do
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
  grep -rq 'dated — re-verify before citing' "$ROOT/skills/$s/" \
    && ok "evidence base carries its date warning: $s" || bad "evidence base carries its date warning: $s"
done

# ── modules: the shared tier ────────────────────────────────────────────────
# A module is a block two or more architects would otherwise each restate. The
# assertions below encode what makes one legitimate: it is addressed by NAME (the
# only identifier that resolves in both plugin and copy installs), it is invocable
# by the model (a module nothing can load is a file nothing reads), it is hidden
# from the / menu, it has at least two citers, and its content exists in exactly
# one place under skills/.
for m in "$ROOT"/skills/module-*/; do
  n="$(basename "$m")"
  grep -q "^user-invocable: false" "$m/SKILL.md" \
    && ok "module hidden from / menu: $n" || bad "module hidden from / menu: $n"
  grep -q "^disable-model-invocation: true" "$m/SKILL.md" \
    && bad "module stays model-invocable: $n" "a module nothing can load is a file nothing reads" \
    || ok "module stays model-invocable: $n"
  grep -q "^\*\*Loaded by:\*\*" "$m/SKILL.md" \
    && ok "module names its citers: $n" || bad "module names its citers: $n"
  # cited by two or more architects — a single-citer module belongs inline
  citers="$(grep -rl "\`$n\`" "$ROOT"/skills/*/SKILL.md | grep -v "/$n/SKILL.md" | wc -l)"
  [ "$citers" -ge 2 ] \
    && ok "module has >=2 citers: $n ($citers)" \
    || bad "module has >=2 citers: $n" "found $citers — inline it instead"
  # one level of composition only. A module may POINT at a sibling ("handled in
  # module-x") — that is a cross-reference. It may not INSTRUCT loading one, which
  # is what turns the tier into a chain with a load order nobody can debug.
  chain="$(grep -oE "load the \`module-[a-z-]+\`" "$m/SKILL.md" | sort -u | tr '\n' ' ')"
  [ -z "$chain" ] && ok "module loads no other module: $n" \
    || bad "module loads no other module: $n" "loads: $chain"
done

# every module named in a skill file exists on disk
missing_mod=""
for n in $(grep -rhoE "module-[a-z-]+" "$ROOT"/skills/*/SKILL.md | sort -u); do
  [ -f "$ROOT/skills/$n/SKILL.md" ] || missing_mod="$missing_mod $n"
done
assert_empty "every cited module exists" "$missing_mod"

# a module's content lives in exactly one file — this is the whole point of the
# tier, and re-pasting a block back into an architect is the regression it guards
dupes=""
while read -r phrase; do
  [ -z "$phrase" ] && continue
  hits="$(grep -rl "$phrase" "$ROOT"/skills/ | wc -l)"
  [ "$hits" -eq 1 ] || dupes="$dupes [$phrase x$hits]"
done <<'ANCHORS'
Parallel subsystems
Spy/mock object name lists
semantic site list
falls through to the default branch
Fake timers vs. subscriptions born outside them
button text within a hair of its own fill
roving-tabindex pattern
trains the reader to ignore the whole thing
Describe the weakness or barrier precisely
Someone pasting a command they do not understand
blame them when they fail
Validate at the boundary, encode at the sink
prototype-polluting keys
ANCHORS
assert_empty "module-owned blocks appear in exactly one file" "$dupes"

# every references/ file a skill cites must exist
missing_ref=""
while read -r r; do
  [ -z "$r" ] && continue
  found=0
  for d in "$ROOT"/skills/*/; do [ -f "$d$r" ] && found=1; done
  [ $found -eq 1 ] || missing_ref="$missing_ref $r"
done < <(grep -rhoE 'references/[a-z0-9-]+\.md' "$ROOT"/skills/*/SKILL.md | sort -u)
assert_empty "every cited reference file exists" "$missing_ref"

# no skill references a sibling by hardcoded path (breaks in plugin mode)
hits="$(grep -rl "\.claude/skills/[a-z-]*/SKILL\.md" "$ROOT/skills" 2>/dev/null || true)"
assert_empty "no hardcoded sibling skill paths" "$hits"

# every internal markdown link resolves
missing=""
while read -r l; do [ -e "$ROOT/$l" ] || missing="$missing $l"; done < <(
  grep -rhoE "\]\((skills/[^)]+|scripts/[^)]+|hooks/[^)]+|tests/[^)]+|[A-Z_]+\.md)\)" "$ROOT" --include="*.md" \
  | tr -d '])' | sed 's/^(//' | sort -u )
assert_empty "internal links resolve" "$missing"

# architect and module counts in docs match reality
acount="$(find "$ROOT/skills" -maxdepth 1 -mindepth 1 -type d ! -name 'module-*' | wc -l)"
mcount="$(find "$ROOT/skills" -maxdepth 1 -mindepth 1 -type d -name 'module-*' | wc -l)"
grep -q "The $acount architects:" "$ROOT/README.md" \
  && ok "README architect count is $acount" || bad "README architect count is $acount" "README says something else"
grep -q "The $mcount modules:" "$ROOT/README.md" \
  && ok "README module count is $mcount" || bad "README module count is $mcount" "README says something else"

# ─── Route commands ──────────────────────────────────────────────────────────
# A route command is a thin pre-routed entry into ONE architect's mode. Everything
# below guards the same failure: a command that survives a rename of the thing it
# routes into, and silently sends the run somewhere that no longer exists.
#
# The declaration line is the contract, and it is load-bearing twice over — these
# tests parse it, and so does skill-preamble.sh, which resolves the owner from the
# command file to map the composition and mark the preamble once instead of twice.
ccount=0
for f in "$ROOT"/commands/*.md; do
  [ -e "$f" ] || continue
  ccount=$((ccount+1))
  c="$(basename "$f" .md)"

  grep -q "^description: " "$f" && ok "command has description: $c" || bad "command has description: $c"
  grep -q "^argument-hint: " "$f" && ok "command has argument-hint: $c" || bad "command has argument-hint: $c"

  # a command filename must not collide with a skill directory — both surface as
  # /m-skills:<name>, and the loser of that collision is undefined
  [ -d "$ROOT/skills/$c" ] \
    && bad "command name does not collide with a skill: $c" "skills/$c/ exists" \
    || ok "command name does not collide with a skill: $c"

  # exactly one owner, named as skills/<owner>/SKILL.md, and it must resolve
  owners="$(grep -ohE 'skills/[a-z0-9-]+/SKILL\.md' "$f" | sed 's|skills/||;s|/SKILL.md||' | sort -u)"
  n="$(printf '%s\n' "$owners" | grep -c .)"
  if [ "$n" != "1" ]; then
    bad "command names exactly one owner: $c" "found ${n}: $(printf '%s' "$owners" | tr '\n' ' ')"
    continue
  fi
  owner="$owners"
  if [ ! -f "$ROOT/skills/$owner/SKILL.md" ]; then
    bad "command owner resolves: $c" "no skills/$owner/SKILL.md"
    continue
  fi
  ok "command owner resolves: $c → $owner"

  # the declaration line: `Run \`<owner>\` in **<route>** mode.` The owner it names
  # in prose must be the same one its Read path points at, or the two drift apart
  # and the hook resolves an architect the body never actually reads.
  decl="$(grep -m1 -oE '^Run `[a-z0-9-]+` in \*\*[^*]+\*\* mode' "$f" || true)"
  if [ -z "$decl" ]; then
    bad "command declares its route: $c" "no 'Run \`<owner>\` in **<route>** mode' line"
    continue
  fi
  downer="$(printf '%s' "$decl" | sed -E 's/^Run `([a-z0-9-]+)`.*/\1/')"
  assert_eq "command's declared owner matches its Read path: $c" "$downer" "$owner"

  # the route must still exist in the architect. Renaming a mode now fails the
  # build instead of orphaning a command that points at a section nobody kept.
  route="$(printf '%s' "$decl" | sed -E 's/.*\*\*(.+)\*\* mode$/\1/')"
  grep -qiF "$route" "$ROOT/skills/$owner/SKILL.md" \
    && ok "command's route exists in $owner: $route" \
    || bad "command's route exists in $owner: $route" "'$route' appears nowhere in skills/$owner/SKILL.md"

  # every reference file a command cites must live under ITS owner. Same class of
  # bug as the composition-map check further down: a path that resolves in some
  # other skill's directory is still a path this run cannot read.
  for r in $(grep -ohE 'references/[a-z0-9-]+\.md' "$f" | sort -u); do
    if [ -f "$ROOT/skills/$owner/$r" ]; then
      ok "command cites a reference that exists: $c → $r"
      continue
    fi
    # a module's reference is legitimate too — the command says which module to
    # load first — but it still has to exist somewhere in the pack.
    found=""
    for d in "$ROOT"/skills/*/; do
      [ -f "$d$r" ] || continue
      found="$(basename "${d%/}")"; break
    done
    [ -n "$found" ] \
      && ok "command cites a reference that exists: $c → $r (owned by $found)" \
      || bad "command cites a reference that exists: $c → $r" "resolves in no skill directory"
  done
done

grep -q "The $ccount route commands:" "$ROOT/README.md" \
  && ok "README route-command count is $ccount" || bad "README route-command count is $ccount" "README says something else"

# A skill that declares a Profile section it owns must have that section in the
# template, or §5 resolution sends the run to a heading that is not there. The
# declarations are free-form (`§X and §Y`, `§X -> subrow`, `§X (parenthetical)`),
# so every §-prefixed capitalised token is extracted and matched as a heading prefix.
while IFS= read -r decl; do
  f="${decl%%:*}"; n="$(basename "$(dirname "$f")")"
  for sec in $(printf '%s' "$decl" | grep -oE '§[A-Z][A-Za-z]*( [A-Z][A-Za-z]*)*' | sed 's/^§//;s/ /_/g'); do
    sec="${sec//_/ }"
    grep -q "^## $sec" "$ROOT/skills/guidelines-meta/PROJECT-PROFILE.template.md" \
      && ok "profile has the section $n owns: §$sec" \
      || bad "profile has the section $n owns: §$sec" "no '## $sec' heading in PROJECT-PROFILE.template.md"
  done
  grep -q "\`$n\`" "$ROOT/skills/guidelines-meta/PROJECT-PROFILE.template.md" \
    && ok "profile names its owner $n" \
    || bad "profile names its owner $n" "the section-ownership table does not mention $n"
done < <(grep -H "Profile section owned:" "$ROOT"/skills/*/SKILL.md 2>/dev/null || true)

# The template is a backstop for copy-installs, and it must not be STRICTER than the
# hook in a way §9 and the README both contradict. §9 promises the listing forms of
# these five stay open; prefix matching cannot express "writing forms only", so the
# entries are dropped and guard-mutations.sh GIT_SOFT covers the writing forms.
overreach=""
for verb in branch tag stash remote worktree submodule; do
  grep -q "\"Bash(git $verb:\*)\"" "$ROOT/settings.template.json" && overreach="$overreach git-$verb"
done
assert_empty "template does not deny read-only listing forms" "$overreach"
# ...while the unambiguous writes stay denied
for verb in add commit push checkout reset rebase; do
  grep -q "\"Bash(git $verb:\*)\"" "$ROOT/settings.template.json" \
    && ok "template still denies git $verb" || bad "template still denies git $verb"
done
grep -q 'mirrors what the plugin' "$ROOT/settings.template.json" \
  && bad "template does not claim to mirror the hooks" "it is a subset, not a mirror" \
  || ok "template does not claim to mirror the hooks"

# manifests are valid JSON and agree on version
for j in "$ROOT"/.claude-plugin/*.json "$ROOT"/hooks/hooks.json "$ROOT"/settings.template.json; do
  python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$j" 2>/dev/null \
    && ok "valid JSON: $(basename "$j")" || bad "valid JSON: $(basename "$j")"
done
# hooks/hooks.json is loaded automatically; manifest.hooks is for ADDITIONAL files.
# Naming the standard path there registers every guard and advisory twice — each
# PreToolUse deny fires two hooks, and each advisory injects its block two times.
grep -q '"hooks"[[:space:]]*:[[:space:]]*"\./hooks/hooks\.json"' "$ROOT/.claude-plugin/plugin.json" \
  && bad "manifest does not re-declare the standard hooks file" "double-registers every hook" \
  || ok "manifest does not re-declare the standard hooks file"

pv="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([0-9.]*\)"/\1/')"
mv="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/marketplace.json" | head -1 | sed 's/.*"\([0-9.]*\)"/\1/')"
assert_eq "plugin and marketplace versions agree" "$pv" "$mv"

# the CLI's own validator. Two manifests, two calls: `validate <dir>` resolves the
# MARKETPLACE file and never opens plugin.json, so a single call on $ROOT asserted
# far less than it appeared to — the plugin manifest went unvalidated entirely.
if command -v claude >/dev/null 2>&1; then
  out="$(claude plugin validate "$ROOT/.claude-plugin/marketplace.json" --strict 2>&1)"
  assert_contains "marketplace manifest validates" "$out" "Validation passed"
  assert_contains "  ...and it was the marketplace" "$out" "marketplace manifest"
  out="$(claude plugin validate "$ROOT/.claude-plugin/plugin.json" --strict 2>&1)"
  assert_contains "plugin manifest validates" "$out" "Validation passed"
  assert_contains "  ...and it was the plugin" "$out" "plugin manifest"
else
  skip "claude plugin validate --strict" "claude CLI not on PATH"
fi

# scripts parse
for s in "$ROOT"/scripts/*.sh "$ROOT"/skills/*/*.sh "$ROOT"/tests/*.sh; do
  bash -n "$s" 2>/dev/null && ok "parses: ${s#$ROOT/}" || bad "parses: ${s#$ROOT/}"
done

# every hook script named in hooks.json must exist and parse
HOOKS_JSON="$ROOT/hooks/hooks.json"
if command -v jq >/dev/null 2>&1; then
  jq empty "$HOOKS_JSON" 2>/dev/null && ok "hooks.json is valid JSON" || bad "hooks.json is valid JSON"
  for s in $(jq -r '.hooks[][].hooks[].args[0]' "$HOOKS_JSON" 2>/dev/null | sed 's|${CLAUDE_PLUGIN_ROOT}/||' | sort -u); do
    [ -f "$ROOT/$s" ] && ok "hook script exists: $s" || bad "hook script exists: $s"
    bash -n "$ROOT/$s" 2>/dev/null && ok "hook script parses: $s" || bad "hook script parses: $s"
  done
  # the enforcement claim the skills now make must be wired to a real event
  assert_contains "git guard wired to PreToolUse" "$(jq -r '.hooks.PreToolUse[].hooks[].args[0]' "$HOOKS_JSON")" "guard-mutations.sh"
  assert_contains "preamble wired to UserPromptExpansion" "$(jq -r '.hooks.UserPromptExpansion[].hooks[].args[0]' "$HOOKS_JSON")" "skill-preamble.sh"
else
  skip "hooks.json wiring" "jq not installed"
fi

# the preamble's composition map must be derived from the skill file, not a static
# table — a hardcoded list is one more cross-reference to rot, which is the failure
# the module tier exists to remove
# fresh session id: the preamble is once-per-skill-per-session by design
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:code-review-architect"}' | CLAUDE_SESSION_ID="test-$$-a" bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_contains "preamble emits the composition map" "$out" "What this skill composes from"
assert_contains "composition map lists a module" "$out" "module-threat-model"
assert_contains "composition map lists a reference" "$out" "references/output-format.md"
# a module is a fragment loaded by an architect that already got the preamble
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:module-propagation"}' | CLAUDE_SESSION_ID="test-$$-b" bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_empty "preamble silent for a module" "$out"

# The map tells Claude to read each reference from ${CLAUDE_SKILL_DIR}/, so every
# path it lists under that heading MUST exist in THAT skill's directory. Several
# architects name a sibling's references in prose ("its references/triage.md"), and
# a grep-derived map happily advertised five files that resolve nowhere.
# The structural check further up cannot catch this: it searches every skill dir.
badmap=""
for f in "$ROOT"/skills/*/SKILL.md; do
  sk="$(basename "$(dirname "$f")")"
  case "$sk" in guidelines-meta|module-*) continue ;; esac
  o="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:%s","session_id":"map-%s-%s"}' "$sk" "$$" "$sk" \
       | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
  # the hook emits one JSON line, so unescape before slicing it: only the lines under
  # the ${CLAUDE_SKILL_DIR} heading are own-directory claims. The foreign-owned list
  # below it names its owner and is expected NOT to resolve here.
  own="$(printf '%s' "$o" | sed 's/\\n/\n/g' \
         | sed -n '/Reference files, read with the Read tool/,/^$/p' \
         | grep -oE 'references/[a-z0-9-]+\.md' | sort -u)"
  for r in $own; do
    [ -f "$ROOT/skills/$sk/$r" ] || badmap="$badmap [$sk→$r]"
  done
done
assert_empty "composition map advertises only paths that resolve" "$badmap"
rm -rf "${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)"/map-$$-*

# guards must fail closed, advisories must fail open — asserted on the source,
# because a hook that silently allows is indistinguishable from one that passed
for g in guard-mutations guard-outward guard-secrets; do
  grep -q 'guard_require_json_engine' "$ROOT/scripts/$g.sh" \
    && ok "$g fails closed without a JSON engine" || bad "$g fails closed without a JSON engine"
done
for a in skill-preamble warn-test-weakening advise-propagation; do
  grep -q 'advisory_require_json_engine' "$ROOT/scripts/$a.sh" \
    && ok "$a fails open without a JSON engine" || bad "$a fails open without a JSON engine"
done

# the skills must point at the hook rather than restating the rule
grep -q 'enforced by the plugin' "$ROOT/skills/implementing-architect/SKILL.md" \
  && ok "implementing cites the hook, not a restatement" || bad "implementing cites the hook, not a restatement"

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

# ── A repo is allowed to be more than one ecosystem. Resolution used to be an
#    elif chain, so the first manifest present won and every other one was invisible
#    — and §5 rule 3 then had the model STATE that the missing gates do not exist,
#    which is the fabrication §15 exists to prevent, produced by the resolver itself.
PG="$TMP/polyglot"; mkdir -p "$PG"
printf '{"scripts":{"lint":"eslint ."}}' > "$PG/package.json"
printf '[project]\nname="x"\n' > "$PG/pyproject.toml"
printf 'test:\n\tpytest\nbuild:\n\tmake dist\n' > "$PG/Makefile"
out="$(cd "$PG" && bash "$CQ" --list)"
assert_contains "polyglot: js lint still wins"      "$out" "npm run lint"
assert_contains "polyglot: make test is found"      "$out" "make test"
assert_contains "polyglot: make build is found"     "$out" "make build"
assert_contains "polyglot: python typecheck found"  "$out" "mypy"
assert_missing  "polyglot: nothing left falsely n-a" "$out" "Tests + Coverage   n-a"

# the earlier ecosystem still outranks the later one for a role BOTH define
PG2="$TMP/polyglot2"; mkdir -p "$PG2"
printf '{"scripts":{"test":"vitest run"}}' > "$PG2/package.json"
printf 'test:\n\tpytest\n' > "$PG2/Makefile"
out="$(cd "$PG2" && bash "$CQ" --list)"
assert_contains "polyglot: manifest order is precedence" "$out" "npm run test"
assert_missing  "polyglot: later ecosystem does not clobber" "$out" "make test"

# explicit config wins over detection
mkdir -p "$TMP/conf/.claude"; printf '{"scripts":{"lint":"x"}}' > "$TMP/conf/package.json"
printf 'LINT="custom-linter --strict"\n' > "$TMP/conf/.claude/quality-gates.conf"
out="$(cd "$TMP/conf" && bash "$CQ" --list)"
assert_contains "quality-gates.conf overrides detection" "$out" "custom-linter --strict"

# ── PROJECT-PROFILE.md is the authority (guidelines-meta §5 rule 1). This is what
#    skill-preamble.sh injects as the resolved gate table, so a script that ignored
#    the profile would hand Claude auto-detected commands under the profile's name.
mkdir -p "$TMP/prof/.claude"
printf '{"scripts":{"lint":"eslint .","test":"vitest run","build":"vite build"}}' > "$TMP/prof/package.json"
cat > "$TMP/prof/.claude/PROJECT-PROFILE.md" <<'PROF'
# Project Profile
## Commands
| Role | Command | Notes |
|---|---|---|
| `<lint>` | `pnpm run lint:strict` | the real gate |
| `<typecheck>` | | not filled in |
| `<test>` | `pnpm run test:ci` | with coverage |
| `<e2e>` | `n-a` | none here |
| `<visual>` | `<command>` | still a placeholder |

**Golden / snapshot update command (USER-ONLY — never run by a skill):** `pnpm run snap`
PROF
out="$(cd "$TMP/prof" && bash "$CQ" --list)"
assert_contains "profile overrides detection"        "$out" "pnpm run lint:strict"
assert_contains "profile supplies test command"      "$out" "pnpm run test:ci"
assert_contains "profile names its own update cmd"   "$out" "pnpm run snap"
assert_contains "profile named as the source"        "$out" "PROJECT-PROFILE.md"
assert_contains "blank profile row falls through"    "$out" "npm run build"
# a half-filled profile is the normal state (§5 "progressive, not a questionnaire"):
# n-a and <placeholder> rows must not become invented commands
assert_missing  "placeholder row not taken literally" "$out" "<command>"

# profile beats conf, conf still beats detection
printf 'LINT="conf-linter"
BUILD="make release"
' > "$TMP/prof/.claude/quality-gates.conf"
out="$(cd "$TMP/prof" && bash "$CQ" --list)"
assert_contains "profile outranks quality-gates.conf" "$out" "pnpm run lint:strict"
assert_contains "conf still fills what profile omits" "$out" "make release"
# an env var passed on the invocation is the most explicit signal and outranks both
out="$(cd "$TMP/prof" && LINT="env-linter" bash "$CQ" --list)"
assert_contains "env var outranks profile and conf"   "$out" "env-linter"

# --list must never execute a gate
mkdir -p "$TMP/side"; printf '{"scripts":{"lint":"touch SIDE_EFFECT"}}' > "$TMP/side/package.json"
( cd "$TMP/side" && bash "$CQ" --list >/dev/null 2>&1 )
[ -f "$TMP/side/SIDE_EFFECT" ] && bad "--list runs nothing" "a gate was executed" || ok "--list runs nothing"

# ...and the conf is DATA, not a script. It used to be `.`-sourced before the --list
# early exit, so cloning a repo ran its author's shell: profile-bootstrap.sh calls
# --list on every SessionStart and guard-mutations.sh on the first guarded Bash call.
mkdir -p "$TMP/confside/.claude"; printf '{"scripts":{}}' > "$TMP/confside/package.json"
printf 'LINT="conf-lint"\ntouch CONF_EXECUTED\n' > "$TMP/confside/.claude/quality-gates.conf"
( cd "$TMP/confside" && bash "$CQ" --list >/dev/null 2>&1 )
[ -f "$TMP/confside/CONF_EXECUTED" ] \
  && bad "quality-gates.conf is parsed, not executed" "shell in the conf ran" \
  || ok "quality-gates.conf is parsed, not executed"
out="$(cd "$TMP/confside" && bash "$CQ" --list)"
assert_contains "conf assignments still read" "$out" "conf-lint"

# quoting styles a hand-written conf actually uses must all survive the parser
mkdir -p "$TMP/confquote/.claude"; printf '{"scripts":{}}' > "$TMP/confquote/package.json"
printf '# a comment\nLINT="pnpm run lint"\nTEST=\x27pnpm run test:ci\x27\n  BUILD=make\nVISUAL=""\n' \
  > "$TMP/confquote/.claude/quality-gates.conf"
out="$(cd "$TMP/confquote" && bash "$CQ" --list)"
assert_contains "conf: double quotes"  "$out" "pnpm run lint"
assert_contains "conf: single quotes"  "$out" "pnpm run test:ci"
assert_contains "conf: bare + indent"  "$out" "make"
assert_contains "conf: empty means n-a" "$out" "Visual regression  n-a"

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

# ...but "source" is not a JS/Python word. A pack whose own repo is 9 shell scripts
# and 25 skill files greeted ITSELF as "not really started yet" — and so does every
# C, C#, Kotlin, Swift, Elixir, or shell project.
SH="$TMP/shellproj"; mkdir -p "$SH/scripts"
printf '{}' > "$SH/package.json"
for i in 1 2 3 4 5 6; do printf '#!/bin/sh\n' > "$SH/scripts/s$i.sh"; done
assert_contains "a shell project is brownfield" "$(run_bs "$SH")" "investigate before you ask"

CP="$TMP/cproj"; mkdir -p "$CP/src"; printf 'all:\n\tcc\n' > "$CP/Makefile"
for i in 1 2 3 4; do printf 'int main(){}\n' > "$CP/src/f$i.c"; done
assert_contains "a C project is brownfield" "$(run_bs "$CP")" "investigate before you ask"

# a genuinely empty repo must STILL read as greenfield — the fix must not swallow it
EG="$TMP/emptygreen"; mkdir -p "$EG"; printf '{"scripts":{}}' > "$EG/package.json"
assert_contains "an empty repo is still greenfield" "$(run_bs "$EG")" "has not really started"

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
out="$(CLAUDE_PROJECT_DIR="$BR" CLAUDE_PLUGIN_ROOT="$ROOT" M_SKILLS_AUTOPROFILE=1 bash "$BS" 2>/dev/null)"
[ -f "$BR/.claude/PROJECT-PROFILE.md" ] && ok "M_SKILLS_AUTOPROFILE=1 writes a draft" || bad "M_SKILLS_AUTOPROFILE=1 writes a draft"
assert_contains "the draft write is announced" "$out" "DRAFT has been written"

# ...on the greenfield path too. $WROTE was interpolated only into the brownfield
# heredoc, so a file appeared in the user's repo and the session never said so.
GW="$TMP/greenwrite"; mkdir -p "$GW"; printf '{"scripts":{}}' > "$GW/package.json"
out="$(CLAUDE_PROJECT_DIR="$GW" CLAUDE_PLUGIN_ROOT="$ROOT" M_SKILLS_AUTOPROFILE=1 bash "$BS" 2>/dev/null)"
[ -f "$GW/.claude/PROJECT-PROFILE.md" ] \
  && ok "greenfield + autoprofile writes a draft" || bad "greenfield + autoprofile writes a draft"
assert_contains "greenfield draft write is announced too" "$out" "DRAFT has been written"

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
section "5. Behaviour — the enforcement hooks"

# These are the assertions that matter most in the pack: the rules they cover used
# to live only in prose, so a regression here silently returns the pack to the state
# where §9 was restated eleven times and enforced zero times.

if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  skip "hook behaviour" "neither jq nor python3 available"
else

# Isolate the hooks' per-session state so one run cannot silence the next.
export CLAUDE_SESSION_ID="test-$$"
export CLAUDE_PROJECT_DIR="$TMP/hookproj"
export CLAUDE_CONFIG_DIR="$TMP/hookconfig"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude" "$CLAUDE_CONFIG_DIR"

# The block above admits either engine, so these two must too. Hardcoding python3
# made every assertion below evaluate to "allow" on a jq-only box — ~70 silent passes
# reported as failures with no hint that the harness, not the hook, was broken.
if command -v jq >/dev/null 2>&1; then
  esc() { printf '%s' "$1" | jq -Rs .; }
  verdict() { jq -r '.hookSpecificOutput.permissionDecision // .decision // "allow"' 2>/dev/null; }
else
  esc() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
  verdict() { python3 -c '
import json,sys
try: d = json.load(sys.stdin)
except Exception: print("allow"); sys.exit()
h = d.get("hookSpecificOutput") or {}
print(h.get("permissionDecision") or d.get("decision") or "allow")
' 2>/dev/null; }
fi

# decision <script> <json-payload> → "deny" | "ask" | "block" | "allow"
decision() {
  local out res
  out="$(printf '%s' "$2" | bash "$ROOT/scripts/$1" 2>/dev/null)"
  [ -z "$out" ] && { echo allow; return; }
  res="$(printf '%s' "$out" | verdict)"
  printf '%s\n' "${res:-allow}"
}
bash_payload()  { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(esc "$1")"; }
write_payload() { printf '{"tool_name":"%s","tool_input":{"file_path":%s}}' "$1" "$(esc "$2")"; }
edit_payload()  { printf '{"tool_name":"Edit","tool_input":{"file_path":%s,"old_string":%s,"new_string":%s}}' "$(esc "$1")" "$(esc "$2")" "$(esc "$3")"; }

expect() { # <label> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected $2, got $3"; fi
}

# ── §9 git guards. The four chained/flag forms are the class the prefix-matching
#    deny list in settings.template.json cannot see, which is why this hook exists.
expect "deny: git commit"              deny  "$(decision guard-mutations.sh "$(bash_payload 'git commit -m x')")"
expect "deny: git -C <path> push"      deny  "$(decision guard-mutations.sh "$(bash_payload 'git -C /tmp/x push')")"
expect "deny: git add behind &&"       deny  "$(decision guard-mutations.sh "$(bash_payload 'cd foo && git add .')")"
expect "deny: git push inside bash -c" deny  "$(decision guard-mutations.sh "$(bash_payload 'bash -c "git push --force"')")"
expect "deny: --git-dir= form"         deny  "$(decision guard-mutations.sh "$(bash_payload 'git --git-dir=/r/.git commit -m y')")"
expect "deny: --no-verify anywhere"    deny  "$(decision guard-mutations.sh "$(bash_payload 'pre-commit run --no-verify')")"
expect "deny: git reset --hard"        deny  "$(decision guard-mutations.sh "$(bash_payload 'git reset --hard HEAD~1')")"

# read-only git must survive, or the review and history skills stop working
expect "allow: git status"             allow "$(decision guard-mutations.sh "$(bash_payload 'git status')")"
expect "allow: git diff HEAD"          allow "$(decision guard-mutations.sh "$(bash_payload 'git diff HEAD')")"
expect "allow: git log --oneline"      allow "$(decision guard-mutations.sh "$(bash_payload 'git log --oneline -20')")"
expect "allow: git show"               allow "$(decision guard-mutations.sh "$(bash_payload 'git show HEAD:file.ts')")"

# listing forms are read-only and must survive — denying them is the over-block
# that sends people to the opt-out, which would disarm the guard entirely
expect "deny: git branch <name>"       deny  "$(decision guard-mutations.sh "$(bash_payload 'git branch feature/x')")"
expect "deny: git branch -D"           deny  "$(decision guard-mutations.sh "$(bash_payload 'git branch -D old')")"
expect "deny: git tag <name>"          deny  "$(decision guard-mutations.sh "$(bash_payload 'git tag v1.0')")"
expect "deny: git remote add"          deny  "$(decision guard-mutations.sh "$(bash_payload 'git remote add origin url')")"
expect "deny: git stash (bare)"        deny  "$(decision guard-mutations.sh "$(bash_payload 'git stash')")"
expect "deny: git stash pop"           deny  "$(decision guard-mutations.sh "$(bash_payload 'git stash pop')")"
expect "allow: git branch (list)"      allow "$(decision guard-mutations.sh "$(bash_payload 'git branch')")"
expect "allow: git branch -a"          allow "$(decision guard-mutations.sh "$(bash_payload 'git branch -a')")"
expect "allow: git branch --show-current" allow "$(decision guard-mutations.sh "$(bash_payload 'git branch --show-current')")"
expect "allow: git tag -l"             allow "$(decision guard-mutations.sh "$(bash_payload 'git tag -l')")"
expect "allow: git remote -v"          allow "$(decision guard-mutations.sh "$(bash_payload 'git remote -v')")"
expect "allow: git stash list"         allow "$(decision guard-mutations.sh "$(bash_payload 'git stash list')")"
expect "allow: git rev-parse"          allow "$(decision guard-mutations.sh "$(bash_payload 'git rev-parse --show-toplevel')")"

# ── §10 golden updates
expect "deny: --update-snapshots"      deny  "$(decision guard-mutations.sh "$(bash_payload 'npx playwright test --update-snapshots')")"
expect "deny: jest -u"                 deny  "$(decision guard-mutations.sh "$(bash_payload 'jest -u')")"
expect "deny: UPDATE_SNAPSHOTS=1"      deny  "$(decision guard-mutations.sh "$(bash_payload 'UPDATE_SNAPSHOTS=1 npm test')")"
expect "deny: cargo insta accept"      deny  "$(decision guard-mutations.sh "$(bash_payload 'cargo insta accept')")"
# -u only means snapshots next to a runner that defines it
expect "allow: curl -u"                allow "$(decision guard-mutations.sh "$(bash_payload 'curl -u user:pass https://x')")"
expect "allow: plain test run"         allow "$(decision guard-mutations.sh "$(bash_payload 'npm test')")"

# ── §9 is "no git write", not "no four specific verbs". These were denied by the
#    hook while Guidelines §9 listed only six bullets; the prose now matches, so
#    pin the breadth against a future narrowing.
expect "deny: git fetch"               deny  "$(decision guard-mutations.sh "$(bash_payload 'git fetch origin main')")"
expect "deny: git pull"                deny  "$(decision guard-mutations.sh "$(bash_payload 'git pull')")"
expect "deny: git merge"               deny  "$(decision guard-mutations.sh "$(bash_payload 'git merge feature')")"
expect "deny: git restore"             deny  "$(decision guard-mutations.sh "$(bash_payload 'git restore --staged .')")"
# debugging-architect §8 claims bisect is denied; it was not, until it was added
expect "deny: git bisect"              deny  "$(decision guard-mutations.sh "$(bash_payload 'git bisect start')")"
expect "deny: git apply"               deny  "$(decision guard-mutations.sh "$(bash_payload 'git apply patch.diff')")"
# read-only git is the review path and must never close
expect "allow: git merge-base"         allow "$(decision guard-mutations.sh "$(bash_payload 'git merge-base main HEAD')")"
expect "allow: git describe"           allow "$(decision guard-mutations.sh "$(bash_payload 'git describe --tags')")"

# ── catastrophic filesystem operations
expect "deny: rm -rf ~"                deny  "$(decision guard-mutations.sh "$(bash_payload 'rm -rf ~')")"
expect "deny: dd of=/dev/sda"          deny  "$(decision guard-mutations.sh "$(bash_payload 'dd if=/dev/zero of=/dev/sda')")"
expect "allow: scoped rm -rf"          allow "$(decision guard-mutations.sh "$(bash_payload 'rm -rf ./node_modules')")"

# ── H2 outward-facing actions are handed over, not fired. deployment-architect
#    constraint 2: the runbook is the deliverable, the button is the user's.
expect "deny: npm publish"             deny  "$(decision guard-outward.sh "$(bash_payload 'npm publish')")"
expect "deny: fly deploy"              deny  "$(decision guard-outward.sh "$(bash_payload 'fly deploy')")"
expect "deny: kubectl apply"           deny  "$(decision guard-outward.sh "$(bash_payload 'kubectl apply -f k8s/')")"
expect "deny: prisma migrate deploy"   deny  "$(decision guard-outward.sh "$(bash_payload 'npx prisma migrate deploy')")"
# reversible work is what keeps the skill useful — it must stay open (constraint 3)
expect "allow: terraform plan"         allow "$(decision guard-outward.sh "$(bash_payload 'terraform plan')")"
expect "allow: kubectl get pods"       allow "$(decision guard-outward.sh "$(bash_payload 'kubectl get pods')")"
expect "allow: docker build"           allow "$(decision guard-outward.sh "$(bash_payload 'docker build -t x .')")"

# ── H2b gh writes join the git family (Guidelines §9): they publish to a surface
#    other people see. Read-only gh must stay open — code-review-architect reviews
#    a PR by fetching it with the platform CLI.
expect "deny: gh pr create"            deny  "$(decision guard-outward.sh "$(bash_payload 'gh pr create --fill')")"
expect "deny: gh pr merge"             deny  "$(decision guard-outward.sh "$(bash_payload 'gh pr merge 12 --squash')")"
expect "deny: gh pr comment"           deny  "$(decision guard-outward.sh "$(bash_payload 'gh pr comment 3 -b hi')")"
expect "deny: gh issue create"         deny  "$(decision guard-outward.sh "$(bash_payload 'gh issue create -t x')")"
expect "deny: gh release create"       deny  "$(decision guard-outward.sh "$(bash_payload 'gh release create v1.0')")"
expect "deny: gh secret set"           deny  "$(decision guard-outward.sh "$(bash_payload 'gh secret set API_KEY')")"
expect "deny: gh workflow run"         deny  "$(decision guard-outward.sh "$(bash_payload 'gh workflow run deploy.yml')")"
expect "deny: gh api -X POST"          deny  "$(decision guard-outward.sh "$(bash_payload 'gh api -X POST /repos/x/y/issues')")"
expect "allow: gh pr view"             allow "$(decision guard-outward.sh "$(bash_payload 'gh pr view 12')")"
expect "allow: gh pr diff"             allow "$(decision guard-outward.sh "$(bash_payload 'gh pr diff 12')")"
expect "allow: gh pr list"             allow "$(decision guard-outward.sh "$(bash_payload 'gh pr list')")"
expect "allow: gh pr checks"           allow "$(decision guard-outward.sh "$(bash_payload 'gh pr checks 12')")"
expect "allow: gh issue list"          allow "$(decision guard-outward.sh "$(bash_payload 'gh issue list')")"
expect "allow: gh run view"            allow "$(decision guard-outward.sh "$(bash_payload 'gh run view 5')")"
expect "allow: gh api read"            allow "$(decision guard-outward.sh "$(bash_payload 'gh api /repos/x/y')")"

# ── H5 secrets: writes denied, reads and example files untouched. The example-file
#    exemption is load-bearing — profile-bootstrap.sh and deployment-architect both
#    read .env.example, so a guard that blocked it would break the pack itself.
expect "deny: write .env"              deny  "$(decision guard-secrets.sh "$(write_payload Write '/p/.env')")"
expect "deny: write .env.production"   deny  "$(decision guard-secrets.sh "$(write_payload Write '/p/.env.production')")"
expect "deny: write server.pem"        deny  "$(decision guard-secrets.sh "$(write_payload Write '/p/certs/server.pem')")"
expect "deny: append into .env"        deny  "$(decision guard-secrets.sh "$(bash_payload 'echo "KEY=v" >> .env')")"
expect "allow: write .env.example"     allow "$(decision guard-secrets.sh "$(write_payload Write '/p/.env.example')")"
expect "allow: edit .env.sample"       allow "$(decision guard-secrets.sh "$(write_payload Edit '/p/.env.sample')")"
expect "allow: read .env via cat"      allow "$(decision guard-secrets.sh "$(bash_payload 'cat .env')")"
expect "allow: write ordinary source"  allow "$(decision guard-secrets.sh "$(write_payload Write '/p/src/app.ts')")"

# ── H4 test weakening: only a NEWLY introduced marker fires
expect "block: spec gains it.skip"     block "$(decision warn-test-weakening.sh "$(edit_payload 'src/a.spec.ts' 'it("x", () => {})' 'it.skip("x", () => {})')")"
expect "block: spec gains .only"       block "$(decision warn-test-weakening.sh "$(edit_payload 'src/a.spec.ts' 'it("x", () => {})' 'it.only("x", () => {})')")"
expect "allow: spec edit, no marker"   allow "$(decision warn-test-weakening.sh "$(edit_payload 'src/a.spec.ts' 'it("x", () => {})' 'it("y", () => {})')")"
expect "allow: spec LOSES a skip"      allow "$(decision warn-test-weakening.sh "$(edit_payload 'src/a.spec.ts' 'it.skip("x", () => {})' 'it("x", () => {})')")"
expect "allow: skip in non-test file"  allow "$(decision warn-test-weakening.sh "$(edit_payload 'src/a.ts' 'a' 'it.skip("x")')")"

# ── H6 propagation: fires once per file per session, silent elsewhere
expect "block: models/ first edit"     block "$(decision advise-propagation.sh "$(edit_payload 'src/models/user.ts' 'a' 'b')")"
expect "allow: models/ second edit"    allow "$(decision advise-propagation.sh "$(edit_payload 'src/models/user.ts' 'b' 'c')")"
expect "block: schema.prisma"          block "$(decision advise-propagation.sh "$(edit_payload 'prisma/schema.prisma' 'a' 'b')")"
expect "allow: ordinary util file"     allow "$(decision advise-propagation.sh "$(edit_payload 'src/utils/format.ts' 'a' 'b')")"
expect "allow: a test file"            allow "$(decision advise-propagation.sh "$(edit_payload 'src/models/user.spec.ts' 'a' 'b')")"

# ── H3 preamble: this pack's skills only, and it must carry the resolved gates
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:testing-architect"}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_contains "preamble injects gate resolution" "$out" "Gate resolution"
assert_contains "preamble injects §9"              "$out" "Inherited Guards"
assert_contains "preamble names the skill"         "$out" "testing-architect"
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"some-other-plugin:thing"}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_empty "preamble silent for other plugins" "$out"
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:guidelines-meta"}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_empty "preamble silent for guidelines-meta itself" "$out"

# It is registered with no matcher, so it runs on EVERY user prompt: it must decide
# "not mine" with a shell builtin, before spending a jq/python3 spawn on it.
out="$(printf '{"hook_event_name":"UserPromptExpansion","prompt":"what does this repo do?"}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_empty "preamble silent on an ordinary prompt" "$out"

# Silence alone does not prove it was cheap — an early `exit 0` after the jq call
# looks identical from outside. Poison the JSON engines: if either is invoked, it
# leaves a marker. This is the assertion that actually pins the per-turn cost.
SPY="$TMP/spy"; mkdir -p "$SPY"
for engine in jq python3; do
  printf '#!/bin/sh\ntouch "%s/spawned"\nexit 1\n' "$SPY" > "$SPY/$engine"
  chmod +x "$SPY/$engine"
done
rm -f "$SPY/spawned"
printf '{"hook_event_name":"UserPromptExpansion","prompt":"an ordinary question"}' \
  | PATH="$SPY:$PATH" bash "$ROOT/scripts/skill-preamble.sh" >/dev/null 2>&1
if [ -f "$SPY/spawned" ]; then
  bad "preamble spawns no JSON engine on an ordinary prompt" "jq/python3 was invoked; the cheap-exit is gone"
else
  ok "preamble spawns no JSON engine on an ordinary prompt"
fi
# ...but it must still spawn one when the prompt IS a pack command, or it cannot work
rm -f "$SPY/spawned"
printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:code-review-architect"}' \
  | PATH="$SPY:$PATH" bash "$ROOT/scripts/skill-preamble.sh" >/dev/null 2>&1
if [ -f "$SPY/spawned" ]; then
  ok "preamble still parses a real pack invocation"
else
  bad "preamble still parses a real pack invocation" "cheap-exit swallowed a genuine m-skills command"
fi

# Once per skill per session. A skill arriving via BOTH the slash command and the
# Skill tool used to inject the identical ~40 lines twice.
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:deployment-architect"}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_contains "preamble injects on first invocation" "$out" "deployment-architect"
out="$(printf '{"hook_event_name":"PostToolUse","tool_input":{"skill":"m-skills:deployment-architect"}}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_empty "preamble does not inject the same skill twice" "$out"
out="$(printf '{"hook_event_name":"PostToolUse","tool_input":{"skill":"m-skills:design-architect"}}' | bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_contains "a different skill still injects" "$out" "design-architect"

# ── Route commands resolve to the architect they route into. Unresolved, SKILL would
#    be "decompose": skills/decompose/SKILL.md does not exist, so the composition map
#    comes out EMPTY and the marker is written under the wrong key — which means the
#    architect the command then reads injects the whole preamble a second time.
RC='{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:decompose","session_id":"%s"}'
out="$(printf "$RC" "route-$$-a" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_contains "route command resolves to its owner"      "$out" "preamble for \`product-architect\`"
assert_contains "route command gets the owner's ref map"   "$out" "references/decompose.md"
assert_contains "route command gets the owner's modules"   "$out" "module-writing-floor"
assert_missing  "route command is not mapped as itself"    "$out" "preamble for \`decompose\`"
# the dedupe that the resolution buys: the owner, loaded next by the command body,
# must NOT inject a second copy in the same session
out="$(printf '{"hook_event_name":"PostToolUse","tool_input":{"skill":"m-skills:product-architect"},"session_id":"route-'"$$"'-a"}' \
       | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_empty "route command's owner does not inject twice" "$out"
# a name that is neither a skill nor a command must not acquire an owner
out="$(printf '{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:not-a-thing","session_id":"route-'"$$"'-b"}' \
       | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_missing "unknown name resolves to no owner" "$out" "What this skill composes from"
rm -rf "${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)"/route-$$-*

# ── §10's dynamic arm: the PROJECT'S OWN resolved update command. This is the half
#    prose can never enforce, because the command is project-specific — and it was
#    the only guard family with no coverage at all.
UP="$TMP/updproj"; mkdir -p "$UP/.claude"
printf '{"scripts":{"test":"vitest run","e2e:update":"playwright test -u"}}' > "$UP/package.json"
touch "$UP/package-lock.json"
(
  export CLAUDE_PROJECT_DIR="$UP" CLAUDE_SESSION_ID="upd-$$"
  expect "deny: the project's own update command" deny \
    "$(decision guard-mutations.sh "$(bash_payload 'npm run e2e:update')")"
  expect "allow: a different script in the same project" allow \
    "$(decision guard-mutations.sh "$(bash_payload 'npm run test')")"
)
rm -rf "${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)/upd-$$"

# ── C2: `-u` is only a snapshot flag on runners that define it, and only when it
#    belongs to that runner. Denying legitimate work is the worst guard failure
#    there is: the reason text points at .m-skills-no-guards, which disarms all three.
expect "allow: mocha -u tdd (mocha's -u is --ui)" allow \
  "$(decision guard-mutations.sh "$(bash_payload 'mocha -u tdd test/')")"
expect "allow: jest piped into sort -u"           allow \
  "$(decision guard-mutations.sh "$(bash_payload 'jest --listTests | sort -u')")"
expect "allow: vitest then a separate uniq -u"    allow \
  "$(decision guard-mutations.sh "$(bash_payload 'vitest run --reporter=json; cat out | uniq -u')")"
# ...but the real thing still has to be caught, in every segment
expect "deny: vitest -u"                          deny \
  "$(decision guard-mutations.sh "$(bash_payload 'vitest -u')")"
expect "deny: playwright -u behind &&"            deny \
  "$(decision guard-mutations.sh "$(bash_payload 'pnpm build && npx playwright test -u')")"

# ── T5: the once-per-session marker must key on the SESSION, not on the machine.
#    Every hook payload carries session_id; keying only on $CLAUDE_SESSION_ID meant
#    that when the runtime exported none, the state dir was one shared name and the
#    marker outlived the session — the preamble then injected once per MACHINE.
SP='{"hook_event_name":"UserPromptExpansion","command_name":"m-skills:planning-architect","session_id":"%s"}'
a="$(printf "$SP" "sess-$$-one" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
b="$(printf "$SP" "sess-$$-one" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
c="$(printf "$SP" "sess-$$-two" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/skill-preamble.sh" 2>/dev/null)"
assert_contains "payload session_id: first invocation injects"  "$a" "planning-architect"
assert_empty    "payload session_id: same session stays silent" "$b"
assert_contains "payload session_id: a NEW session injects"     "$c" "planning-architect"

# the same guarantee for the propagation advisory, which is once-per-file-per-session
PP='{"tool_name":"Edit","tool_input":{"file_path":"src/models/order.ts","old_string":"a","new_string":"b"},"session_id":"%s"}'
a="$(printf "$PP" "prop-$$-one" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/advise-propagation.sh" 2>/dev/null)"
b="$(printf "$PP" "prop-$$-one" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/advise-propagation.sh" 2>/dev/null)"
c="$(printf "$PP" "prop-$$-two" | env -u CLAUDE_SESSION_ID bash "$ROOT/scripts/advise-propagation.sh" 2>/dev/null)"
assert_contains "propagation: advises on first edit"  "$a" "shared-shape"
assert_empty    "propagation: silent on second edit"  "$b"
assert_contains "propagation: a NEW session advises"  "$c" "shared-shape"
rm -rf "${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)"/sess-$$-* \
       "${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)"/prop-$$-*

# ── C9: NotebookEdit sends notebook_path, not file_path. The branch read the wrong
#    field, so a guard the code claims to have never ran.
expect "deny: NotebookEdit into a secret path" deny \
  "$(decision guard-secrets.sh "$(printf '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":%s}}' "$(esc '/p/.env')")")"
expect "allow: NotebookEdit into a notebook"   allow \
  "$(decision guard-secrets.sh "$(printf '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":%s}}' "$(esc '/p/analysis.ipynb')")")"

# ── the opt-out must release every guard, or the pack is unusable for anyone who
#    wants Claude to touch git at all
touch "$CLAUDE_PROJECT_DIR/.claude/.m-skills-no-guards"
expect "opt-out releases git guard"     allow "$(decision guard-mutations.sh "$(bash_payload 'git commit -m x')")"
expect "opt-out releases secret guard"  allow "$(decision guard-secrets.sh "$(write_payload Write '/p/.env')")"
expect "opt-out releases outward gate"  allow "$(decision guard-outward.sh "$(bash_payload 'npm publish')")"
rm -f "$CLAUDE_PROJECT_DIR/.claude/.m-skills-no-guards"
expect "guard re-arms once flag is gone" deny "$(decision guard-mutations.sh "$(bash_payload 'git commit -m x')")"

rm -rf "${TMPDIR:-/tmp}/m-skills-$(id -u 2>/dev/null || echo 0)/$CLAUDE_SESSION_ID"
unset CLAUDE_SESSION_ID CLAUDE_PROJECT_DIR CLAUDE_CONFIG_DIR
fi

# ─────────────────────────────────────────────────────────────────────────────
section "6. Eval — model in the loop (opt-in)"

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
