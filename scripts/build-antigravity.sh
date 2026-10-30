#!/usr/bin/env bash
# m-skills — build the Antigravity (agy) plugin from this tree. One source, two hosts.
#
# Usage: bash scripts/build-antigravity.sh [out-dir]   (default: dist/antigravity/m-skills)
#
# What changes on the way out, and why — observed across agy 1.2.2 through 1.4.11 / Antigravity 2.0:
#   plugin.json + assets/icon.png + README.md + LICENSE + THIRD-PARTY-NOTICES.md + .gitattributes
#     self-contained Marketplace bundle matching https://antigravity.google/schemas/v1/plugin.json
#     (additionalProperties: false).
#   skills/   copied. agy CLI namespaces them as m-skills:<name> (App/IDE also expose /<name>),
#     and both honour disable-model-invocation. guidelines-meta/SKILL.md is trimmed below agy's
#     24,000-byte body cap by extracting §17 into references/reply-protocol.md (rewritten for
#     agy's ask_question schema) and replacing §9/§10 with pointers to rules/m-skills-guards.md.
#   commands/<name>.md → skills/<name>/SKILL.md, gated. `agy plugin validate` reports
#     commands "converted to skills", but none of them registers at runtime.
#     $ARGUMENTS            → a phrase        agy substitutes nothing in a skill body.
#     ${CLAUDE_SKILL_DIR}   → <this-skill>   agy exports no path variables, and a bare
#     ${CLAUDE_PLUGIN_ROOT} → <m-skills>     relative path breaks `bash …/check-quality.sh`
#                                           run from the project; the rule defines both.
#     AskUserQuestion       → ask_question   agy's picker tool (multiSelect → is_multi_select,
#                                           and Claude-only ExitPlanMode notes removed).
#   rules/m-skills-guards.md   always_on + description. Guidelines §9 and §10 and
#     security-architect constraints 5–6, quoted live, plus the slash-command / ask_question gate.
#   hooks.json   the three guards through antigravity-adapt.sh. agy reads it only at
#     the plugin root, runs it with the plugin root as cwd, and fires tool events only
#     when grouped as {matcher, hooks:[…]} — the flat form loads and never fires.
#   bash.cmd   from scripts/antigravity-bash.cmd, with CRLF endings. agy on Windows runs hooks
#     through `cmd /c`, which finds this file before any bash on PATH; it starts Git Bash,
#     or steps aside when there is none. Read only by cmd.
#   scripts/   the lib, the three guards, the adapter, and profile-bootstrap.sh for
#     /onboard, all shipped 0755 LF.

set -euo pipefail

ROOT="$(cd "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist/antigravity/m-skills}"

# The output is cleared with rm -rf, so it must be unmistakably a build directory.
case "$OUT" in
  */dist/antigravity/m-skills) ;;
  *) echo "build-antigravity: refusing to clear '$OUT' — the output path must end in /dist/antigravity/m-skills" >&2; exit 1 ;;
esac

# Read through tr: a clone made before .gitattributes keeps this unchanged file CRLF.
# shellcheck source=lib/hook-json.sh
. <(tr -d '\r' < "$ROOT/scripts/lib/hook-json.sh")

