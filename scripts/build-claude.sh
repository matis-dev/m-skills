#!/usr/bin/env bash
# m-skills — build the tree the Claude plugin directory follows. One source, three hosts.
#
# Usage: bash scripts/build-claude.sh [out-dir]   (default: dist/claude/m-skills)
#
# Since 2026-11 the directory accepts, from an organization that is not Verified, only
# Markdown, text, JSON, YAML, and images: no hook of any type, no script or program, no
# file starting with #!, no package-manager config, and no allowed-tools entry beyond
# Read, Grep, Glob, and LS. So this edition ships no scripts and no hooks (see No hooks
# below), and the steps that ran a plugin script, and the text that says a hook denies a
# call, are rewritten (see Edition rewrites below). The build refuses any file that
# breaks those rules, so a new script in skills/ fails here, not in the directory.
#
# What ships: the manifests and icon, skills/ (minus its scripts, with the edition
# rewrites), commands/, LICENSE, THIRD-PARTY-NOTICES.md, and README.release.md as
# README.md. Everything else stays on main, where the self-hosted install keeps every
# script and hook.

set -euo pipefail

ROOT="$(cd "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist/claude/m-skills}"

# The output is cleared with rm -rf, so it must be unmistakably a build directory.
case "$OUT" in
  */dist/claude/m-skills) ;;
  *) echo "build-claude: refusing to clear '$OUT' — the output path must end in /dist/claude/m-skills" >&2; exit 1 ;;
esac

VERSION="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
[ -n "$VERSION" ] || { echo "build-claude: no version in .claude-plugin/plugin.json" >&2; exit 1; }
[ -f "$ROOT/README.release.md" ] || { echo "build-claude: README.release.md is missing" >&2; exit 1; }

PART="$(mktemp -d)"; trap 'rm -rf "$PART"' EXIT

rm -rf "$OUT"
mkdir -p "$OUT/.claude-plugin"
cp "$ROOT/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json" "$ROOT/.claude-plugin/icon.png" "$OUT/.claude-plugin/"
cp -R "$ROOT/skills" "$ROOT/commands" "$OUT/"
cp "$ROOT/LICENSE" "$ROOT/THIRD-PARTY-NOTICES.md" "$OUT/"
# The one script in skills/, by name: a new one must fail the checks below, not vanish.
rm "$OUT/skills/implementing-architect/check-quality.sh"
cp "$ROOT/README.release.md" "$OUT/README.md"

# ── No hooks ─────────────────────────────────────────────────────────────────
# Since 2026-11 the directory refuses, from an organization that is not Verified, hooks
# of every type: command hooks first, then prompt hooks too. So this
# edition ships no hooks/ folder, and the guards are rules Claude follows, not calls a
# hook denies. The skill text that says a hook enforces them is rewritten below, and the
# checks refuse any hook or hook claim left in the tree. hooks/hooks.json on main, which
# the self-hosted marketplace installs, keeps every hook.

# guidelines-meta's adhd section promises a SessionStart hook this edition does not ship.
GM="$OUT/skills/guidelines-meta/SKILL.md"
awk '
  /^\*\*Scope and persistence\.\*\*/ {
    print "**Scope and persistence.** This section applies whenever any skill in this pack is running, which is most of the time. To apply it to *everything* — ordinary questions, debugging, work that never touches a pipeline skill — ask for it at the start of a session; it holds until the session ends or its context is cleared. This edition runs no `SessionStart` hook, so no flag file can re-apply it; the self-hosted install from matis-dev/m-skills adds one. `\"stop adhd mode\"` turns it off."
    skip = 1; replaced = 1; next
  }
  skip && /^> Derived from \[ayghri\/i-have-adhd\]/ { skip = 0; print ""; print; next }
  !skip { print }
  END { if (!replaced) exit 1 }
' "$GM" > "$GM.tmp" || { echo "build-claude: guidelines-meta has no adhd Scope and persistence paragraph to rewrite" >&2; exit 1; }
mv "$GM.tmp" "$GM"

