#!/usr/bin/env bash
set -euo pipefail

# Usage: ./resolve-release-image.sh <new-release-tag>
#
# Given a release-please release tag (e.g. v1.3.0), figures out which
# already-built dev image should be promoted to staging/prod, and whether
# there is anything new to promote at all.
#
# release-please tags the commit where its Release PR was merged, but that
# commit only touches CHANGELOG.md/VERSION — never app/ or Dockerfile. So the
# image to promote is not "the image built at this tag" (no such image
# exists), it's the image built for the most recent commit, reachable from
# this tag, that actually changed app/ or Dockerfile.
#
# "Changed since last release" is answered by resolving the same thing for
# the previous release tag and comparing the two SHAs. If they're the same
# commit, nothing app-relevant has happened since the last promotion, so
# staging/prod are left exactly as they are.
#
# Requires a full checkout (fetch-depth: 0) — shallow clones don't have the
# tag/commit history this script walks.
#
# Outputs (printed, and appended to $GITHUB_OUTPUT when set):
#   source_sha=<short sha of the commit whose dev image should be promoted>
#   changed=true|false

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <new-release-tag>" >&2
  exit 1
fi

NEW_TAG="$1"

if ! git rev-parse "$NEW_TAG" >/dev/null 2>&1; then
  echo "Error: tag '$NEW_TAG' not found in this checkout" >&2
  exit 1
fi

SOURCE_SHA=$(git log -1 --format=%h "$NEW_TAG" -- app/ Dockerfile)

if [ -z "$SOURCE_SHA" ]; then
  echo "Error: no commit reachable from '$NEW_TAG' touches app/ or Dockerfile" >&2
  exit 1
fi

PREV_TAG=$(git describe --tags --abbrev=0 "${NEW_TAG}^" 2>/dev/null || true)

if [ -z "$PREV_TAG" ]; then
  echo "No previous release tag found — first release, always promoting." >&2
  CHANGED=true
else
  PREV_SOURCE_SHA=$(git log -1 --format=%h "$PREV_TAG" -- app/ Dockerfile)
  if [ "$SOURCE_SHA" = "$PREV_SOURCE_SHA" ]; then
    CHANGED=false
  else
    CHANGED=true
  fi
fi

echo "source_sha=${SOURCE_SHA}"
echo "changed=${CHANGED}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "source_sha=${SOURCE_SHA}"
    echo "changed=${CHANGED}"
  } >>"$GITHUB_OUTPUT"
fi
