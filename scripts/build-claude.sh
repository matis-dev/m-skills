#!/usr/bin/env bash
# m-skills — build the tree the Claude plugin directory follows. One source, three hosts.
#
# Usage: bash scripts/build-claude.sh [out-dir]   (default: dist/claude/m-skills)
#
# The directory's validator follows a hook's script only when that script is
# self-contained: it loads no other file, runs no other script, and holds no
# here-document. A script that does any of those holds every version for a reviewer
# ("Scripts the validator couldn't follow"). The sources on main stay multi-file and
# commented; this build compiles each hook script into one file:
#   the library load        → the library itself, in place
#   check-quality.sh --list → m_skills_gate_table, the resolver as a subshell function
#   | bash skill-preamble.sh → m_skills_preamble, the preamble as a subshell function
#   comment lines that name a .sh file are dropped; every other comment is kept
# A subshell function keeps a child process's exit, cd, and variables to itself.
#
# What ships: the manifests and icon, skills/, commands/, hooks/hooks.json, the
# compiled hook scripts, LICENSE, THIRD-PARTY-NOTICES.md, and README.release.md as
# README.md. Tests, the changelog, the templates, the library, and the build and
# adapter scripts stay on main: nothing an installed plugin runs needs them.

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

LIB="$ROOT/scripts/lib/hook-json.sh"
CQ="$ROOT/skills/implementing-architect/check-quality.sh"
SP="$ROOT/scripts/skill-preamble.sh"
PART="$(mktemp -d)"; trap 'rm -rf "$PART"' EXIT

# Comment lines that name a script read to the validator as a call to that script.
drop_script_comments() { awk '!(/^[[:space:]]*#/ && /[A-Za-z0-9_-]\.sh([^A-Za-z0-9_]|$)/)'; }

# compile <file> <lib-part-or-empty> <defs-part-or-empty>
#   inlines the library at its load line, puts the function definitions right after
#   the script's `set -…u… pipefail`, and turns the two script calls into those functions.
compile() {
  awk -v lib="$2" -v defs="$3" '
    function cat(f,   l) { while ((getline l < f) > 0) print l; close(f) }
    /^[[:space:]]*\. "[^"]*\/lib\/hook-json\.sh" 2>\/dev\/null \|\| (exit|return) 0$/ {
      if (lib != "") cat(lib)
      next
    }
    !placed && /^set -[a-z]*u[a-z]* pipefail$/ {
      print
      if (defs != "") cat(defs)
      placed = 1
      next
    }
    {
      gsub(/bash "\$(DIR\/\.\.|PLUGIN)\/skills\/implementing-architect\/check-quality\.sh"/, "m_skills_gate_table")
      gsub(/bash "\$DIR\/skill-preamble\.sh"/, "m_skills_preamble")
      print
    }
  ' "$1" | drop_script_comments
}

tail -n +2 "$LIB" | drop_script_comments > "$PART/lib"

# The gate resolver reads its gates from the environment first. A child process sees
# only exported variables; a subshell function sees the caller's own as well, so the
# function starts by unsetting any copy the caller did not export.
# Hooks only ever ask it for --list, so it is inlined up to the end of that branch.
# The part after it RUNS each gate, a command computed at run time, which the
# validator blocks as an unpinned launcher when `uv run` sits beside it.
{
  echo 'm_skills_gate_table() ('
  echo '  for v in LINT TYPECHECK TEST BUILD E2E VISUAL A11Y AUDIT VISUAL_REPORT UPDATE_CMD; do'
  echo '    [[ "$(declare -p "$v" 2>/dev/null)" =~ ^declare\ -[a-zA-Z]*x ]] || unset "$v"'
  echo '  done'
  tail -n +2 "$CQ" | drop_script_comments \
    | awk '{ print } /^if \[ "\$\{1:-\}" = "--list" \]; then$/ { list = 1 } list && /^fi$/ { exit }'
  echo ')'
} > "$PART/gate"
grep -q '^if \[ "${1:-}" = "--list" \]; then$' "$PART/gate" \
  || { echo "build-claude: check-quality.sh has no --list branch to stop at" >&2; exit 1; }

# The preamble runs inside enforce-picks.sh, which has already loaded the library.
{
  echo 'm_skills_preamble() ('
  tail -n +2 "$SP" | compile /dev/stdin "" ""
  echo ')'
} > "$PART/preamble"
cat "$PART/gate" "$PART/preamble" > "$PART/gate+preamble"

rm -rf "$OUT"
mkdir -p "$OUT/.claude-plugin" "$OUT/hooks" "$OUT/scripts"
cp "$ROOT/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json" "$ROOT/.claude-plugin/icon.png" "$OUT/.claude-plugin/"
cp -R "$ROOT/skills" "$ROOT/commands" "$OUT/"
cp "$ROOT/hooks/hooks.json" "$OUT/hooks/"
cp "$ROOT/LICENSE" "$ROOT/THIRD-PARTY-NOTICES.md" "$OUT/"
cp "$ROOT/README.release.md" "$OUT/README.md"

# Every script hooks.json runs, and nothing else from scripts/.
for s in $(grep -oE 'scripts/[a-z-]+\.sh' "$ROOT/hooks/hooks.json" | sort -u); do
  src="$ROOT/$s"
  defs=""
  grep -q 'skill-preamble\.sh"' "$src" && defs="$PART/gate+preamble"
  [ -z "$defs" ] && grep -q 'check-quality\.sh" --list' "$src" && defs="$PART/gate"
  compile "$src" "$PART/lib" "$defs" > "$OUT/$s"
  chmod +x "$OUT/$s"
done

# Refuse to ship a script the validator could not follow, or one that does not parse.
fail=""
for f in "$OUT"/scripts/*.sh; do
  rel="${f#$OUT/}"
  bash -n "$f" 2>/dev/null || fail="$fail\n  $rel: does not parse"
  grep -nE '<<[^<]|<<$' "$f" | grep -v '<<<' | sed "s|^|  $rel: here-document at |" >> "$PART/bad" || true
  grep -nE '^[[:space:]]*(\.|source)[[:space:]]' "$f" | sed "s|^|  $rel: loads a file at |" >> "$PART/bad" || true
  grep -nE '(^|[^A-Za-z0-9_])(ba)?sh[[:space:]]+"\$' "$f" | sed "s|^|  $rel: runs a script at |" >> "$PART/bad" || true
  grep -nE '(^|[^A-Za-z0-9_])(ba)?sh([[:space:]]+-[a-z]+([[:space:]]+[a-z]+)?)*[[:space:]]+-c[[:space:]]+"\$' "$f" \
    | sed "s|^|  $rel: runs a computed command at |" >> "$PART/bad" || true
  grep -nE '[A-Za-z0-9_-]\.sh([^A-Za-z0-9_]|$)' "$f" | sed "s|^|  $rel: names a script at |" >> "$PART/bad" || true
done
if [ -n "$fail" ] || [ -s "$PART/bad" ]; then
  { printf 'build-claude: the built tree would hold the plugin for review:'; printf "$fail"; echo; cut -c1-160 "$PART/bad"; } >&2
  exit 1
fi

echo "Built $OUT (m-skills $VERSION)"