# ── Edition rewrites ─────────────────────────────────────────────────────────
# Each step that ran a plugin script becomes a step Claude does by hand. rewrite fails
# the build when its source text is gone, so an edit on main cannot slip a script call
# past it. An empty replacement for a whole line deletes the line.
rewrite() { # <file under OUT> <exact source text> <replacement>
  OLD="$2" NEW="$3" awk '
    BEGIN { o = ENVIRON["OLD"]; n = ENVIRON["NEW"] }
    { i = index($0, o)
      if (i) { hit = 1; if (n == "" && $0 == o) next; $0 = substr($0, 1, i - 1) n substr($0, i + length(o)) }
      print }
    END { exit !hit }
  ' "$OUT/$1" > "$OUT/$1.tmp" || { echo "build-claude: $1 no longer holds the text to rewrite: $2" >&2; exit 1; }
  mv "$OUT/$1.tmp" "$OUT/$1"
}
SWEEP_SHAPE='count the source files in any language (.ts, .py, .go, .rs, .sh, and the rest), skipping node_modules, .git, vendor, dist, build, target, and virtualenvs. Fewer than three, and no src, lib, app, scripts, pkg, internal, cmd, or source directory holding three or more files, is `greenfield`; anything else is `brownfield`'
rewrite commands/kickoff.md 'Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-bootstrap.sh --shape` — it prints `greenfield` or `brownfield` by the same rule as the session nudge.' "This edition ships no scripts, so work it out by hand: $SWEEP_SHAPE."
rewrite commands/kickoff.md 'whatever `--shape` printed' 'whatever the count says'
rewrite commands/onboard.md 'Mechanical sweep: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-bootstrap.sh` (silent when a profile exists and still holds). Fingerprint for the profile marker: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-bootstrap.sh --fingerprint`.' 'Mechanical sweep, by hand: this edition ships no scripts, so wherever onboard.md says the bootstrap, it means this sweep. List the manifests, lockfiles, package scripts, CI workflows, and `.claude` folder to point at §Commands and §Stack. For each secret-file name in the tree (`.env`, `.pem`, `.key`, credentials JSON), ask git whether it tracks or ignores it, never opening the file, and open with a 🚨 block for each one git tracks or a ⚠️ block for each one it does not ignore. Ask git too whether any real env file was ever committed (`git log --all --diff-filter=A --name-only`) and open with a 🚨 block for each, since its values need rotating even after it is gone. If real env files are on disk and no Claude Code settings file sets `sandbox.enabled` to true, offer once to merge into `.claude/settings.json` a `permissions.deny` entry `Read(./<file>)` and a `sandbox.filesystem.denyRead` entry `./<file>` for each: this edition ships no hook to stop a read, and `grep -r` or a dotenv loader reaches the file without naming it anyway. Merge nothing unless the user agrees. Skip the fingerprint marker: this edition runs no drift check.'
rewrite skills/documentation-architect/references/onboard.md '- Put `<!-- m-skills-fingerprint: <n> -->` under the title, with `<n>` from `profile-bootstrap.sh --fingerprint`, so drift detection works from the first session.' ''
rewrite skills/documentation-architect/references/onboard.md '**§Commands is machine-read** by `check-quality.sh` — keep' '**§Commands is the gate authority** every skill reads first — keep'
rewrite skills/guidelines-meta/PROJECT-PROFILE.template.md '> **This table is machine-read.** `check-quality.sh` parses these rows and treats them as the authority' '> **This table is the gate authority.** Every skill reads these rows first and treats them as the authority'
rewrite skills/implementing-architect/SKILL.md 'allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/check-quality.sh:*)' ''
rewrite skills/implementing-architect/SKILL.md '**One-shot alternative:** `bash ${CLAUDE_SKILL_DIR}/check-quality.sh` runs the same gates in the same order and prints a pass/fail report.' '**One-shot alternative:** none in this edition, which ships no scripts; the self-hosted install from matis-dev/m-skills adds a script that runs the same gates in one go.'
rewrite skills/implementing-architect/SKILL.md ' The variable resolves to this skill'"'"'s own directory in both plugin and copied installs, so the command is identical either way. Add `--list` to print which gates it resolved **without running any of them** — use that first when you'"'"'re unsure the profile is right.' ''

