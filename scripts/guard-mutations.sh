#!/usr/bin/env bash
# m-skills — PreToolUse guard for Bash. Enforces guidelines-meta §9 and §10.
#
# These two rules are restated in eleven skill files and, before this hook, enforced
# nowhere: settings.template.json is a template the user must copy, and its prefix
# matching cannot see inside `&&` chains or `bash -c "…"` anyway. Prose only binds
# when the model has that file in context; this binds always.
#
# Three families, one process spawn:
#   §9  git mutation      → deny   (add/commit/push/branch/reset/--no-verify/…)
#   §10 golden updates    → deny   (static patterns + the PROJECT'S resolved command)
#   catastrophic fs ops   → deny   (rm -rf /, mkfs, dd of=/dev/…)
#
# The third family converts no existing instruction — it is additive scope, kept
# because it is four lines here and the failure mode is unrecoverable.
#
# Opt out with .claude/.m-skills-no-guards (project) or in $CLAUDE_CONFIG_DIR (global).
# Fails CLOSED: an unverifiable guard denies rather than waving the command through.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

CMD="$(json_field "$INPUT" "tool_input.command")"
[ -z "$CMD" ] && exit 0

OPTOUT_LINE="Opt out for this project with: touch .claude/.m-skills-no-guards"

# ── §9 — git mutation ────────────────────────────────────────────────────────
# Tolerate interposed flags so `git -C /path commit` and `git --git-dir=x push`
# are caught, and scan the whole string so `&&`, `;`, and `bash -c "…"` are too.
# This is the class the prefix-matching deny list in settings.template.json misses.
GIT_PREFIX='(^|[^[:alnum:]_./-])git([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--[^[:space:]]+=[^[:space:]]+|--no-pager|--paginate|--bare|--literal-pathspecs))*[[:space:]]+'

# Always mutating. No read-only form exists.
GIT_HARD='(add|stage|commit|push|checkout|switch|reset|rebase|cherry-pick|revert|clean|am|mv|rm|merge|pull|fetch|gc|prune|filter-branch|update-ref|symbolic-ref|restore)'

# Mutating only in some forms. Listing branches, tags, remotes, worktrees, and
# stashes is read-only and genuinely useful — denying it would send people to the
# opt-out, which defeats the guard entirely. Each pattern below matches only the
# writing form: a destructive flag, or a bare name where a name means "create".
GIT_SOFT='(branch[[:space:]]+(-[dDmMcC]([[:space:]]|$)|--(delete|move|copy|set-upstream-to|unset-upstream|edit-description)|[^-[:space:]])|tag[[:space:]]+(-[adsfD]([[:space:]]|$)|--(delete|force|annotate|sign)|[^-[:space:]])|remote[[:space:]]+(add|remove|rm|rename|set-url|set-head|prune)|worktree[[:space:]]+(add|remove|move|prune|lock)|submodule[[:space:]]+(add|update|init|deinit|sync|set-url)|stash([[:space:]]+(push|pop|apply|drop|clear|save|create|store)([[:space:]]|$)|[[:space:]]*$))'

GIT_DENIED=""
if printf '%s' "$CMD" | grep -Eq "${GIT_PREFIX}${GIT_HARD}([^[:alnum:]_-]|\$)"; then
  GIT_DENIED="$(printf '%s' "$CMD" | grep -Eo "${GIT_PREFIX}${GIT_HARD}([^[:alnum:]_-]|\$)" | grep -Eo "${GIT_HARD}" | head -1)"
elif printf '%s' "$CMD" | grep -Eq "${GIT_PREFIX}${GIT_SOFT}"; then
  GIT_DENIED="$(printf '%s' "$CMD" | grep -Eo "${GIT_PREFIX}${GIT_SOFT}" | grep -oE '(branch|tag|remote|worktree|submodule|stash)' | head -1)"
fi

if [ -n "$GIT_DENIED" ]; then
  emit_deny "Blocked by m-skills (Guidelines §9): \`git ${GIT_DENIED}\` mutates the repository, and staging, committing, pushing, and branching are user-only — no exceptions, including when the user says \"ship it\". Leave the changes unstaged and hand the user the command to run themselves. Read-only git stays open: status, diff, log, show, blame, rev-parse, and the listing forms of branch/tag/remote/stash. ${OPTOUT_LINE}"
