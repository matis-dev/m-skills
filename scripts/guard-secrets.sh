#!/usr/bin/env bash
# m-skills — PreToolUse guard for secret-bearing files.
#
# Enforces security-architect constraint 5 ("never write a real secret into a
# tracked file — including in an example"), which was prose only.
#
# WRITES are denied; READS are untouched. That asymmetry is load-bearing, not a
# softening: guidelines-meta §5 tells skills to read the env contract,
# deployment-architect Phase 0 depends on it, and profile-bootstrap.sh already
# scans for .env.example. A guard that blocked reads would break the pack itself.
#
# Example files (.env.example / .sample / .template / .dist) are never blocked in
# either direction — they are the documented, secret-free contract.
#
# Opt out with .claude/.m-skills-no-guards. Fails CLOSED.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

TOOL="$(json_field "$INPUT" "tool_name")"

# The documented, secret-free contract files. Checked first — they always pass.
EXAMPLE='\.(example|sample|template|dist|defaults?)$|(^|/)(env|\.env)\.(example|sample|template|dist)$'

# Real secret-bearing paths.
SECRET='(^|/)\.env(\.[A-Za-z0-9_-]+)?$|\.(pem|key|p12|pfx|jks|keystore)$|(^|/)id_(rsa|dsa|ecdsa|ed25519)$|(^|/)(credentials|service-account|serviceAccountKey|gha-creds.*)\.json$|(^|/)\.npmrc$|(^|/)\.pypirc$|(^|/)\.netrc$'

deny_path() {
  emit_deny "Blocked by m-skills (security-architect constraint 5): writing to \`$1\` risks putting a real credential in a tracked file. Placeholders only, and secrets belong in the environment, not in the repo. Reading this file is still allowed, as are .env.example / .sample / .template in both directions. If you are editing a genuinely secret-free file, rename it to an example variant — or opt out with: touch .claude/.m-skills-no-guards"
}

case "$TOOL" in
  Write|Edit|NotebookEdit)
    # NotebookEdit sends notebook_path, not file_path. Reading only file_path made
    # this arm dead code — a guard the header claims and the case never ran.
    FILE="$(json_field "$INPUT" "tool_input.file_path")"
    [ -z "$FILE" ] && FILE="$(json_field "$INPUT" "tool_input.notebook_path")"
    [ -z "$FILE" ] && exit 0
    printf '%s' "$FILE" | grep -Eq "$EXAMPLE" && exit 0
    printf '%s' "$FILE" | grep -Eq "$SECRET" && deny_path "$FILE"
    ;;
  Bash)
    CMD="$(json_field "$INPUT" "tool_input.command")"
    [ -z "$CMD" ] && exit 0
    # Only redirections and in-place edits into a secret file. Reading one
    # (cat, grep, source) stays allowed on purpose.
    TARGET="$(printf '%s' "$CMD" \
      | grep -Eo '(>>?[[:space:]]*|tee[[:space:]]+(-a[[:space:]]+)?|sed[[:space:]]+-i[^|;&]*[[:space:]])[^[:space:];|&)]+' \
      | grep -Eo '[^[:space:]>]+$' | grep -Ev "$EXAMPLE" | grep -E "$SECRET" | head -1)"
    [ -n "$TARGET" ] && deny_path "$TARGET"
    ;;
esac

exit 0