# The guards stay, as rules: every line that says a hook or guard denies the call is
# rewritten to say this edition ships none. The leftover-claim check below catches a new one.
GUARD_OLD='**Git and golden-file guards are enforced by the plugin'"'"'s PreToolUse hook** (Guidelines §9, §10): every git write, `gh` publish, `--no-verify`, and snapshot update is denied by the runtime; read-only inspection stays open.'
GUARD_NEW='**Git and golden-file guards are yours to hold** (Guidelines §9, §10): this edition ships no hooks, so nothing denies the call. Run no git write, `gh` publish, `--no-verify`, or snapshot update; read-only inspection stays open.'
for s in brainstorming-planner code-review-architect debugging-architect deployment-architect implementing-architect \
         maintenance-architect planning-architect product-architect rolling-history testing-architect; do
  rewrite "skills/$s/SKILL.md" "$GUARD_OLD" "$GUARD_NEW"
done
rewrite skills/guidelines-meta/SKILL.md 'the hook-enforced git and golden-file guards' 'the git and golden-file guards'
rewrite skills/guidelines-meta/SKILL.md '**Everything that writes is denied**' '**Everything that writes is off limits**'
rewrite skills/guidelines-meta/SKILL.md '*(This is enforced by the plugin'"'"'s `PreToolUse` hook, which denies the call outright. The list above describes what that hook actually does, so the prose and the enforcement cannot drift apart.)*' '*(This edition ships no hooks, so nothing denies these calls: the list above is the rule, and you hold it. The self-hosted install from matis-dev/m-skills adds hooks that block them.)*'
rewrite skills/implementing-architect/SKILL.md 'Constraint 1 is absolute and now mechanical.' 'Constraint 1 is absolute.'
rewrite skills/implementing-architect/SKILL.md ' — and the hook denies the call if you reach for it anyway.' '.'
rewrite skills/deployment-architect/SKILL.md ' Enforced by the plugin'"'"'s PreToolUse hook, which denies the call.' ''
rewrite skills/maintenance-architect/SKILL.md '; the hook denies it if you run it yourself.' '; never run it yourself.'
rewrite skills/debugging-architect/SKILL.md 'is a branch-moving operation and is denied like the rest' 'is a branch-moving operation and a git write like the rest'
rewrite skills/security-architect/SKILL.md ', and enforced by the plugin'"'"'s outward guard' ''
rewrite skills/security-architect/SKILL.md ' The plugin'"'"'s secret-file guard enforces both directions.' ''
rewrite skills/module-gate-battery/SKILL.md 'This is Guidelines §10 and it is enforced by the plugin'"'"'s git and snapshot guard, which denies the call.' 'This is Guidelines §10. This edition ships no hook to deny the call, so the stop is yours.'
rewrite skills/product-architect/SKILL.md ' The plugin'"'"'s outward guard denies `gh issue create` for this reason; a tracker with no CLI is the same rule on the honour system.' ' This edition ships no hook to deny `gh issue create`, so the rule holds on the honour system, as it does for a tracker with no CLI.'
rewrite skills/marketing-architect/SKILL.md ', and the plugin'"'"'s outward guard denies them at the runtime regardless of what was agreed in conversation.' ', so they stay the user'"'"'s to send whatever was agreed in conversation.'
rewrite skills/module-handover/SKILL.md ' The plugin'"'"'s git and outward guards deny these at the runtime, so this is not a rule you can forget your way past.' ' This edition ships no hook to deny them, so the rule holds only while you hold it.'
rewrite skills/module-handover/SKILL.md 'a pick would have you run it, and the guard denies that.' 'a pick would have you run it.'
rewrite commands/rollback.md ', and the plugin'"'"'s outward guard denies it at the runtime regardless.' ', whatever was said before.'
rewrite commands/spread.md '; the plugin'"'"'s outward guard enforces that at the runtime.' '.'
rewrite .claude-plugin/plugin.json ', with hooks that deny git writes, auto-accepted snapshot updates, and secret-file access.' ', with guards in every skill against git writes, auto-accepted snapshot updates, and secret-file access.'
rewrite .claude-plugin/marketplace.json 'and enforces the strictest guards \u2014 no staging or committing, no auto-accepted golden updates \u2014 with hooks rather than prose.' 'and holds the strictest guards \u2014 no staging or committing, no auto-accepted golden updates \u2014 as rules in every skill.'

