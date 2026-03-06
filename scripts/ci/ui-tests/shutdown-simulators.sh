#!/bin/bash
# Cleanup simulators after test run.
# Keeps matching simulators (just shuts them down) so the next run can
# reuse them WITHOUT triggering Data Migration, which is extremely expensive
# when multiple fresh simulators migrate concurrently.
# If disk space is low, trims the pool down to MIN_KEEP to free space.
# Only deletes simulators for non-matching runtimes/models.
# Required env: SIMULATOR_UDIDS (space-separated list of UDIDs to shutdown first)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Disk threshold: if available space drops below this, trim simulator pool
MIN_DISK_GB="${MIN_DISK_GB:-20}"
# Minimum simulators to always keep (even when trimming for disk)
MIN_KEEP=1

# Read config from .ios-sim-runtime (line 1: device model, line 2: runtime version)
SIM_DEVICE=$(sed -n '1p' "$REPO_ROOT/.ios-sim-runtime" | xargs)
RUNTIME=$(sed -n '2p' "$REPO_ROOT/.ios-sim-runtime" | tr -d '[:space:]')

echo "Target device: $SIM_DEVICE (iOS $RUNTIME)"

# Phase 1: Shutdown simulators used in this run
if [ -n "$SIMULATOR_UDIDS" ]; then
  for UDID in $SIMULATOR_UDIDS; do
    echo "Shutting down simulator: $UDID"
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
  done
fi

# Phase 2: Shutdown (but keep!) all matching simulators.
# NOT erasing — erase triggers Data Migration on next boot.
MATCHING_UDIDS=$(xcrun simctl list devices "iOS $RUNTIME" | grep "$SIM_DEVICE" | grep -oE '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}' || true)
MATCHING_COUNT=0
MATCHING_ARRAY=()

for UDID in $MATCHING_UDIDS; do
  xcrun simctl shutdown "$UDID" 2>/dev/null || true
  MATCHING_ARRAY+=("$UDID")
  MATCHING_COUNT=$((MATCHING_COUNT + 1))
done

echo "Found $MATCHING_COUNT matching simulator(s)"

if [ "$MATCHING_COUNT" -eq 0 ]; then
  echo "⚠️ No simulators found for $SIM_DEVICE (iOS $RUNTIME), nothing to keep"
fi

# Phase 3: Disk-aware trimming — delete extra matching sims if disk is low
if [ "$MATCHING_COUNT" -gt "$MIN_KEEP" ]; then
  AVAILABLE_GB=$(df -g / | tail -1 | awk '{print $4}')
  echo "Available disk space: ${AVAILABLE_GB}GB (threshold: ${MIN_DISK_GB}GB)"

  if [ "$AVAILABLE_GB" -lt "$MIN_DISK_GB" ]; then
    echo "⚠️ Low disk space — trimming simulator pool from $MATCHING_COUNT to $MIN_KEEP"
    TRIM_INDEX=0
    for UDID in "${MATCHING_ARRAY[@]}"; do
      if [ "$TRIM_INDEX" -lt "$MIN_KEEP" ]; then
        echo "  Keeping: $UDID"
      else
        echo "  Deleting (disk pressure): $UDID"
        xcrun simctl delete "$UDID" 2>/dev/null || true
      fi
      TRIM_INDEX=$((TRIM_INDEX + 1))
    done
    # Recalculate
    MATCHING_COUNT=$MIN_KEEP
    AFTER_GB=$(df -g / | tail -1 | awk '{print $4}')
    echo "  Disk after trimming: ${AFTER_GB}GB"
  else
    echo "Disk OK — keeping all $MATCHING_COUNT simulator(s) for next run"
  fi
fi

for UDID in "${MATCHING_ARRAY[@]:0:$MATCHING_COUNT}"; do
  echo "Kept: $SIM_DEVICE ($UDID)"
done

# Phase 4: Delete simulators for OTHER models/runtimes (saves disk space)
if [ "$MATCHING_COUNT" -gt 0 ]; then
  MATCHING_SET=" $MATCHING_UDIDS "
  ALL_UDIDS=$(xcrun simctl list devices | grep -oE '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}' || true)
  DELETED=0

  for UDID in $ALL_UDIDS; do
    if [[ "$MATCHING_SET" != *" $UDID "* ]]; then
      echo "Deleting (non-matching): $UDID"
      xcrun simctl shutdown "$UDID" 2>/dev/null || true
      xcrun simctl delete "$UDID" 2>/dev/null || true
      DELETED=$((DELETED + 1))
    fi
  done
  [ "$DELETED" -gt 0 ] && echo "Deleted $DELETED non-matching simulator(s)"
fi

# Clean up unavailable simulators (stale runtimes)
xcrun simctl delete unavailable 2>/dev/null || true

echo "Simulator cleanup complete: kept $MATCHING_COUNT $SIM_DEVICE iOS $RUNTIME simulator(s)"