VERSION="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
[ -n "$VERSION" ] || { echo "build-antigravity: no version in .claude-plugin/plugin.json" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/assets" "$OUT/rules" "$OUT/scripts/lib"
cp -R "$ROOT/skills" "$OUT/"
cp "$ROOT/.claude-plugin/icon.png" "$OUT/assets/icon.png"
cp "$ROOT/README.antigravity.md" "$OUT/README.md"
cp "$ROOT/LICENSE" "$ROOT/THIRD-PARTY-NOTICES.md" "$ROOT/.gitattributes" "$OUT/"
cp "$ROOT/scripts/lib/hook-json.sh" "$OUT/scripts/lib/"
for s in guard-mutations.sh guard-outward.sh guard-secrets.sh antigravity-adapt.sh profile-bootstrap.sh; do
  cp "$ROOT/scripts/$s" "$OUT/scripts/"
done
# A CRLF script fails in bash on its first line — exit 2, which older agy treated as a block.
# .gitattributes pins *.sh to LF, but a Windows clone made with core.autocrlf before that
# file existed keeps CRLF in every script a later pull leaves unchanged. Ship them LF + 0755.
# tr and awk, not sed: BSD sed reads \r as a plain r.
for f in "$OUT/.gitattributes" "$OUT/README.md" "$OUT"/scripts/*.sh "$OUT"/scripts/lib/*.sh "$OUT"/skills/*/*.sh; do
  [ -f "$f" ] || continue
  tr -d '\r' < "$f" > "$f.lf" && cat "$f.lf" > "$f" && rm "$f.lf"
done
chmod +x "$OUT"/scripts/*.sh "$OUT"/skills/*/*.sh
# cmd misreads labels and blocks in an LF-only batch file, so this one ships CRLF.
awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$ROOT/scripts/antigravity-bash.cmd" > "$OUT/bash.cmd"

# A route command becomes a skill of the same name. It stays user-only, as a command is
# in Claude Code: its frontmatter gains the name and the gate, and its body is unchanged.
for c in "$ROOT"/commands/*.md; do
  name="$(basename "$c" .md)"
  mkdir -p "$OUT/skills/$name"
  awk -v name="$name" '
    { sub(/\r$/, "") }
    NR == 1 && /^---$/ { print; print "name: " name; print "disable-model-invocation: true"; next }
    { print }
  ' "$c" > "$OUT/skills/$name/SKILL.md"
done

# -i.bak works on both GNU and BSD sed; the backups are removed right after.
find "$OUT/skills" -name '*.md' -exec sed -i.bak \
  -e 's|\$ARGUMENTS|the text the user typed after the command|g' \
  -e 's|\${CLAUDE_SKILL_DIR}|<this-skill>|g' \
  -e 's|\${CLAUDE_PLUGIN_ROOT}|<m-skills>|g' \
  -e 's| — unless plan mode is active, where `ExitPlanMode` carries it||g' \
  -e 's|`multiSelect`|`is_multi_select`|g' \
  -e 's|AskUserQuestion|ask_question|g' {} +
find "$OUT" -name '*.bak' -delete

# Antigravity truncates any SKILL.md body above 24,000 bytes (and fails `agy plugin validate
# --strict`). Extract §17 into references/reply-protocol.md with Antigravity's native
# ask_question schema, and replace §9/§10 (quoted verbatim in rules/m-skills-guards.md) plus
# §17 with compact pointers so §18, §19, and Self-check load intact.
# The split keys on these lines; a reworded one would otherwise leak §18 onward into
# the reference, or drop it, with the build still green.
GM_OUT="$OUT/skills/guidelines-meta/SKILL.md"
for anchor in '### 9. ' '### 11. ' '### 17. ' '### 18. ' '- **Questions go in the picker, not the chat.**'; do
  tr -d '\r' < "$GM_OUT" | grep -qF -- "$anchor" \
    || { echo "build-antigravity: guidelines-meta/SKILL.md has no '$anchor' line to split on" >&2; exit 1; }
done
mkdir -p "$OUT/skills/guidelines-meta/references"
{
  printf '# Reference: Reply Protocol (§17)\n\n'
  printf '*`guidelines-meta` reference — full protocol and Antigravity `ask_question` contract.*\n\n'
  awk '
    { sub(/\r$/, "") }
    /^### 17\./ { on = 1 }
    on && /^- \*\*Questions go in the picker, not the chat\.\*\*/ { exit }
    on { print }
  ' "$GM_OUT"
  cat <<'EOF'
- **Questions go in the picker, not the chat.** When the user must choose among structured options, call `ask_question` (`questions: [{question, options, is_multi_select}]`) instead of writing a numbered menu into prose. Ask trivial yes/no questions in plain text. Shape `ask_question`:
  - **One call per pause**, batching related questions together. Never ask what the repo, the profile, or a sensible default already answers (§5.3).
  - **2–4 options**, unnumbered and without an *Other* option (the UI adds both); put your recommendation first, prefixed with `(Recommended) `, and include a short consequence on each option.
  - Set `is_multi_select: true` when choices are not mutually exclusive.
  - **No picker available** (for example inside a read-only subagent) → ask one question in prose with a numbered list, recommendation first.
  - **A pick that names a gated pipeline skill is the user starting it** — in `ask_question` or from the numbered fallback (`Approve → implementing-architect`, `Plan it → planning-architect`). Read `<this-skill>/../<name>/SKILL.md` and run it in full on the work under discussion: no paste line, no second confirm. A casual remark in chat is not a pick.
EOF
  awk '
    { sub(/\r$/, "") }
    /^- \*\*Break these rules when:\*\*/ { print }
    /^> Derived from \[ayghri\/i-have-adhd\]/ { print ""; print }
  ' "$GM_OUT"
} > "$OUT/skills/guidelines-meta/references/reply-protocol.md"

