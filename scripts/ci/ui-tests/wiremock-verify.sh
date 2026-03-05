#!/bin/bash
# Verify WireMock containers are healthy
# Required env: SIMULATOR_COUNT, SIMULATOR_PORT_MAPPING

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

if [ -z "$SIMULATOR_PORT_MAPPING" ]; then
  echo "⚠️ Warning: SIMULATOR_PORT_MAPPING not set, using default port mapping"
  # Generate default port mapping for verification
  SIMULATOR_PORT_MAPPING=""
  for i in $(seq 1 $SIMULATOR_COUNT); do
    if [ -n "$SIMULATOR_PORT_MAPPING" ]; then
      SIMULATOR_PORT_MAPPING="$SIMULATOR_PORT_MAPPING,placeholder$i:$((i-1))"
    else
      SIMULATOR_PORT_MAPPING="placeholder1:0"
    fi
  done
  echo "Generated fallback mapping: $SIMULATOR_PORT_MAPPING"
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