fi

# --no-verify / --no-gpg-sign are git-only flags; their presence anywhere is the rule break.
if printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])--(no-verify|no-gpg-sign)([[:space:]]|=|$)'; then
  emit_deny "Blocked by m-skills (Guidelines §9): skipping hooks with --no-verify / --no-gpg-sign is forbidden. Fix the root cause the hook is reporting instead. ${OPTOUT_LINE}"
fi

# ── §10 — golden / snapshot updates ──────────────────────────────────────────
# Static patterns first.
if printf '%s' "$CMD" | grep -Eq -- '(--update-snapshots?|--updateSnapshot|--update-golden|--accept-snapshots?|UPDATE_SNAPSHOTS=|SNAPSHOT_UPDATE=|UPDATE_GOLDEN=|insta[[:space:]]+accept|--snapshot-update)'; then
  emit_deny "Blocked by m-skills (Guidelines §10): golden and visual-snapshot updates are user-only. Surface the diff and its report path, then stop — \"Diffs detected — review the report at <path>; if intended, run <update-command> manually.\" Auto-updating erases the exact signal the test exists to produce. ${OPTOUT_LINE}"
fi

# A bare -u only means "update snapshots" next to a test runner that defines it.
if printf '%s' "$CMD" | grep -Eq '(^|[^[:alnum:]_./-])(jest|vitest|ava|mocha|jasmine|playwright)([^[:alnum:]_-]|$)' \
  && printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])-[a-zA-Z]*u([a-zA-Z]*)?([[:space:]]|$)'; then
  emit_deny "Blocked by m-skills (Guidelines §10): \`-u\` updates snapshots on this test runner, and that is user-only. Report the diffs and let the user run the update themselves. ${OPTOUT_LINE}"
fi

# Then the project's OWN resolved update command. Prose can never do this — §10's
# whole point is that the command is project-specific. Cached per session: the
# resolution spawns node, and this hook runs on every Bash call.
resolve_update_cmd() {
  local state cache root
  root="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}")"
  state="$(m_skills_state_dir)"
  cache="$state/updatecmd-$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
  if [ -f "$cache" ]; then
    cat "$cache"
    return 0
  fi
  mkdir -p "$state" 2>/dev/null || return 1
  local resolved
  resolved="$(cd "$root" 2>/dev/null && bash "$DIR/../skills/implementing-architect/check-quality.sh" --list 2>/dev/null \
              | sed -n 's/^[[:space:]]*Update (user-only)[[:space:]]*//p' | head -1)"
  [ "$resolved" = "n-a" ] && resolved=""
  printf '%s' "$resolved" > "$cache" 2>/dev/null
  printf '%s' "$resolved"
}

UPDATE_CMD="$(resolve_update_cmd)"
if [ -n "$UPDATE_CMD" ] && printf '%s' "$CMD" | grep -qF -- "$UPDATE_CMD"; then
  emit_deny "Blocked by m-skills (Guidelines §10): \`${UPDATE_CMD}\` is this project's resolved snapshot-update command, and it is user-only. Surface the diffs and the report path, then stop. ${OPTOUT_LINE}"
fi

# ── Catastrophic filesystem operations (additive scope) ──────────────────────
if printf '%s' "$CMD" | grep -Eq '(^|[^[:alnum:]_./-])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR])[a-zA-Z]*[[:space:]]+(/|~|\$HOME|\.\.|\*)([[:space:]]|/|$)'; then
  emit_deny "Blocked by m-skills: recursive force-delete of a root, home, parent, or bare glob path is unrecoverable. Name the specific directory instead. ${OPTOUT_LINE}"
fi

if printf '%s' "$CMD" | grep -Eq '(^|[^[:alnum:]_./-])mkfs([.[:space:]]|$)|(^|[^[:alnum:]_./-])dd[[:space:]]+.*of=/dev/'; then
  emit_deny "Blocked by m-skills: this writes directly to a block device. ${OPTOUT_LINE}"
fi

exit 0
