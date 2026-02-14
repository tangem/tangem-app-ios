#!/bin/bash
# Verify request distribution across WireMock instances
# Required env: SIMULATOR_COUNT

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Request Distribution Across WireMock Instances         ║"
echo "╠════════════════════════════════════════════════════════════════╣"

TOTAL_REQUESTS=0
declare -a REQUEST_COUNTS

for i in $(seq 1 $SIMULATOR_COUNT); do
  PORT=$((8080 + i))
  REQUEST_COUNT=$(curl -s -X POST -H 'Content-Type: application/json' -d '{}' "http://localhost:$PORT/__admin/requests/count" | jq '.count // 0' 2>/dev/null || echo "0")
  REQUEST_COUNTS[$i]=$REQUEST_COUNT
  
  # Get unmatched requests count (potential issues)
  UNMATCHED=$(curl -s "http://localhost:$PORT/__admin/requests/unmatched" | jq '.meta.total // 0' 2>/dev/null || echo "0")
  
  echo "║ WireMock $i (port $PORT): $REQUEST_COUNT requests (unmatched: $UNMATCHED)"
  TOTAL_REQUESTS=$((TOTAL_REQUESTS + REQUEST_COUNT))
done

echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ Total requests: $TOTAL_REQUESTS"
echo "╚════════════════════════════════════════════════════════════════╝"

# Verify distribution - each instance should have received requests
echo ""
echo "=== Distribution Analysis ==="
ALL_RECEIVED=true
for i in $(seq 1 $SIMULATOR_COUNT); do
  PORT=$((8080 + i))
  REQUEST_COUNT=${REQUEST_COUNTS[$i]}
  
  if [ "$REQUEST_COUNT" -eq "0" ]; then
    echo "⚠️  WireMock $i (port $PORT) received NO requests - possible routing issue!"
    ALL_RECEIVED=false
  else
    echo "✅ WireMock $i (port $PORT) received $REQUEST_COUNT requests"
  fi
done

if [ "$ALL_RECEIVED" = "true" ]; then
  echo ""
  echo "✅ All WireMock instances received requests - parallel routing working correctly!"
else
  echo ""
  echo "⚠️  Some WireMock instances received no requests - check SIMULATOR_PORT_MAPPING"
fi
