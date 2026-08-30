#!/usr/bin/env bash
# m-skills — PostToolUse advisory: a shared-shape file was just edited.
#
# implementing-architect's Change Propagation Protocols A/B/C are ~50 lines the
# pack itself calls "the highest-value output of the whole review" — and they fire
# only when the model remembers to run them. This fires on the edit instead.
#
# Generic path triggers only, no profile lookup: the shapes below hold in any repo,
# and a heuristic that works everywhere beats a table that must be filled first.
#
# Fires ONCE per file per session. A file edited five times advises once, so the
# reminder stays a signal rather than becoming wallpaper.
#
# It can prompt the sweep; it cannot verify it. The text says so, because an
# advisory mistaken for a completed check is worse than no advisory.
#
# Respects .m-skills-no-guards. Fails OPEN.

set -uo pipefail

DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 0
# shellcheck source=lib/hook-json.sh
. "$DIR/lib/hook-json.sh" 2>/dev/null || exit 0

m_skills_guards_disabled && exit 0
advisory_require_json_engine

INPUT="$(hook_read_input)"
[ -z "$INPUT" ] && exit 0

FILE="$(json_field "$INPUT" "tool_input.file_path")"
[ -z "$FILE" ] && exit 0

# Never advise on a test file — that is H4's territory, and a fixture edit is
# usually the RESULT of a sweep rather than the trigger for one.
printf '%s' "$FILE" | grep -Eq '\.(spec|test)\.[A-Za-z0-9]+$|(^|/)(tests?|spec|__tests__)/' && exit 0

printf '%s' "$FILE" | grep -Eq '(^|/)(models?|entities|schemas?|types?|dto|interfaces|migrations?|domain)/|\.(proto|graphql|gql|prisma|sql)$|(^|/)(schema|types|models)\.[A-Za-z0-9]+$' || exit 0

# Once per file per session.
STATE="$(m_skills_state_dir "$(json_field "$INPUT" "session_id")")/propagation"
mkdir -p "$STATE" 2>/dev/null || exit 0
MARK="$STATE/$(printf '%s' "$FILE" | cksum | cut -d' ' -f1)"
[ -f "$MARK" ] && exit 0
: > "$MARK" 2>/dev/null || exit 0

emit_block "m-skills advisory — \`${FILE}\` looks like a shared-shape definition, and this is the first edit to it this session.

A green pipeline is not proof the change fully landed. If you renamed, removed, retyped, or restructured a field, moved a numeric bound, or changed an enum value, run the Protocol A sweep (implementing-architect). Grep the OLD identifier and OLD value, then confirm each site:

1. The type/model declaration itself.
2. Every construction site — factories, builders, form groups, default objects. There is almost always more than one.
3. Both mapping directions — serialize and hydrate, encode and decode.
4. Validation stated twice — the declarative validators AND any hand-written validation service.
5. Boundaries — API payloads, storage schemas, query params, export/import paths.
6. Templates and views. These pass type-check and fail only at build, so run <build>, not just <typecheck>.
7. Parallel subsystems — the secondary UI mirroring the primary one, an admin form. The easiest miss.
8. User-facing strings — a removed field orphans its label/placeholder keys in every locale.
9. Fixtures and test doubles — old-shape mocks pass green anyway.

Numeric bounds and enum values do NOT grep cleanly: a bare number drowns in false positives, so \"grep found nothing\" is not proof. Walk the semantic sites instead — wherever the app states the constraint a second time.

If the public surface of a service or class changed instead, that is Protocol B: spy/mock name lists, hand-written fakes, and inline stubs return nothing for a method they do not list.

Advisory only — this hook sees the path, not the change. If the edit was cosmetic, ignore it and carry on; it will not fire again for this file."
