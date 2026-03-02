#!/bin/bash
# Cleanup simulators after test run
# Keeps exactly one simulator matching the model and runtime from .ios-sim-runtime
# Deletes all other simulators to free disk space
# Required env: SIMULATOR_UDIDS (space-separated list of UDIDs to shutdown first)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Read config from .ios-sim-runtime (line 1: device model, line 2: runtime version)
SIM_DEVICE=$(sed -n '1p' "$REPO_ROOT/.ios-sim-runtime" | xargs)
RUNTIME=$(sed -n '2p' "$REPO_ROOT/.ios-sim-runtime" | tr -d '[:space:]')

echo "Target device to keep: $SIM_DEVICE (iOS $RUNTIME)"

# Phase 1: Shutdown simulators used in this run
if [ -n "$SIMULATOR_UDIDS" ]; then
  for UDID in $SIMULATOR_UDIDS; do
    echo "Shutting down simulator: $UDID"
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
  done
fi

# Phase 2: Find matching simulators, keep exactly one, delete the rest
KEEP_UDID=""
MATCHING_UDIDS=$(xcrun simctl list devices "iOS $RUNTIME" | grep "$SIM_DEVICE" | grep -oE '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}' || true)

for UDID in $MATCHING_UDIDS; do
  if [ -z "$KEEP_UDID" ]; then
    KEEP_UDID="$UDID"
    echo "Keeping: $SIM_DEVICE ($UDID)"
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
    xcrun simctl erase "$UDID" 2>/dev/null || true
  else
    echo "Deleting extra: $SIM_DEVICE ($UDID)"
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
    xcrun simctl delete "$UDID" 2>/dev/null || true
  fi
done

if [ -z "$KEEP_UDID" ]; then
  echo "⚠️ No simulators found for $SIM_DEVICE (iOS $RUNTIME), nothing to keep"
fi

# Phase 3: Delete all remaining simulators (different models/runtimes)
# Only proceed if we have a simulator to keep; otherwise we'd delete everything on the runner
if [ -n "$KEEP_UDID" ]; then
  ALL_UDIDS=$(xcrun simctl list devices | grep -oE '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}' || true)

  for UDID in $ALL_UDIDS; do
    if [ "$UDID" != "$KEEP_UDID" ]; then
      echo "Deleting: $UDID"
      xcrun simctl shutdown "$UDID" 2>/dev/null || true
      xcrun simctl delete "$UDID" 2>/dev/null || true
    fi
  done
else
  echo "WARNING: No matching simulator found to keep, skipping cleanup of other simulators to avoid deleting all devices on this runner"
fi

# Clean up unavailable simulators (stale runtimes)
xcrun simctl delete unavailable 2>/dev/null || true

echo "Simulator cleanup complete"
if [ -n "$KEEP_UDID" ]; then
  echo "Kept 1 simulator: $SIM_DEVICE iOS $RUNTIME ($KEEP_UDID)"
fi
