#!/usr/bin/env bash
# m-skills — build the OpenAI Codex plugin from this tree. One source, three hosts.
#
# Usage: bash scripts/build-codex.sh [out-dir]   (default: dist/codex/m-skills)
#
# What changes on the way out, and why — each from codex-cli 0.159.0 as observed on
# 2026-09-29, not its docs:
#   .codex-plugin/plugin.json   the manifest; skills from ./skills/, hooks found at
#     hooks/hooks.json without being named.
#   skills/   copied. Codex namespaces them as m-skills:<name> and starts one when the
#     user types $m-skills:<name>. A gated skill gets agents/openai.yaml with
#     policy.allow_implicit_invocation: false — Codex then leaves it out of the model's
#     skill list entirely, which is what disable-model-invocation does in Claude Code.
#   commands/<name>.md → skills/<name>/SKILL.md, gated the same way. Codex has no
#     plugin commands.
#     $ARGUMENTS            → a phrase        Codex substitutes nothing in a skill body.
#     ${CLAUDE_SKILL_DIR}   → <this-skill>   exported to hooks only, never to skill text;
#     ${CLAUDE_PLUGIN_ROOT} → <m-skills>     the Codex section below defines both.
#     /m-skills:<name>      → $m-skills:<name>
#     AskUserQuestion       → request_user_input   Plan mode only; the Codex section
#                                                  points everywhere else at §17's fallback.
#   hooks/hooks.json   the three guards on Bash, which Codex sends in Claude Code's own
#     shape, and codex-adapt.sh on apply_patch. Hooks run in the session's cwd, so every
#     command goes through $PLUGIN_ROOT — a relative path exits 127, and Codex runs the
#     tool anyway when a hook fails. None of them runs until the user trusts it in /hooks.
#   A "Running under Codex" section appended to guidelines-meta, which every architect
#     loads first: the placeholders, the gated skills and their $ lines, and the guards
#     restated for a session whose hooks are not trusted yet. Codex plugins ship no
#     always-on rule.
#   scripts/   the lib, the three guards, the adapter, and profile-bootstrap.sh for
#     /onboard. The SessionStart hooks and the advisories stay behind for now.

set -euo pipefail

ROOT="$(cd "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist/codex/m-skills}"

# The output is cleared with rm -rf, so it must be unmistakably a build directory.
case "$OUT" in
  */dist/codex/m-skills) ;;
  *) echo "build-codex: refusing to clear '$OUT' — the output path must end in /dist/codex/m-skills" >&2; exit 1 ;;
esac

# shellcheck source=lib/hook-json.sh
. "$ROOT/scripts/lib/hook-json.sh"

