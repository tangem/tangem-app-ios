#!/bin/bash
# Collect WireMock logs from all containers
# Required env: SIMULATOR_COUNT

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

mkdir -p ./wiremock-logs

for i in $(seq 1 $SIMULATOR_COUNT); do
  echo "=== WireMock instance $i logs ==="
  docker logs wiremock-$i > ./wiremock-logs/wiremock_$i.log 2>&1 || echo "No logs for instance $i"
  tail -100 ./wiremock-logs/wiremock_$i.log || true

  WIREMOCK_PORT=$((8080 + i))
  echo "--- Request stats (port $WIREMOCK_PORT) ---"
  curl -s -X POST -H 'Content-Type: application/json' -d '{}' "http://localhost:$WIREMOCK_PORT/__admin/requests/count" 2>/dev/null || echo "Could not get request count"
done
