#!/usr/bin/env bash
# m-skills — release both plugin builds in one command: check, build, validate, stage, push.
#
# Usage: bash scripts/release.sh [--dry-run]
#   Run it from a terminal when the repo is ready. --dry-run runs every check and both
#   builds, prints what each branch would receive, and writes nothing to git or to a worktree.
#
# Two targets, each a sibling worktree of this checkout holding an orphan branch whose root
# is the built plugin (README § Antigravity and § Claude directory release):
#   ../m-skills-release       branch release      <- dist/claude/m-skills       (Claude plugin directory)
#   ../m-skills-antigravity   branch antigravity  <- dist/antigravity/m-skills  (Antigravity Marketplace)
# Codex is not released: it has no branch or marketplace.
#
# Phases. No git write happens before phase 7, so a refusal in 1–6 leaves both remotes alone:
#   1 preconditions  main is clean and pushed; plugin.json, marketplace.json and the CHANGELOG
#                    top heading agree on one version; both worktrees are clean, on their
#                    branch, and at their remote's tip; claude and agy are installed
#   2 tests          bash tests/run-tests.sh
#   3 build          build-claude.sh and build-antigravity.sh, unchanged
#   4 validate       both vendors' --strict validators on the built trees
#   5 diff           built tree vs worktree; no difference means nothing to release for that
#                    target, and a difference under an unchanged version is refused
#   6 leak check     nothing secret-shaped may reach a public repository
#                    (--dry-run stops here)
#   7 stage          replace each worktree's contents with its build, validate again in place
#   8 commit         one commit per worktree, before any push, so a hook or identity failure
#                    still leaves the remotes alone
#   9 push           release first, then antigravity; each verified against the remote
# Only phase 9 can leave the two branches out of step. When it does, the output names what
# landed and prints the command that finishes the rest.
#
# The push is a one-way door, so the writing path wants a terminal on stdin. That is a speed
# bump, not a boundary: M_SKILLS_RELEASE_NONINTERACTIVE=1 lifts it for unattended runs and tests.

set -euo pipefail

ROOT="$(cd "$(dirname -- "$0")/.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd -P)"
TARGETS="claude antigravity"

# Read through tr: a clone made before .gitattributes keeps this unchanged file CRLF.
# shellcheck source=lib/hook-json.sh
. <(tr -d '\r' < "$ROOT/scripts/lib/hook-json.sh")

t_wt()       { case "$1" in claude) echo "$PARENT/m-skills-release" ;; antigravity) echo "$PARENT/m-skills-antigravity" ;; esac; }
t_branch()   { case "$1" in claude) echo release ;; antigravity) echo antigravity ;; esac; }
t_dist()     { case "$1" in claude) echo "$ROOT/dist/claude/m-skills" ;; antigravity) echo "$ROOT/dist/antigravity/m-skills" ;; esac; }
t_manifest() { case "$1" in claude) echo .claude-plugin/plugin.json ;; antigravity) echo plugin.json ;; esac; }
t_build()    { case "$1" in claude) echo "$ROOT/scripts/build-claude.sh" ;; antigravity) echo "$ROOT/scripts/build-antigravity.sh" ;; esac; }
t_remote()   { git -C "$(t_wt "$1")" config "branch.$(t_branch "$1").remote" || true; }
t_subject()  { case "$1" in claude) echo "release: m-skills $VERSION" ;; antigravity) echo "release: m-skills $VERSION (antigravity)" ;; esac; }

LOG="$(mktemp)"; trap 'rm -f "$LOG"' EXIT
STAGED=""    # worktrees whose files this run has begun to replace
PUSHED=""

usage() { echo "usage: bash scripts/release.sh [--dry-run]" >&2; exit 2; }

# die <what went wrong> [detail lines]
die() {
  local t
  printf 'release: %s\n' "$1" >&2
  [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/  /' >&2
  if [ -n "$PUSHED" ]; then
    printf '  already pushed: %s\n' "$PUSHED" >&2
  elif [ -n "$STAGED" ]; then
    printf '  Worktree files were replaced and nothing is committed. To discard them:\n' >&2
    for t in $STAGED; do
      printf '    git -C %s reset --hard HEAD && git -C %s clean -fd\n' "$(t_wt "$t")" "$(t_wt "$t")" >&2
    done
  fi
  exit 1
}

# run <label> <command…> — quiet on success; on failure the output's tail comes with the refusal
run() {
  local label="$1"; shift
  "$@" > "$LOG" 2>&1 || die "$label failed" "$(tail -n 20 "$LOG")"
  echo "  ok  $label"
}

# remote_tip <repo> <remote> <branch> — the commit the remote's branch points at (empty if none)
remote_tip() {
  local out
  out="$(git -C "$1" ls-remote "$2" "refs/heads/$3")" || return 1
  printf '%s' "${out%%[[:space:]]*}"
}

DRY=0
case "${1:-}" in
  "") ;;
  --dry-run) DRY=1 ;;
  *) usage ;;
