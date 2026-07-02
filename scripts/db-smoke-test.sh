#!/usr/bin/env bash
set -euo pipefail

# Usage: ./db-smoke-test.sh <alb-hostname> <host-header>
# Posts a timestamped message via the JSON API and reads it back.
# Proves the app can write to and read from RDS — not just serve HTTP.

ALB_URL="$1"
HOST="$2"
TAG="smoke-$(date +%s)-$$"

echo "DB smoke test: host=${HOST} tag=${TAG}"

# POST a test message via the JSON API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Host: ${HOST}" \
  -d "{\"name\":\"smoke-test\",\"message\":\"${TAG}\"}" \
  "http://${ALB_URL}/messages")

if [ "$HTTP_CODE" != "201" ]; then
  echo "DB smoke test failed: POST /messages returned HTTP ${HTTP_CODE}, expected 201"
  exit 1
fi

echo "POST succeeded (HTTP 201)"

# GET /messages and verify the tag appears in the response
RESPONSE=$(curl -sf \
  --max-time 10 \
  -H "Host: ${HOST}" \
  "http://${ALB_URL}/messages")

if echo "$RESPONSE" | grep -q "$TAG"; then
  echo "DB smoke test passed: message round-tripped through RDS"
  exit 0
else
  echo "DB smoke test failed: posted message not found in GET /messages"
  echo "Response: $RESPONSE"
  exit 1
fi
