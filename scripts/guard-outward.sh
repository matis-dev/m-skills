#!/usr/bin/env bash
# m-skills — PreToolUse ask-gate for outward-facing actions.
#
# deployment-architect constraint 2 ("never fire an irreversible action unasked")
# only binds while that skill is loaded — but `npm publish` can be typed in any
# session, including one that never touched the deployment pipeline. This makes
# the constraint hold everywhere.
#
# ASK, not deny: deploying and publishing are legitimate operations that need a
# confirmation gate, not a prohibition. The reason names the rollback requirement
# so the confirmation is an informed one.
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

# Each entry: <ERE> | <what it does>. Ordered cheapest-signal first.
match() { printf '%s' "$CMD" | grep -Eq "$1"; }

WHAT=""
if   match "${B}(vercel|netlify|fly|railway|render|heroku)[[:space:]]+(deploy|up)([^[:alnum:]_-]|\$)"; then WHAT="deploy to a hosting platform"
elif match "${B}(npm|pnpm|yarn|bun)[[:space:]]+publish([^[:alnum:]_-]|\$)";                              then WHAT="publish a package to a registry"
elif match "${B}kubectl[[:space:]]+(apply|delete|rollout|scale)([^[:alnum:]_-]|\$)";                     then WHAT="mutate a Kubernetes cluster"
elif match "${B}(terraform|tofu)[[:space:]]+(apply|destroy)([^[:alnum:]_-]|\$)";                         then WHAT="apply infrastructure changes"
elif match "${B}(prisma|drizzle-kit|alembic|knex|sequelize)[[:space:]]+.*(migrate|deploy|push|upgrade)";  then WHAT="run a migration against a database"
elif match "${B}gh[[:space:]]+release[[:space:]]+(create|edit|delete)([^[:alnum:]_-]|\$)";               then WHAT="create or change a GitHub release"
elif match "${B}docker[[:space:]]+push([^[:alnum:]_-]|\$)";                                              then WHAT="push a container image to a registry"
elif match "${B}aws[[:space:]]+(s3[[:space:]]+(sync|rm|cp)|cloudfront[[:space:]]+create-invalidation|ecs[[:space:]]+update-service|lambda[[:space:]]+update-function-code)"; then WHAT="mutate live AWS infrastructure"
elif match "${B}(firebase|wrangler|serverless|sls)[[:space:]]+(deploy|publish)([^[:alnum:]_-]|\$)";      then WHAT="deploy to a serverless platform"
elif match "${B}(supabase|doctl|flyctl)[[:space:]]+.*(deploy|migration[[:space:]]+up)";                  then WHAT="deploy or migrate a hosted environment"
fi

[ -z "$WHAT" ] && exit 0

emit_ask "m-skills (deployment-architect constraint 2): this would ${WHAT} — an outward-facing, hard-to-reverse action. Before confirming, check that the rollback plan exists and names its one-way doors (migrations, sent mail, charges, client-side caches), and that this is the environment you meant. Guidelines §9 still applies separately: release tags stay user-only."