esac
[ $# -le 1 ] || usage

if [ "$DRY" = 0 ] && [ ! -t 0 ] && [ "${M_SKILLS_RELEASE_NONINTERACTIVE:-}" != 1 ]; then
  die "no terminal on stdin: the writing path pushes to GitHub, so it is yours to fire" \
    "run it from a terminal, or use --dry-run"
fi

# ── 1 preconditions ──────────────────────────────────────────────────────────
echo "release: checking the repository"

for tool in git claude agy; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is not on PATH" "a release is never pushed unvalidated; install it first"
done

CPJ="$(tr -d '\r' < "$ROOT/.claude-plugin/plugin.json")"
MPJ="$(tr -d '\r' < "$ROOT/.claude-plugin/marketplace.json")"
VERSION="$(json_field "$CPJ" version)"
MVERSION="$(json_field "$MPJ" plugins.0.version)"
# (awk reads to the end rather than exiting: an early exit sends SIGPIPE up the pipe, and
# under pipefail that fails the script on some runs and not others)
HEADING="$(tr -d '\r' < "$ROOT/CHANGELOG.md" | awk '!seen && /^### V[0-9]/ { sub(/^### V/, ""); print $1; seen = 1 }')"
case "$HEADING" in *.*.*) ;; *) HEADING="$HEADING.0" ;; esac    # V5.2 names release 5.2.0
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "plugin.json has no x.y.z version" "found: '$VERSION'"
[ "$MVERSION" = "$VERSION" ] || die "plugin.json says $VERSION and marketplace.json says '$MVERSION'" \
  "set both to the version being released"
[ "$HEADING" = "$VERSION" ] || die "the manifests say $VERSION and the newest CHANGELOG heading says $HEADING" \
  "bump the manifests, or add the heading, so the three agree"

[ "$(git -C "$ROOT" branch --show-current)" = main ] || die "this checkout is not on main" "release from main"
[ -z "$(git -C "$ROOT" status --porcelain)" ] || die "this checkout has uncommitted changes" \
  "a release is built from committed sources: commit or set them aside first"
MAIN_REMOTE="$(git -C "$ROOT" config branch.main.remote || true)"
[ -n "$MAIN_REMOTE" ] || die "main has no upstream" "set it yourself: git branch --set-upstream-to=origin/main main"
tip="$(remote_tip "$ROOT" "$MAIN_REMOTE" main)" || die "cannot reach $MAIN_REMOTE to compare main" "check the network, then rerun"
[ "$tip" = "$(git -C "$ROOT" rev-parse HEAD)" ] || die "main is not at $MAIN_REMOTE's tip" \
  "push main first, so the sources behind a release are public"

# check_worktree <target> — also called right before the files are replaced
check_worktree() {
  local wt b r real hint tip
  wt="$(t_wt "$1")"; b="$(t_branch "$1")"
  if [ ! -d "$wt" ]; then
    if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$b"; then hint="git worktree add $wt $b"
    else hint="git worktree add --orphan -b $b $wt"; fi
    die "the $b worktree is missing at $wt" "create it once, yourself: $hint"
  fi
  real="$(cd "$wt" && pwd -P)"
  [ "$real" != "$(cd "$ROOT" && pwd -P)" ] || die "the $b worktree is this checkout" "it must be a separate worktree"
  git -C "$ROOT" worktree list --porcelain | grep -Fx "worktree $real" >/dev/null \
    || die "$wt is not a worktree of this repository" "register it with: git worktree add"
  [ "$(git -C "$wt" rev-parse --show-toplevel)" = "$real" ] || die "$wt is not the root of its worktree"
  [ "$(git -C "$wt" branch --show-current)" = "$b" ] || die "$wt is not on branch $b" "git -C $wt switch $b"
  [ -z "$(git -C "$wt" status --porcelain)" ] || die "$wt has uncommitted changes" \
    "it is replaced wholesale on release: commit or discard them first"
  r="$(t_remote "$1")"
  [ -n "$r" ] || die "branch $b has no upstream" "set it yourself: git -C $wt branch --set-upstream-to=origin/$b $b"
  tip="$(remote_tip "$wt" "$r" "$b")" || die "cannot reach $r to compare $b" "check the network, then rerun"
  [ "$tip" = "$(git -C "$wt" rev-parse HEAD)" ] || die "$b is not at $r's tip" "git -C $wt pull --ff-only"
}
for t in $TARGETS; do check_worktree "$t"; done
echo "  ok  version $VERSION, main pushed, both worktrees clean and current"

# ── 2 tests, 3 build, 4 validate ─────────────────────────────────────────────
echo "release: running the gates"
[ -f "$ROOT/tests/run-tests.sh" ] || die "tests/run-tests.sh is missing"
run "tests/run-tests.sh" bash "$ROOT/tests/run-tests.sh"
for t in $TARGETS; do run "build $t" bash "$(t_build "$t")"; done

