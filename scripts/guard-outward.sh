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
# Opt out with .claude/.m-skills-no-guards. With no JSON reader at all, steps aside and logs.

set -uo pipefail

DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" = "${BASH_SOURCE[0]}" ] && DIR=.
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0

INPUT="$(< /dev/stdin)"
[ -z "$INPUT" ] && exit 0

guard_require_json_engine

json_fields "$INPUT" CMD tool_input.command
[ -z "$CMD" ] && exit 0

# Every pattern below starts with one of these names and a separator, so a command that
# names none of them is settled by one match — no reason to walk sixteen. Matching is in
# bash and follows the newline rule in lib/hook-json.sh: $SP and $ANY never cross a line.
B='(^|[^[:alnum:]_./-])'
SP="$M_SKILLS_SP"; ANY="$M_SKILLS_ANY"
m_skills_re "$CMD" "${B}(gh|vercel|netlify|fly|railway|render|heroku|npm|pnpm|yarn|bun|kubectl|terraform|tofu|prisma|drizzle-kit|alembic|knex|sequelize|docker|aws|firebase|wrangler|serverless|sls|supabase|doctl|flyctl)${SP}" || exit 0

match() { m_skills_re "$CMD" "$1"; }

WHAT=""; KIND=""

# ── gh writes — publish to a surface other people see ────────────────────────
# Subcommands are enumerated as WRITES only. Anything not listed (view, list,
# diff, checks, status) falls through and stays allowed.
if   match "${B}gh${SP}+pr${SP}+(create|merge|close|reopen|comment|edit|review|ready)([^[:alnum:]_-]|\$)";  then WHAT="open, merge, or comment on a pull request"; KIND=gh
elif match "${B}gh${SP}+issue${SP}+(create|close|reopen|comment|edit|transfer|delete|pin)([^[:alnum:]_-]|\$)"; then WHAT="create or change a GitHub issue"; KIND=gh
elif match "${B}gh${SP}+release${SP}+(create|edit|delete|upload)([^[:alnum:]_-]|\$)";                      then WHAT="create or change a GitHub release"; KIND=gh
elif match "${B}gh${SP}+secret${SP}+(delete|remove|se[t])([^[:alnum:]_-]|\$)";                               then WHAT="write a repository or environment secret"; KIND=gh
elif match "${B}gh${SP}+(repo|gist)${SP}+(create|delete|edit|rename|archive)([^[:alnum:]_-]|\$)";          then WHAT="create, delete, or reconfigure a repository"; KIND=gh
elif match "${B}gh${SP}+workflow${SP}+(run|enable|disable)([^[:alnum:]_-]|\$)";                            then WHAT="trigger or toggle a CI workflow"; KIND=gh
elif match "${B}gh${SP}+api${SP}+${ANY}(-X|--method)${SP}*(POST|PUT|PATCH|DELETE)";                      then WHAT="make a writing GitHub API call"; KIND=gh

# ── infrastructure — deploy, publish, migrate ────────────────────────────────
elif match "${B}(vercel|netlify|fly|railway|render|heroku)${SP}+(deploy|up)([^[:alnum:]_-]|\$)";       then WHAT="deploy to a hosting platform"; KIND=infra
elif match "${B}(npm|pnpm|yarn|bun)${SP}+publish([^[:alnum:]_-]|\$)";                                  then WHAT="publish a package to a registry"; KIND=infra
elif match "${B}kubectl${SP}+(apply|delete|rollout|scale)([^[:alnum:]_-]|\$)";                         then WHAT="mutate a Kubernetes cluster"; KIND=infra
elif match "${B}(terraform|tofu)${SP}+(apply|destroy)([^[:alnum:]_-]|\$)";                             then WHAT="apply infrastructure changes"; KIND=infra
elif match "${B}(prisma|drizzle-kit|alembic|knex|sequelize)${SP}+${ANY}(migrate|deploy|push|upgrade)";     then WHAT="run a migration against a database"; KIND=infra
elif match "${B}docker${SP}+push([^[:alnum:]_-]|\$)";                                                  then WHAT="push a container image to a registry"; KIND=infra
elif match "${B}aws${SP}+(s3${SP}+(sync|rm|cp)|cloudfront${SP}+create-invalidation|ecs${SP}+update-service|lambda${SP}+update-function-code)"; then WHAT="mutate live AWS infrastructure"; KIND=infra
elif match "${B}(firebase|wrangler|serverless|sls)${SP}+(deploy|publish)([^[:alnum:]_-]|\$)";          then WHAT="deploy to a serverless platform"; KIND=infra
elif match "${B}(supabase|doctl|flyctl)${SP}+${ANY}(deploy|migration${SP}+up)";                      then WHAT="deploy or migrate a hosted environment"; KIND=infra
fi

[ -z "$WHAT" ] && exit 0

OPTOUT_LINE="Opt out for this project with: touch .claude/.m-skills-no-guards"

if [ "$KIND" = "gh" ]; then
  emit_deny "Blocked by m-skills (Guidelines §9): this would ${WHAT} — a write to a surface other people see, and it notifies them. Like every git write, it is the user's to run. Print the exact command for them to paste, and say what it will publish. Read-only \`gh\` stays open: pr view/list/diff/checks, issue view/list, run view/list. ${OPTOUT_LINE}"
fi

emit_deny "Blocked by m-skills (deployment-architect constraint 2): this would ${WHAT} — an outward-facing action that is hard to undo, and it is the user's to fire, not yours. Hand over a runbook instead: the config and secrets they must set in the target, then one numbered, copy-paste step per command, each with what it does and how they know it worked — plus the rollback plan and its one-way doors (migrations, sent mail, charges, client-side caches) named before they start. Reversible work stays open: production builds, artifact inspection, config diffing, dry runs, health checks, reading logs. ${OPTOUT_LINE}"
