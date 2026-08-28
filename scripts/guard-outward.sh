#!/usr/bin/env bash
# m-skills — PreToolUse handover gate for outward-facing actions.
#
# deployment-architect constraint 2 ("never fire an irreversible action") only
# binds while that skill is loaded — but `npm publish` can be typed in any
# session, including one that never touched the deployment pipeline. This makes
# the constraint hold everywhere.
#
# DENY, not ask. Deploying, publishing, migrating shared state, and publishing to
# a collaboration surface are the user's to run, exactly like a git write
# (guidelines-meta §9). The skill's job is to assemble a copy-paste runbook and
# hand it over; the reason text below says so, because a deny that only says "no"
# turns a design decision into an obstacle.
#
# Two families:
#   infra  — deploy, publish, migrate, mutate live infrastructure
#   gh     — writes to a shared GitHub surface (PRs, issues, releases, secrets)
#
# READ-ONLY gh stays open on purpose: `gh pr view|list|diff|checks`,
# `gh issue view|list`, `gh run view|list`. code-review-architect reviews a PR by
# fetching it with the platform CLI, and denying that would break the review path.
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

CMD="$(json_field "$INPUT" "tool_input.command")"
[ -z "$CMD" ] && exit 0

B='(^|[^[:alnum:]_./-])'

match() { printf '%s' "$CMD" | grep -Eq "$1"; }

WHAT=""; KIND=""

# ── gh writes — publish to a surface other people see ────────────────────────
# Subcommands are enumerated as WRITES only. Anything not listed (view, list,
# diff, checks, status) falls through and stays allowed.
if   match "${B}gh[[:space:]]+pr[[:space:]]+(create|merge|close|reopen|comment|edit|review|ready)([^[:alnum:]_-]|\$)";  then WHAT="open, merge, or comment on a pull request"; KIND=gh
elif match "${B}gh[[:space:]]+issue[[:space:]]+(create|close|reopen|comment|edit|transfer|delete|pin)([^[:alnum:]_-]|\$)"; then WHAT="create or change a GitHub issue"; KIND=gh
elif match "${B}gh[[:space:]]+release[[:space:]]+(create|edit|delete|upload)([^[:alnum:]_-]|\$)";                      then WHAT="create or change a GitHub release"; KIND=gh
elif match "${B}gh[[:space:]]+secret[[:space:]]+(set|delete|remove)([^[:alnum:]_-]|\$)";                               then WHAT="write a repository or environment secret"; KIND=gh
elif match "${B}gh[[:space:]]+(repo|gist)[[:space:]]+(create|delete|edit|rename|archive)([^[:alnum:]_-]|\$)";          then WHAT="create, delete, or reconfigure a repository"; KIND=gh
elif match "${B}gh[[:space:]]+workflow[[:space:]]+(run|enable|disable)([^[:alnum:]_-]|\$)";                            then WHAT="trigger or toggle a CI workflow"; KIND=gh
elif match "${B}gh[[:space:]]+api[[:space:]]+.*(-X|--method)[[:space:]]*(POST|PUT|PATCH|DELETE)";                      then WHAT="make a writing GitHub API call"; KIND=gh

# ── infrastructure — deploy, publish, migrate ────────────────────────────────
elif match "${B}(vercel|netlify|fly|railway|render|heroku)[[:space:]]+(deploy|up)([^[:alnum:]_-]|\$)";       then WHAT="deploy to a hosting platform"; KIND=infra
elif match "${B}(npm|pnpm|yarn|bun)[[:space:]]+publish([^[:alnum:]_-]|\$)";                                  then WHAT="publish a package to a registry"; KIND=infra
elif match "${B}kubectl[[:space:]]+(apply|delete|rollout|scale)([^[:alnum:]_-]|\$)";                         then WHAT="mutate a Kubernetes cluster"; KIND=infra
elif match "${B}(terraform|tofu)[[:space:]]+(apply|destroy)([^[:alnum:]_-]|\$)";                             then WHAT="apply infrastructure changes"; KIND=infra
elif match "${B}(prisma|drizzle-kit|alembic|knex|sequelize)[[:space:]]+.*(migrate|deploy|push|upgrade)";     then WHAT="run a migration against a database"; KIND=infra
elif match "${B}docker[[:space:]]+push([^[:alnum:]_-]|\$)";                                                  then WHAT="push a container image to a registry"; KIND=infra
elif match "${B}aws[[:space:]]+(s3[[:space:]]+(sync|rm|cp)|cloudfront[[:space:]]+create-invalidation|ecs[[:space:]]+update-service|lambda[[:space:]]+update-function-code)"; then WHAT="mutate live AWS infrastructure"; KIND=infra
elif match "${B}(firebase|wrangler|serverless|sls)[[:space:]]+(deploy|publish)([^[:alnum:]_-]|\$)";          then WHAT="deploy to a serverless platform"; KIND=infra
elif match "${B}(supabase|doctl|flyctl)[[:space:]]+.*(deploy|migration[[:space:]]+up)";                      then WHAT="deploy or migrate a hosted environment"; KIND=infra
fi

[ -z "$WHAT" ] && exit 0

OPTOUT_LINE="Opt out for this project with: touch .claude/.m-skills-no-guards"

if [ "$KIND" = "gh" ]; then
  emit_deny "Blocked by m-skills (Guidelines §9): this would ${WHAT} — a write to a surface other people see, and it notifies them. Like every git write, it is the user's to run. Print the exact command for them to paste, and say what it will publish. Read-only \`gh\` stays open: pr view/list/diff/checks, issue view/list, run view/list. ${OPTOUT_LINE}"
fi

emit_deny "Blocked by m-skills (deployment-architect constraint 2): this would ${WHAT} — an outward-facing action that is hard to undo, and it is the user's to fire, not yours. Hand over a runbook instead: the config and secrets they must set in the target, then one numbered, copy-paste step per command, each with what it does and how they know it worked — plus the rollback plan and its one-way doors (migrations, sent mail, charges, client-side caches) named before they start. Reversible work stays open: production builds, artifact inspection, config diffing, dry runs, health checks, reading logs. ${OPTOUT_LINE}"
