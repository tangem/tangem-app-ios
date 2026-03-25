#!/bin/bash
# Start WireMock containers for parallel testing
# Required env: SIMULATOR_COUNT

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

# Cleanup existing containers from previous runs
for i in $(seq 1 $SIMULATOR_COUNT); do
  docker rm -f wiremock-$i 2>/dev/null || true
done

for i in $(seq 1 $SIMULATOR_COUNT); do
  WIREMOCK_PORT=$((8080 + i))
  echo "Starting WireMock instance $i on port $WIREMOCK_PORT..."

  docker run -d \
    --name wiremock-$i \
    -p $WIREMOCK_PORT:8080 \
    tangem-wiremock
done

# Wait for all instances to be ready
for i in $(seq 1 $SIMULATOR_COUNT); do
  WIREMOCK_PORT=$((8080 + i))
  echo "Waiting for WireMock on port $WIREMOCK_PORT..."
  for attempt in {1..30}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WIREMOCK_PORT/__admin/mappings" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
      MAPPING_COUNT=$(curl -s "http://localhost:$WIREMOCK_PORT/__admin/mappings" | jq '.meta.total' 2>/dev/null || echo "unknown")
      echo "WireMock $i ready! Mappings loaded: $MAPPING_COUNT"
      break
    fi
    if [ "$attempt" = "30" ]; then
      echo "ERROR: WireMock $i failed to start!"
      docker logs wiremock-$i
      exit 1
    fi
    sleep 1
  done
done

# Verify mappings
echo "=== WireMock mappings sample ==="
curl -s "http://localhost:8081/__admin/mappings" | head -c 500 || echo "Failed to get mappings"
echo ""
