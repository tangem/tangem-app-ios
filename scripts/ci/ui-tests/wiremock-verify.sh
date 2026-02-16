#!/bin/bash
# Verify WireMock containers are healthy
# Required env: SIMULATOR_COUNT, SIMULATOR_PORT_MAPPING

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

if [ -z "$SIMULATOR_PORT_MAPPING" ]; then
  echo "ERROR: SIMULATOR_PORT_MAPPING environment variable is required"
  exit 1
fi

echo "=== Checking WireMock containers ==="
for i in $(seq 1 $SIMULATOR_COUNT); do
  PORT=$((8080 + i))
  echo "Checking WireMock on port $PORT..."
  
  # Check health
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/__admin/mappings")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ WireMock on port $PORT is healthy"
    # Show mapping count
    MAPPING_COUNT=$(curl -s "http://localhost:$PORT/__admin/mappings" | jq '.mappings | length')
    echo "   Mappings loaded: $MAPPING_COUNT"
  else
    echo "❌ WireMock on port $PORT returned HTTP $HTTP_CODE"
    exit 1
  fi
done

echo ""
echo "=== Port Mapping ==="
echo "SIMULATOR_PORT_MAPPING: $SIMULATOR_PORT_MAPPING"
echo ""
echo "=== Simulators ==="
xcrun simctl list devices booted
