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

# Wait for all instances to be ready (parallel check with resource monitoring)
echo "Checking WireMock instances readiness in parallel..."
echo "Starting health checks for $SIMULATOR_COUNT WireMock instances..."

# Start parallel health checks
HEALTH_PIDS=()
for i in $(seq 1 $SIMULATOR_COUNT); do
  WIREMOCK_PORT=$((8080 + i))
  (
    echo "Waiting for WireMock on port $WIREMOCK_PORT..."
    for attempt in $(seq 1 40); do
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WIREMOCK_PORT/__admin/mappings" 2>/dev/null || echo "000")
      if [ "$HTTP_CODE" = "200" ]; then
        MAPPING_COUNT=$(curl -s "http://localhost:$WIREMOCK_PORT/__admin/mappings" | jq '.meta.total' 2>/dev/null || echo "unknown")
        echo "✅ WireMock $i ready! Mappings loaded: $MAPPING_COUNT (attempt $attempt)"

        # Additional health check - test a sample endpoint
        HEALTH_CHECK=$(curl -s "http://localhost:$WIREMOCK_PORT/__admin/health" | jq '.status' 2>/dev/null || echo "unknown")
        if [ "$HEALTH_CHECK" = "\"OK\"" ]; then
          echo "✅ WireMock $i health check passed"
        fi
        exit 0
      fi
      if [ "$attempt" = "40" ]; then
        echo "❌ ERROR: WireMock $i failed to start after 40 attempts (40s)!"
        echo "Container logs:"
        docker logs wiremock-$i 2>/dev/null || echo "No logs available"
        exit 1
      fi
      sleep 1
    done
  ) &
  HEALTH_PIDS+=($!)
done

# Wait for all health checks and verify each succeeded
HEALTH_FAILURES=0
for pid in "${HEALTH_PIDS[@]}"; do
  if ! wait $pid; then
    HEALTH_FAILURES=$((HEALTH_FAILURES + 1))
  fi
done
if [ $HEALTH_FAILURES -gt 0 ]; then
  echo "❌ ERROR: $HEALTH_FAILURES WireMock instance(s) failed to start!"
  exit 1
fi
echo "🎉 All $SIMULATOR_COUNT WireMock instances are ready!"

# Verify mappings
echo "=== WireMock mappings sample ==="
curl -s "http://localhost:8081/__admin/mappings" | head -c 500 || echo "Failed to get mappings"
echo ""
