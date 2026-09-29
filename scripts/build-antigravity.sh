#!/usr/bin/env bash
# m-skills — build the Antigravity (agy) plugin from this tree. One source, two hosts.
#
# Usage: bash scripts/build-antigravity.sh [out-dir]   (default: dist/antigravity/m-skills)
#
# What changes on the way out, and why — each from agy 1.2.2 as observed, not its docs:
#   skills/   copied. agy namespaces them as m-skills:<name>, like Claude Code, and
#     honours disable-model-invocation (its /skills listing reports model_invocable).
#   commands/<name>.md → skills/<name>/SKILL.md, gated. `agy plugin validate` reports
#     commands "converted to skills", but none of them registers at runtime.
#     $ARGUMENTS            → a phrase        agy substitutes nothing in a skill body.
#     ${CLAUDE_SKILL_DIR}   → <this-skill>   agy exports no path variables, and a bare
#     ${CLAUDE_PLUGIN_ROOT} → <m-skills>     relative path breaks `bash …/check-quality.sh`
#                                           run from the project; the rule defines both.
#     AskUserQuestion       → ask_question   agy's picker tool.
#   rules/m-skills-guards.md   always_on. Guidelines §9 and §10 and security-architect
#     constraints 5–6, quoted live, plus the start-only-when-typed gate. It is the only
#     protection in the IDE, which runs no hooks.
#   hooks.json   the three guards through antigravity-adapt.sh. agy reads it only at
#     the plugin root, runs it with the plugin root as cwd, and fires tool events only
#     when grouped as {matcher, hooks:[…]} — the flat form loads and never fires.
#   scripts/   the lib, the three guards, the adapter, and profile-bootstrap.sh for
#     /onboard. The advisories and SessionStart hooks stay behind: agy has no event
#     that could carry them.

set -euo pipefail

ROOT="$(cd "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist/antigravity/m-skills}"

# The output is cleared with rm -rf, so it must be unmistakably a build directory.
case "$OUT" in
  */dist/antigravity/m-skills) ;;
  *) echo "build-antigravity: refusing to clear '$OUT' — the output path must end in /dist/antigravity/m-skills" >&2; exit 1 ;;
esac

# shellcheck source=lib/hook-json.sh
. "$ROOT/scripts/lib/hook-json.sh"

VERSION="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
[ -n "$VERSION" ] || { echo "build-antigravity: no version in .claude-plugin/plugin.json" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/rules" "$OUT/scripts/lib"
cp -R "$ROOT/skills" "$OUT/"
cp "$ROOT/scripts/lib/hook-json.sh" "$OUT/scripts/lib/"
for s in guard-mutations.sh guard-outward.sh guard-secrets.sh antigravity-adapt.sh profile-bootstrap.sh; do
  cp "$ROOT/scripts/$s" "$OUT/scripts/"
done

# A route command becomes a skill of the same name. It stays user-only, as a command is
# in Claude Code: its frontmatter gains the name and the gate, and its body is unchanged.
for c in "$ROOT"/commands/*.md; do
  name="$(basename "$c" .md)"
  mkdir -p "$OUT/skills/$name"
  awk -v name="$name" '
    NR == 1 && /^---$/ { print; print "name: " name; print "disable-model-invocation: true"; next }
    { print }
  ' "$c" > "$OUT/skills/$name/SKILL.md"
done

# -i.bak works on both GNU and BSD sed; the backups are removed right after.
find "$OUT/skills" -name '*.md' -exec sed -i.bak \
  -e 's|\$ARGUMENTS|the text the user typed after the command|g' \
  -e 's|\${CLAUDE_SKILL_DIR}|<this-skill>|g' \
  -e 's|\${CLAUDE_PLUGIN_ROOT}|<m-skills>|g' \
  -e 's|AskUserQuestion|ask_question|g' {} +
find "$OUT" -name '*.bak' -delete

cat > "$OUT/plugin.json" <<EOF
{
  "name": "m-skills",
  "description": "The m-skills pipeline for Antigravity: brainstorm, plan, implement, review, document, plus design, testing, docs, slicing, debugging, release and upkeep when needed. Resolved per project from a PROJECT-PROFILE.md. Git, snapshot, secret and outward guards are enforced by hooks in the agy CLI and stated as a rule in the IDE.",
  "version": "$VERSION"
}
EOF

cat > "$OUT/hooks.json" <<'EOF'
{
  "m-skills-guards": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          { "type": "command", "command": "bash scripts/antigravity-adapt.sh guard-mutations.sh", "timeout": 10 },
          { "type": "command", "command": "bash scripts/antigravity-adapt.sh guard-outward.sh", "timeout": 5 }
        ]
      },
      {
        "matcher": "run_command|view_file|write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [
          { "type": "command", "command": "bash scripts/antigravity-adapt.sh guard-secrets.sh", "timeout": 5 }
        ]
      }
    ]
  }
}
EOF

GUIDELINES="$ROOT/skills/guidelines-meta/SKILL.md"
GATED="$(
  for f in "$ROOT"/skills/*/SKILL.md; do
    grep -q '^disable-model-invocation: true' "$f" && printf '`/m-skills:%s` ' "$(basename "$(dirname "$f")")"
  done
  for f in "$ROOT"/commands/*.md; do printf '`/m-skills:%s` ' "$(basename "$f" .md)"; done
)"
SECURITY="$(awk '/^## Operational Constraints/ { on = 1 } on && /^---$/ { exit } on && /^[56]\. / { print }' \
  "$ROOT/skills/security-architect/SKILL.md")"

cat > "$OUT/rules/m-skills-guards.md" <<EOF
---
trigger: always_on
---

# m-skills — standing rules

Generated by scripts/build-antigravity.sh from the m-skills sources. Edit those, not this file.

## Paths inside m-skills skills

- \`<this-skill>\` is the folder holding the SKILL.md you are following. Use its absolute path when running a command from it.
- \`<m-skills>\` is the m-skills plugin folder: two levels above any m-skills SKILL.md (the folder that contains \`skills/guidelines-meta/\`).

## Pipeline skills start only when the user types them

${GATED}— each of these runs only when the user types its slash command. Never start one yourself. When one clearly fits, say which in one line and give the exact line to paste.

## Guards

In the agy CLI a hook denies each of these. In the Antigravity IDE nothing checks them: they hold only because you follow them.

$(m_skills_section "$GUIDELINES" 9)

$(m_skills_section "$GUIDELINES" 10)

### Secrets and outward actions (security-architect)

${SECURITY}
EOF

echo "Built $OUT (m-skills $VERSION)"
