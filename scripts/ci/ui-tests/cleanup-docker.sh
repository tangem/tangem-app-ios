#!/bin/bash
# Cleanup Docker resources after test run
# Required env: SIMULATOR_COUNT

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

echo "Cleaning up Docker resources..."

# Stop and remove WireMock containers
for i in $(seq 1 $SIMULATOR_COUNT); do
  docker rm -f wiremock-$i 2>/dev/null || true
done

# Remove WireMock image only (avoid pruning unrelated resources on shared runner)
docker rmi tangem-wiremock 2>/dev/null || true

# Stop Colima to free resources
if command -v colima &> /dev/null; then
  echo "Stopping Colima..."
  colima stop || true
fi

echo "✅ Cleanup complete"