VERSION="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
[ -n "$VERSION" ] || { echo "build-codex: no version in .claude-plugin/plugin.json" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/.codex-plugin" "$OUT/hooks" "$OUT/scripts/lib"
cp -R "$ROOT/skills" "$OUT/"
cp "$ROOT/scripts/lib/hook-json.sh" "$OUT/scripts/lib/"
for s in guard-mutations.sh guard-outward.sh guard-secrets.sh codex-adapt.sh profile-bootstrap.sh; do
  cp "$ROOT/scripts/$s" "$OUT/scripts/"
done

# A route command becomes a skill of the same name, user-only as a command is in Claude Code.
for c in "$ROOT"/commands/*.md; do
  name="$(basename "$c" .md)"
  mkdir -p "$OUT/skills/$name"
  awk -v name="$name" '
    NR == 1 && /^---$/ { print; print "name: " name; print "disable-model-invocation: true"; next }
    { print }
  ' "$c" > "$OUT/skills/$name/SKILL.md"
done

# Codex ignores disable-model-invocation; this is the key it reads instead.
GATED=""
for f in "$OUT"/skills/*/SKILL.md; do
  grep -q '^disable-model-invocation: true' "$f" || continue
  d="$(dirname "$f")"
  mkdir -p "$d/agents"
  printf 'policy:\n  allow_implicit_invocation: false\n' > "$d/agents/openai.yaml"
  GATED="$GATED\`\$m-skills:$(basename "$d")\` "
done

# -i.bak works on both GNU and BSD sed; the backups are removed right after.
find "$OUT/skills" -name '*.md' -exec sed -i.bak \
  -e 's|\$ARGUMENTS|the text the user typed after the skill name|g' \
  -e 's|\${CLAUDE_SKILL_DIR}|<this-skill>|g' \
  -e 's|\${CLAUDE_PLUGIN_ROOT}|<m-skills>|g' \
  -e 's|/m-skills:|$m-skills:|g' \
  -e 's|AskUserQuestion|request_user_input|g' {} +
find "$OUT" -name '*.bak' -delete

cat > "$OUT/.codex-plugin/plugin.json" <<EOF
{
  "name": "m-skills",
  "version": "$VERSION",
  "description": "The m-skills pipeline for Codex: brainstorm, plan, implement, review, document, plus design, testing, docs, slicing, debugging, release and upkeep when needed. Resolved per project from a PROJECT-PROFILE.md. Git, snapshot, secret and outward guards are enforced by hooks once trusted in /hooks.",
  "skills": "./skills/"
}
EOF

# Codex installs only from a marketplace, so the build writes a one-entry one beside the
# plugin: `codex plugin marketplace add dist/codex`, then `codex plugin add m-skills@m-skills-local`.
mkdir -p "$OUT/../.agents/plugins"
cat > "$OUT/../.agents/plugins/marketplace.json" <<'EOF'
{
  "name": "m-skills-local",
  "interface": { "displayName": "m-skills (local build)" },
  "plugins": [
    {
      "name": "m-skills",
      "source": { "source": "local", "path": "./m-skills" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
EOF

cat > "$OUT/hooks/hooks.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "^Bash$",
        "hooks": [
          { "type": "command", "command": "bash \"$PLUGIN_ROOT/scripts/guard-mutations.sh\"", "timeout": 10, "statusMessage": "m-skills: checking git and golden-file guards..." },
          { "type": "command", "command": "bash \"$PLUGIN_ROOT/scripts/guard-outward.sh\"", "timeout": 5, "statusMessage": "m-skills: checking for outward-facing actions..." },
          { "type": "command", "command": "bash \"$PLUGIN_ROOT/scripts/guard-secrets.sh\"", "timeout": 5, "statusMessage": "m-skills: checking for secret-bearing paths..." }
        ]
      },
      {
        "matcher": "^apply_patch$",
        "hooks": [
          { "type": "command", "command": "bash \"$PLUGIN_ROOT/scripts/codex-adapt.sh\"", "timeout": 10, "statusMessage": "m-skills: checking patched paths for secrets..." }
        ]
      }
    ]
  }
}
EOF

SECURITY="$(awk '/^## Operational Constraints/ { on = 1 } on && /^---$/ { exit } on && /^[56]\. / { print }' \
  "$ROOT/skills/security-architect/SKILL.md")"

cat >> "$OUT/skills/guidelines-meta/SKILL.md" <<EOF

---

## Running under Codex

Generated by scripts/build-codex.sh from the m-skills sources. Edit those, not this section.

- **Paths.** \`<this-skill>\` is the folder holding the SKILL.md you are following; \`<m-skills>\` is the m-skills plugin folder, two levels above any m-skills SKILL.md (the folder that contains \`skills/guidelines-meta/\`). Use absolute paths when running a command from either.
- **Pipeline skills start only when the user types them.** ${GATED}— Codex hides these from you. Never start one yourself; when one clearly fits, say which in one line and give the exact line to paste.
- **Questions.** \`request_user_input\` exists only in Plan mode. Anywhere else, §17's *No picker available* rule applies: one question in chat, options as a numbered list, recommendation first.
- **Guards.** Hooks deny git writes, snapshot updates, secret-file reads and writes, and outward actions — but only after the user trusts the m-skills hooks in \`/hooks\`. Until then nothing checks them, and a hook that fails to start does not block the call. §9 and §10 above hold either way, and so do these two:

${SECURITY}
EOF

echo "Built $OUT (m-skills $VERSION)"