awk '
  { sub(/\r$/, "") }
  /^### 9\. / {
    print "### 9. Inherited Guards (Non-negotiable — STRICT)"
    print "- **Run no git command that writes, and no `gh` command that publishes.** No staging, no commits, no pushing, no branching, no `--no-verify`, no `--force`. Print the exact command for the user to paste instead. Full text is loaded every turn via `rules/m-skills-guards.md` and enforced by `PreToolUse` hooks."
    print ""
    print "### 10. Manual Golden / Snapshot Review"
    print "- **Never auto-accept a golden-file or visual-snapshot update** (`--update-snapshots`, `-u`, `--accept`, `UPDATE_SNAPSHOTS=1`). Surface the diff and report path, then stop for manual user review (`rules/m-skills-guards.md`)."
    print ""
    skip = 9; next
  }
  skip == 9 && /^### 11\. / { skip = 0 }
  /^### 17\. / {
    print "### 17. Reply Protocol (how output is shaped)"
    print "- **Lead with the action or answer**, number multi-step instructions, show at most 5 items per group (dropping none where completeness is the deliverable), end with one concrete next step, and omit filler openers, recaps, and closing pleasantries."
    print "- **Structured choices use `ask_question`** (`questions: [{question, options, is_multi_select}]`, recommended option first prefixed with `(Recommended) `); ask trivial yes/no questions in plain text. Picking an option that carries a gated skill'\''s exact name (`Approve → implementing-architect`) starts that skill — read `<this-skill>/../<name>/SKILL.md` and run it in full."
    print "- Read `<this-skill>/references/reply-protocol.md` for the full 10-rule protocol, compression discipline, pre-send check, and break-the-rules cases."
    print ""
    skip = 17; next
  }
  skip == 17 && /^### 18\. / { skip = 0 }
  !skip { print }
' "$GM_OUT" > "$GM_OUT.tmp" && mv "$GM_OUT.tmp" "$GM_OUT"

# Listing metadata comes from the Claude manifests, so the two listings cannot drift.
CPJ="$(tr -d '\r' < "$ROOT/.claude-plugin/plugin.json")"
MPJ="$(tr -d '\r' < "$ROOT/.claude-plugin/marketplace.json")"
KEYWORDS=""; i=0
while kw="$(json_field "$CPJ" "keywords.$i")"; [ -n "$kw" ]; do
  KEYWORDS="$KEYWORDS${KEYWORDS:+,}
    $(json_string "$kw")"
  i=$((i + 1))
done
for v in "$KEYWORDS" "$(json_field "$CPJ" homepage)" "$(json_field "$CPJ" license)" "$(json_field "$MPJ" owner.url)"; do
  [ -n "$v" ] || { echo "build-antigravity: .claude-plugin manifests lack keywords, homepage, license, or owner.url" >&2; exit 1; }
