#!/usr/bin/env bash
# m-skills — PreToolUse guard for Bash and Monitor. Enforces guidelines-meta §9 and §10.
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
# With no JSON reader at all, steps aside and logs it to guards.log (README, Enforcement).

# Every check matches in bash and the payload is read in one engine run: on Git Bash a
# spawned process costs ~80 ms, and a guard past its timeout lets the call through.
# Patterns follow the newline rule in lib/hook-json.sh (m_skills_re): a separator inside
# a match is $SP, never [[:space:]], so the verdict is grep's line-by-line verdict.

set -uo pipefail

DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" = "${BASH_SOURCE[0]}" ] && DIR=.
case "$DIR" in /*|[A-Za-z]:[\\/]*) ;; *) DIR="$PWD/$DIR" ;; esac   # C:\… is absolute on Windows
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(< /dev/stdin)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

json_fields "$INPUT" CMD tool_input.command SESSION session_id
[ -z "$CMD" ] && exit 0

OPTOUT_LINE="Opt out for this project with: touch .claude/.m-skills-no-guards"
SP="$M_SKILLS_SP"; NL="$M_SKILLS_NL"

# ── §9 — git mutation ────────────────────────────────────────────────────────
# Tolerate interposed flags so `git -C /path commit` and `git --git-dir=x push`
# are caught, and scan the whole string so `&&`, `;`, and `bash -c "…"` are too.
# This is the class the prefix-matching deny list in settings.template.json misses.
# GIT_PREFIX holds three groups, so the subcommand is BASH_REMATCH[4] in both tests below.
GIT_PREFIX="(^|[^[:alnum:]_./-])git(${SP}+(-[cC]${SP}+[^[:space:]]+|--[^[:space:]]+=[^[:space:]]+|--no-pager|--paginate|--bare|--literal-pathspecs))*${SP}+"

# Always mutating. No read-only form exists.
GIT_HARD='(add|stage|commit|push|checkout|switch|reset|rebase|cherry-pick|revert|clean|am|mv|rm|merge|pull|fetch|gc|prune|filter-branch|update-ref|symbolic-ref|restore|bisect|apply|notes|replace)'

# Mutating only in some forms. Listing branches, tags, remotes, worktrees, and
# stashes is read-only and genuinely useful — denying it would send people to the
# opt-out, which defeats the guard entirely. Each pattern below matches only the
# writing form: a destructive flag, or a bare name where a name means "create".
GIT_SOFT="(branch${SP}+(-[dDmMcC]([[:space:]]|\$)|--(delete|move|copy|set-upstream-to|unset-upstream|edit-description)|[^-[:space:]])|tag${SP}+(-[adsfD]([[:space:]]|\$)|--(delete|force|annotate|sign)|[^-[:space:]])|remote${SP}+(add|remove|rm|rename|set-url|set-head|prune)|worktree${SP}+(add|remove|move|prune|lock)|submodule${SP}+(add|update|init|deinit|sync|set-url)|stash(${SP}+(push|pop|apply|drop|clear|save|create|store)([[:space:]]|\$)|${SP}*(${NL}|\$)))"

GIT_DENIED=""
if m_skills_re "$CMD" "${GIT_PREFIX}${GIT_HARD}([^[:alnum:]_-]|\$)"; then
  GIT_DENIED="${BASH_REMATCH[4]}"
elif m_skills_re "$CMD" "${GIT_PREFIX}${GIT_SOFT}"; then
  GIT_DENIED="${BASH_REMATCH[4]%%[^a-z]*}"
fi

if [ -n "$GIT_DENIED" ]; then
  emit_deny "Blocked by m-skills (Guidelines §9): \`git ${GIT_DENIED}\` writes to the repository, and every git write is the user's to run — no exceptions, including when the user says \"ship it\". Print the exact command for them to paste; leave the working tree as it is. Read-only git stays open: status, diff, log, show, blame, rev-parse, merge-base, describe, and the listing forms of branch/tag/remote/stash/worktree. ${OPTOUT_LINE}"
fi

# --no-verify / --no-gpg-sign are git-only flags; their presence anywhere is the rule break.
if m_skills_re "$CMD" '(^|[[:space:]])--(no-verify|no-gpg-sign)([[:space:]]|=|$)'; then
  emit_deny "Blocked by m-skills (Guidelines §9): skipping hooks with --no-verify / --no-gpg-sign is forbidden. Fix the root cause the hook is reporting instead. ${OPTOUT_LINE}"
fi

# scripts/release.sh commits and pushes, and refuses to without a terminal on stdin, which
# an agent's Bash call never has. This variable lifts that refusal, so setting it is a push.
# Only the assignment form is matched: a quoted grep for the name stays open.
if m_skills_re "$CMD" '(^|[[:space:];&|(])M_SKILLS_RELEASE_NONINTERACTIVE='; then
  emit_deny "Blocked by m-skills (Guidelines §9): M_SKILLS_RELEASE_NONINTERACTIVE lets the m-skills release script commit and push without a terminal, and a release is the user's to fire. Check it with its --dry-run, then print the release command for the user to run. ${OPTOUT_LINE}"
fi

# ── §10 — golden / snapshot updates ──────────────────────────────────────────
# Static patterns first.
if m_skills_re "$CMD" "(--update-snapshots?|--updateSnapshot|--update-golden|--accept-snapshots?|UPDATE_SNAPSHOTS=|SNAPSHOT_UPDATE=|UPDATE_GOLDEN=|insta${SP}+accept|--snapshot-update)"; then
  emit_deny "Blocked by m-skills (Guidelines §10): golden and visual-snapshot updates are user-only. Surface the diff and its report path, then stop — \"Diffs detected — review the report at <path>; if intended, run <update-command> manually.\" Auto-updating erases the exact signal the test exists to produce. ${OPTOUT_LINE}"
fi

# A bare -u only means "update snapshots" next to a test runner that defines it, and
# only when the flag belongs to THAT runner. Two corrections are load-bearing here:
#
#   · mocha and jasmine are not on the list. Mocha's -u is --ui (bdd/tdd/qunit), so
#     `mocha -u tdd` is an ordinary run; jasmine has no snapshot concept at all.
#   · the runner and the flag must share a command segment. Matching across the whole
#     string denied `jest --listTests | sort -u`, where the -u is sort's.
#
# Over-blocking is the worst failure a guard has: the reason text points at
# .m-skills-no-guards, and reaching for it disarms all three guards permanently.
#
# Segments split on | ; & and newline. Most commands name no runner, so one match over
# the whole string settles them; only a segment that names one by substring pays for the
# two regex tests — a heredoc of thousands of lines costs a glob per line, not a regcomp.
SNAP_RUNNER='(^|[^[:alnum:]_./-])(jest|vitest|ava|playwright)([^[:alnum:]_-]|$)'
SNAP_U='(^|[[:space:]])-[a-zA-Z]*u[a-zA-Z]*([[:space:]]|$)'
snap_segments() { # word splitting on | ; & newline, globbing off — no here-string, no temp file
  local IFS=$'|;&\n' f=$-
  set -f
  # shellcheck disable=SC2206 # the split is the point
  SEGS=($CMD)
  case "$f" in *f*) ;; *) set +f ;; esac
}
if m_skills_re "$CMD" "$SNAP_RUNNER"; then
  SEGS=(); snap_segments
  for seg in "${SEGS[@]}"; do
    case "$seg" in *jest*|*vitest*|*ava*|*playwright*) ;; *) continue ;; esac
    [[ $seg =~ $SNAP_RUNNER ]] && [[ $seg =~ $SNAP_U ]] && \
      emit_deny "Blocked by m-skills (Guidelines §10): \`-u\` updates snapshots on this test runner, and that is user-only. Report the diffs and let the user run the update themselves. ${OPTOUT_LINE}"
  done
fi

# Then the project's OWN resolved update command. Prose can never do this — §10's
# whole point is that the command is project-specific. The resolution spawns git and
# node and this hook runs on every Bash call, so it is cached per session in one file:
# the project dir, the repo root, and the command. The cache stands while no file the
# resolution reads is newer than it — `-nt` is a builtin, so a hit spawns nothing, and
# a PROJECT-PROFILE.md written mid-session (/onboard writes one) re-resolves.
resolve_update_cmd() {
  local project="${CLAUDE_PROJECT_DIR:-$PWD}" state="" cache="" root="" p="" r="" c="" f sid
  if m_skills_state_base; then
    if [ -n "$SESSION" ]; then local LC_ALL=C; sid="${SESSION//[^A-Za-z0-9._-]/_}"
    else sid="$(m_skills_session_id)"; fi
    state="$M_SKILLS_STATE_BASE/$sid"
    # No usable state dir means no cache, never no check.
    { [ -d "$state" ] || mkdir -p "$state" 2>/dev/null; } && cache="$state/updatecmd"
  fi
  if [ -n "$cache" ] && { IFS= read -r p && IFS= read -r r && IFS= read -r c; } 2>/dev/null < "$cache" \
     && [ "$p" = "$project" ]; then
    for f in "$r/.claude/PROJECT-PROFILE.md" "$r/.claude/quality-gates.conf" "$r/package.json" \
             "$r/Makefile" "$r/pyproject.toml" "$r/Cargo.toml" "$r/go.mod" \
             "$r/pnpm-lock.yaml" "$r/yarn.lock" "$r/bun.lock" "$r/bun.lockb"; do   # lockfiles pick the runner
      [ "$f" -nt "$cache" ] && { p=""; break; }
    done
    [ -n "$p" ] && { UPDATE_CMD="$c"; return 0; }
  fi
  root="$(git -C "$project" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$project")"
  c="$(cd "$root" 2>/dev/null && bash "$DIR/../skills/implementing-architect/check-quality.sh" --list 2>/dev/null \
       | tr -d '\r' | sed -n 's/^[[:space:]]*Update (user-only)[[:space:]]*//p' | head -1)"
  [ "$c" = "n-a" ] && c=""
  [ -n "$cache" ] && printf '%s\n%s\n%s\n' "$project" "$root" "$c" > "$cache" 2>/dev/null
  UPDATE_CMD="$c"
}

