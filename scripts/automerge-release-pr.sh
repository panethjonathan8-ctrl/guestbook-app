#!/usr/bin/env bash
set -euo pipefail

# Usage: ./automerge-release-pr.sh
#
# Finds release-please's own Release PR (always opened from the branch
# release-please--branches--main) and enables GitHub's native auto-merge on
# it, using squash to match this repo's merge policy.
#
# Auto-merge does not bypass anything: GitHub itself still waits for the
# repo's required status checks (build, hadolint, lint, test) to pass before
# actually merging. This script only schedules the merge — it doesn't force
# it.
#
# A no-op, not an error, if no Release PR is currently open (e.g. this push
# was itself a release being cut, so there's nothing pending right now).
#
# Requires: gh CLI authenticated (GH_TOKEN), pull-requests: write permission.

PR_NUMBER=$(gh pr list \
  --head release-please--branches--main \
  --state open \
  --json number \
  --jq '.[0].number // empty')

if [ -z "$PR_NUMBER" ]; then
  echo "No open Release PR found — nothing to auto-merge."
  exit 0
fi

echo "Enabling auto-merge on Release PR #${PR_NUMBER}"
gh pr merge --auto --squash "$PR_NUMBER"