# ── Directory checks ─────────────────────────────────────────────────────────
for f in $(cd "$OUT" && find . -type f | sed 's|^\./||' | sort); do
  case "$f" in
    *.md|*.txt|*.json|*.yaml|*.yml|*.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|LICENSE|README|.gitignore) ;;
    *) echo "  $f: not a type the directory accepts (Markdown, text, JSON, YAML, or an image)" >> "$PART/bad" ;;
  esac
  case "${f##*/}" in
    package.json|package-lock.json|npm-shrinkwrap.json|pnpm-workspace.yaml|pnpm-lock.yaml|yarn.lock|.yarnrc|.yarnrc.yml|bun.lock|bunfig.toml|deno.json|deno.jsonc)
      echo "  $f: a package-manager config" >> "$PART/bad" ;;
  esac
  [ "$(head -c2 "$OUT/$f")" = '#!' ] && echo "  $f: starts with #!" >> "$PART/bad"
  case "$f" in *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico) continue ;; esac
  tr -d '\000' < "$OUT/$f" | cmp -s - "$OUT/$f" || echo "  $f: holds a NUL byte" >> "$PART/bad"
  iconv -f UTF-8 -t UTF-8 < "$OUT/$f" > /dev/null 2>&1 || echo "  $f: is not UTF-8" >> "$PART/bad"
done
# allowed-tools (a skill's frontmatter) or allowedTools: inline, naming only these four.
grep -rnE '^[[:space:]]*"?(allowed-tools|allowedTools)"?[[:space:]]*:' "$OUT" \
  | grep -vE ':[[:space:]]*\[?[[:space:]]*((Read|Grep|Glob|LS)[[:space:]]*,?[[:space:]]*)+\]?[[:space:]]*$' \
  | sed "s|^$OUT/|  |; s|\$| — an allowed-tools entry beyond Read, Grep, Glob, and LS, or a list form the build cannot check|" >> "$PART/bad" || true
# No hook of any type: no hooks/ folder, and no manifest that declares hooks.
[ -e "$OUT/hooks" ] && echo "  hooks/: a hooks folder (the directory refuses hooks of every type)" >> "$PART/bad"
grep -nE '"hooks"[[:space:]]*:' "$OUT"/.claude-plugin/*.json \
  | sed "s|^$OUT/|  |; s|\$| — a manifest that declares hooks|" >> "$PART/bad" || true
# No text left that says a hook or guard denies a call: with no hooks, that is untrue.
# The planted-defect tests are the proof this pattern holds; it lives only here.
grep -rnE 'PreToolUse|denied by the runtime|enforced by the plugin|hook-enforced|hooks? (that )?den(y|ies)|guards? den(y|ies)|guards? enforces?|plugin'"'"'s [a-z-]+ guards?|at the runtime|with hooks rather than prose' \
  "$OUT/skills" "$OUT/commands" "$OUT/.claude-plugin" "$OUT/README.md" \
  | sed "s|^$OUT/|  |; s|\$| — says a hook enforces a guard, and this edition ships none|" >> "$PART/bad" || true
if [ -s "$PART/bad" ]; then
  { echo 'build-claude: the directory would refuse the built tree:'; cut -c1-220 "$PART/bad"; } >&2
  exit 1
fi

echo "Built $OUT (m-skills $VERSION)"
