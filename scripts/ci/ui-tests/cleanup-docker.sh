#!/bin/bash
# Cleanup Docker resources after test run
# No required env (removes all wiremock-* containers regardless of count)

set -e

echo "Cleaning up Docker resources..."

# Stop and remove WireMock containers
docker ps -aq --filter "name=^/wiremock-[0-9]+$" | xargs docker rm -f 2>/dev/null || true

# Remove WireMock image only (avoid pruning unrelated resources on shared runner)
docker rmi tangem-wiremock 2>/dev/null || true

# Stop Colima to free resources
if command -v colima &> /dev/null; then
  echo "Stopping Colima..."
  colima stop || true
fi

echo "✅ Cleanup complete"