# validate <target> <dir>
validate() {
  local m out
  case "$1" in
    claude)
      for m in plugin marketplace; do
        out="$(claude plugin validate "$2/.claude-plugin/$m.json" --strict 2>&1)" \
          && printf '%s' "$out" | grep 'Validation passed' >/dev/null \
          || die "claude plugin validate failed on $m.json in $2" "$(printf '%s' "$out" | tail -n 8)"
      done ;;
    antigravity)
      out="$(agy plugin validate --strict "$2" 2>&1)" \
        || die "agy plugin validate failed on $2" "$(printf '%s' "$out" | tail -n 8)" ;;
  esac
}
for t in $TARGETS; do validate "$t" "$(t_dist "$t")"; echo "  ok  validate $t build"; done

# ── 5 diff, 6 leak check ─────────────────────────────────────────────────────
differs() { ! diff -rq --exclude=.git "$1" "$2" >/dev/null 2>&1; }

summary() { # <built tree> <worktree>
  { diff -rq --exclude=.git "$1" "$2" 2>/dev/null || true; } | awk -v d="$1" -v w="$2" '
    index($0, "Only in " d) == 1 { a++; next }
    index($0, "Only in " w) == 1 { r++; next }
    { c++ }
    END { printf "%d added, %d changed, %d removed", a, c, r }'
}

echo "release: comparing the builds with the branches"
TODO=""
for t in $TARGETS; do
  b="$(t_branch "$t")"
  if ! differs "$(t_dist "$t")" "$(t_wt "$t")"; then
    echo "  $b: nothing to release"
    continue
  fi
  on_branch="$(git -C "$(t_wt "$t")" show "HEAD:$(t_manifest "$t")" | tr -d '\r')"
  bv="$(json_field "$on_branch" version)"
  [ "$bv" != "$VERSION" ] || die "$b would change but its version is still $VERSION" \
    "bump plugin.json, marketplace.json and the CHANGELOG heading, commit and push main, then rerun"
  [ "$(printf '%s\n%s\n' "$bv" "$VERSION" | sort -V | tail -n 1)" = "$VERSION" ] \
    || die "$b already carries $bv, newer than $VERSION" "release a version above $bv"
  echo "  $b: $bv -> $VERSION, $(summary "$(t_dist "$t")" "$(t_wt "$t")")"
  TODO="$TODO $t"
done
[ -n "$TODO" ] || { echo "release: nothing to release"; exit 0; }

# Secret-shaped names only; the built trees are whitelists, so a hit means a stray file in skills/.
for t in $TODO; do
  hits="$(find "$(t_dist "$t")" \( -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name 'id_rsa*' -o -name 'id_ed25519*' \
    -o -name settings.local.json -o -name PROJECT-PROFILE.md -o -name .git \) \
    ! -name '*.example' ! -name '*.sample' ! -name '*.template' | awk 'NR <= 5')"
  [ -z "$hits" ] || die "the $t build holds files that must never reach a public repository" "$hits"
done
echo "  ok  no secret-shaped files in either build"

if [ "$DRY" = 1 ]; then
  for t in $TODO; do echo "  would commit on $(t_branch "$t"): $(t_subject "$t")"; done
  echo "release: dry run, nothing written"
  exit 0
fi

# ── 7 stage ──────────────────────────────────────────────────────────────────
echo "release: staging"
for t in $TODO; do
  check_worktree "$t"
  STAGED="$STAGED $t"
  find "$(t_wt "$t")" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -R "$(t_dist "$t")/." "$(t_wt "$t")/"
  validate "$t" "$(t_wt "$t")"
  echo "  ok  $(t_branch "$t") staged and validated in place"
done

# ── 8 commit ─────────────────────────────────────────────────────────────────
for t in $TODO; do
  wt="$(t_wt "$t")"
  git -C "$wt" add -A || die "git add failed in $wt"
  git -C "$wt" commit -q -m "$(t_subject "$t")" || die "git commit failed in $wt" "nothing was pushed"
  echo "  ok  committed on $(t_branch "$t"): $(t_subject "$t")"
done
STAGED=""

# ── 9 push ───────────────────────────────────────────────────────────────────
echo "release: pushing"
for t in $TODO; do
  wt="$(t_wt "$t")"; b="$(t_branch "$t")"; r="$(t_remote "$t")"
  git -C "$wt" push -q "$r" "HEAD:refs/heads/$b" \
    || die "push of $b to $r failed; its commit is local in $wt" "finish it with: git -C $wt push $r HEAD:refs/heads/$b"
  tip="$(remote_tip "$wt" "$r" "$b")" || die "pushed $b but cannot read it back from $r"
  [ "$tip" = "$(git -C "$wt" rev-parse HEAD)" ] || die "$r's $b is not the commit just pushed" "inspect: git -C $wt ls-remote $r $b"
  PUSHED="$PUSHED $b"
  echo "  ok  $b -> $r at $(git -C "$wt" rev-parse --short HEAD) ($(git -C "$wt" remote get-url "$r" | sed -E 's|(//)[^/@]*@|\1|'))"
done

echo "release: m-skills $VERSION is on GitHub:$PUSHED"
echo "  claude plugin validate does not run the directory's safety scan or policy review: check the developer portal."