UPDATE_CMD=""
resolve_update_cmd
if [ -n "$UPDATE_CMD" ] && m_skills_fixed "$CMD" "$UPDATE_CMD"; then
  emit_deny "Blocked by m-skills (Guidelines §10): \`${UPDATE_CMD}\` is this project's resolved snapshot-update command, and it is user-only. Surface the diffs and the report path, then stop. ${OPTOUT_LINE}"
fi

# ── Catastrophic filesystem operations (additive scope) ──────────────────────
# Home counts only as itself, its top-level globs, or its parent: `~/.cache/x` names one
# directory and passes, while `~/`, `~/*`, `~/.*`, and `~/..` are denied.
RM_RE='(^|[^[:alnum:]_./-])rm'"$SP"'+(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR])[a-zA-Z]*'"$SP"'+((/|\.\.|\*)([[:space:]]|/|$)|(~|\$HOME)(/(\*|\.\*|\.\.?)?)?([[:space:];&|]|$))'
if m_skills_re "$CMD" "$RM_RE"; then
  emit_deny "Blocked by m-skills: recursive force-delete of a root, home, parent, or bare glob path is unrecoverable. Name the specific directory instead. ${OPTOUT_LINE}"
fi

if m_skills_re "$CMD" "(^|[^[:alnum:]_./-])mkfs([.[:space:]]|\$)|(^|[^[:alnum:]_./-])dd${SP}+${M_SKILLS_ANY}of=/dev/"; then
  emit_deny "Blocked by m-skills: this writes directly to a block device. ${OPTOUT_LINE}"
fi

exit 0
