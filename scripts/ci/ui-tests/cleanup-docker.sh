#!/bin/bash
# Cleanup Docker resources after test run
# No required env (removes all wiremock-* containers regardless of count)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Cleaning up Docker resources..."

# Stop and remove WireMock containers
"$SCRIPT_DIR/wiremock-stop.sh"

# Remove WireMock image only (avoid pruning unrelated resources on shared runner)
docker rmi tangem-wiremock 2>/dev/null || true

# Stop Colima to free resources
if command -v colima &> /dev/null; then
  echo "Stopping Colima..."
  colima stop || true
fi

echo "✅ Cleanup complete"