done

cat > "$OUT/plugin.json" <<EOF
{
  "\$schema": "https://antigravity.google/schemas/v1/plugin.json",
  "name": "m-skills",
  "displayName": "m-skills — portable dev pipeline",
  "description": "Portable brainstorm-plan-implement-review-document pipeline for any repo, with PreToolUse hooks and always-on guards for git, secrets, and deploys.",
  "version": "$VERSION",
  "logo": "assets/icon.png",
  "suggestedPrompts": [
    "Run /onboard to inspect this repository and generate .claude/PROJECT-PROFILE.md.",
    "Run /planning-architect to design an implementation plan before writing code.",
    "Run /security-audit to review this codebase against OWASP Top 10:2025."
  ],
  "author": {
    "name": $(json_string "$(json_field "$MPJ" owner.name)"),
    "url": $(json_string "$(json_field "$MPJ" owner.url)")
  },
  "homepage": $(json_string "$(json_field "$CPJ" homepage)"),
  "repository": $(json_string "$(json_field "$CPJ" repository)"),
  "license": $(json_string "$(json_field "$CPJ" license)"),
  "keywords": [$KEYWORDS
  ]
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
          { "type": "command", "command": "bash scripts/antigravity-adapt.sh guard-mutations.sh", "timeout": 30 },
          { "type": "command", "command": "bash scripts/antigravity-adapt.sh guard-outward.sh", "timeout": 30 }
        ]
      },
      {
        "matcher": "run_command|view_file|read_file|write_to_file|write_file|replace_file_content|multi_replace_file_content|edit_file|grep_search",
        "hooks": [
          { "type": "command", "command": "bash scripts/antigravity-adapt.sh guard-secrets.sh", "timeout": 30 }
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
SECURITY="$(tr -d '\r' < "$ROOT/skills/security-architect/SKILL.md" \
  | awk '/^## Operational Constraints/ { on = 1 } on && /^---$/ { exit } on && /^[56]\. / { print }')"

cat > "$OUT/rules/m-skills-guards.md" <<EOF
---
trigger: always_on
description: Enforces m-skills git, snapshot, secret, and outward-action guards, defines <this-skill> and <m-skills> paths, and gates user-only pipeline skills.
---

# m-skills — standing rules

Generated by scripts/build-antigravity.sh from the m-skills sources. Edit those, not this file.

## Paths inside m-skills skills

- \`<this-skill>\` is the folder holding the SKILL.md you are following. Use its absolute path when running a command from it.
- \`<m-skills>\` is the m-skills plugin folder: one level above this \`rules/m-skills-guards.md\` file, or two levels above any m-skills \`SKILL.md\` (the folder that contains \`skills/guidelines-meta/\`).

## Pipeline skills start only when the user invokes them

${GATED}— in Antigravity App and IDE these also appear without the prefix (\`/<name>\`, e.g. \`/planning-architect\`, \`/decompose\`). Each of these runs **only** when the user types its slash command **or** selects an \`ask_question\` option carrying its exact name (such as \`Approve → implementing-architect\` or \`Plan it → planning-architect\`). When picked via \`ask_question\`, read \`<m-skills>/skills/<name>/SKILL.md\` and run it in full without asking a second time. Never start one unprompted; when one clearly fits, say which in one line and give the exact command to paste (or offer it in \`ask_question\` at a stage handover).

## Guards

Where agy runs the m-skills hooks, a hook denies each of these. Where it runs none, nothing checks them: they hold only because you follow them.

$(m_skills_section "$GUIDELINES" 9 | tr -d '\r')

$(m_skills_section "$GUIDELINES" 10 | tr -d '\r')

### Secrets and outward actions (security-architect)

${SECURITY}
EOF

echo "Built $OUT (m-skills $VERSION)"
