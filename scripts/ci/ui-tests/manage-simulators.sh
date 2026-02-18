#!/bin/bash
# Find available simulators, boot them, and build port mapping for WireMock
# Required env: SIMULATOR_COUNT
# Optional env: RUNTIME (default: 26.2)
# Outputs to GITHUB_OUTPUT: simulator_udids, port_mapping, devices_yaml

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RUNTIME="${RUNTIME:-$(cat "$REPO_ROOT/.ios-sim-runtime" | tr -d '[:space:]')}"

echo "Looking for $SIMULATOR_COUNT available iPhone simulators with iOS $RUNTIME..."

# Get list of available iPhone simulators for the given runtime
# Format: "iPhone 17 Pro Max (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Shutdown)"
AVAILABLE_SIMS=$(xcrun simctl list devices available | grep -E -A 100 -- "-- iOS $RUNTIME" | grep -E "iPhone .+ \(" | head -n $SIMULATOR_COUNT)

echo "=== Available simulators ==="
echo "$AVAILABLE_SIMS"

# Extract UDIDs
UDIDS=$(echo "$AVAILABLE_SIMS" | grep -oE "[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}")

SIMULATOR_UDIDS=""
PORT_MAPPING=""
DEVICES_YAML=""
INDEX=0

for UDID in $UDIDS; do
  # Get simulator name for logging
  SIM_NAME=$(echo "$AVAILABLE_SIMS" | grep "$UDID" | sed 's/ (.*//g' | xargs)
  echo "Found simulator: $SIM_NAME (UDID: $UDID, port offset: $INDEX, WireMock port: $((8081 + INDEX)))"
  
  # Build UDID list (space-separated for later use)
  SIMULATOR_UDIDS="$SIMULATOR_UDIDS $UDID"
  
  # Build port mapping (comma-separated format: UDID1:0,UDID2:1,UDID3:2)
  if [ -n "$PORT_MAPPING" ]; then
    PORT_MAPPING="$PORT_MAPPING,$UDID:$INDEX"
  else
    PORT_MAPPING="$UDID:$INDEX"
  fi
  
  # Build devices YAML for Marathondevices file (use printf for newlines)
  DEVICES_YAML=$(printf '%s\n      - type: simulator\n        udid: "%s"' "$DEVICES_YAML" "$UDID")
  
  INDEX=$((INDEX + 1))
done

# Verify we found enough simulators
FOUND_COUNT=$(echo "$UDIDS" | wc -w | tr -d ' ')
if [ "$FOUND_COUNT" -lt "$SIMULATOR_COUNT" ]; then
  echo "⚠️ Warning: Found only $FOUND_COUNT simulators, requested $SIMULATOR_COUNT"
  echo "Available iPhone simulators on this runner:"
  xcrun simctl list devices available | grep -E "iPhone"
fi

# Boot simulators that are not already booted
echo "Booting simulators..."
for UDID in $SIMULATOR_UDIDS; do
  STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o "(Booted)\|(Shutdown)" | tr -d '()')
  if [ "$STATE" = "Shutdown" ]; then
    echo "Booting simulator $UDID..."
    xcrun simctl boot "$UDID" || true
  else
    echo "Simulator $UDID already booted"
  fi
done

# Wait for simulators to be ready
echo "Waiting for simulators to be ready..."
sleep 5
for UDID in $SIMULATOR_UDIDS; do
  xcrun simctl bootstatus "$UDID" -b 2>/dev/null || true
done

echo "=== Booted simulators ==="
xcrun simctl list devices booted

echo "=== Port mapping ==="
echo "$PORT_MAPPING"

# Save outputs for later steps (if running in GitHub Actions)
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "simulator_udids=$SIMULATOR_UDIDS" >> $GITHUB_OUTPUT
  echo "port_mapping=$PORT_MAPPING" >> $GITHUB_OUTPUT
  echo "devices_yaml<<EOF" >> $GITHUB_OUTPUT
  echo "$DEVICES_YAML" >> $GITHUB_OUTPUT
  echo "EOF" >> $GITHUB_OUTPUT
fi
