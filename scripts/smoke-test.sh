#!/usr/bin/env bash
set -euo pipefail

# Usage: ./smoke-test.sh <alb-hostname> <host-header>
# Retries for up to 2 minutes to account for ALB DNS propagation and pod startup.

ALB_URL="$1"
HOST="$2"

echo "Smoke test: http://${ALB_URL}  Host: ${HOST}"

for i in $(seq 1 12); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    -H "Host: ${HOST}" \
    "http://${ALB_URL}")

  echo "[$i/12] HTTP ${HTTP_CODE}"

  if [ "$HTTP_CODE" = "200" ]; then
    echo "Smoke test passed"
    exit 0
  fi

  sleep 10
done

echo "Smoke test failed: did not receive HTTP 200 after 2 minutes"
exit 1
