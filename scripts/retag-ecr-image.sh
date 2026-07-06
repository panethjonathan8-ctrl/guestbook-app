#!/usr/bin/env bash
set -euo pipefail

# Usage: ./retag-ecr-image.sh <repository-name> <source-tag> <new-tag>
#
# Adds <new-tag> to the same image digest already tagged <source-tag>, without
# pulling or pushing any image layers. This is how a dev-built image (tagged
# with its git SHA) becomes "the same image, also called 1.3.0" for staging
# and prod — no rebuild, no risk of the rebuilt bytes differing from what dev
# already ran.
#
# Requires AWS credentials already configured (e.g. via configure-aws-credentials)
# with ecr:BatchGetImage and ecr:PutImage on this repository.

if [ -z "${1:-}" ] || [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
  echo "Usage: $0 <repository-name> <source-tag> <new-tag>" >&2
  exit 1
fi

REPO_NAME="$1"
SOURCE_TAG="$2"
NEW_TAG="$3"

MANIFEST=$(aws ecr batch-get-image \
  --repository-name "$REPO_NAME" \
  --image-ids imageTag="$SOURCE_TAG" \
  --query 'images[0].imageManifest' \
  --output text)

if [ -z "$MANIFEST" ] || [ "$MANIFEST" = "None" ]; then
  echo "Error: no image found in ECR repository '$REPO_NAME' tagged '$SOURCE_TAG'" >&2
  exit 1
fi

if aws ecr put-image \
  --repository-name "$REPO_NAME" \
  --image-tag "$NEW_TAG" \
  --image-manifest "$MANIFEST" >/dev/null 2>&1; then
  echo "Tagged ${REPO_NAME}:${SOURCE_TAG} as ${REPO_NAME}:${NEW_TAG}"
else
  # put-image fails if this exact tag+digest combination already exists.
  # Treat that as success — e.g. a re-run of this workflow after a
  # later step failed.
  EXISTING=$(aws ecr batch-get-image \
    --repository-name "$REPO_NAME" \
    --image-ids imageTag="$NEW_TAG" \
    --query 'images[0].imageManifest' \
    --output text 2>/dev/null || true)
  if [ "$EXISTING" = "$MANIFEST" ]; then
    echo "${REPO_NAME}:${NEW_TAG} already points at the same image — nothing to do"
  else
    echo "Error: failed to tag ${REPO_NAME}:${NEW_TAG}" >&2
    exit 1
  fi
fi
