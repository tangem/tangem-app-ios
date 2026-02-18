#!/bin/bash
# Shutdown simulators (keep them for next run)
# Required env: SIMULATOR_UDIDS (space-separated list of UDIDs)

set -e

if [ -z "$SIMULATOR_UDIDS" ]; then
  echo "⚠️ SIMULATOR_UDIDS is empty, nothing to shutdown"
  exit 0
fi

# Just shutdown, don't delete - simulators are reused between runs
for UDID in $SIMULATOR_UDIDS; do
  echo "Shutting down simulator: $UDID"
  xcrun simctl shutdown "$UDID" 2>/dev/null || true
done

echo "Simulators shutdown complete"
