#!/bin/bash
# Find available simulators, boot them (recreating if broken), and build port mapping for WireMock
# Required env: SIMULATOR_COUNT
# Optional env: RUNTIME (default from .ios-sim-runtime line 2), BOOT_TIMEOUT (default: 120)
# Outputs to GITHUB_OUTPUT: simulator_udids, port_mapping, devices_yaml

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SIM_DEVICE=$(sed -n '1p' "$REPO_ROOT/.ios-sim-runtime" | xargs)
RUNTIME="${RUNTIME:-$(sed -n '2p' "$REPO_ROOT/.ios-sim-runtime" | tr -d '[:space:]')}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-120}"

# --- Helper functions ---

# Verify a simulator reaches Booted state within a timeout.
# Usage: verify_simulator_booted <udid> [timeout_seconds]
# Returns 0 if booted successfully, 1 on timeout/failure.
verify_simulator_booted() {
  local udid="$1"
  local timeout="${2:-$BOOT_TIMEOUT}"

  # Wait for boot completion using bootstatus with a timeout via background process.
  # bootstatus -b will itself wait for the simulator to reach Booted state,
  # so we don't need a separate state check that could race with boot.
  xcrun simctl bootstatus "$udid" -b &
  local pid=$!
  local elapsed=0

  while kill -0 "$pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "  Timeout (${timeout}s) waiting for simulator $udid to finish booting"
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  # Check if bootstatus exited successfully
  if wait "$pid"; then
    return 0
  else
    echo "  bootstatus check failed for simulator $udid"
    return 1
  fi
}

# Delete a broken simulator and create a fresh replacement.
# Usage: recreate_simulator <old_udid> <sim_name>
# Prints the new UDID to stdout. Returns 1 on failure.
recreate_simulator() {
  local old_udid="$1"
  local sim_name="$2"

  echo "  Deleting broken simulator $old_udid ($sim_name)..." >&2
  xcrun simctl delete "$old_udid" 2>/dev/null || true

  # Resolve the runtime identifier (e.g. "com.apple.CoreSimulator.SimRuntime.iOS-26-2")
  local runtime_id
  runtime_id=$(xcrun simctl list runtimes | grep "iOS $RUNTIME" | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.[^ ]+' | head -1)
  if [ -z "$runtime_id" ]; then
    echo "  ERROR: Could not find runtime identifier for iOS $RUNTIME" >&2
    return 1
  fi

  echo "  Creating new simulator '$sim_name' with runtime $runtime_id..." >&2
  local new_udid
  new_udid=$(xcrun simctl create "$sim_name" "$sim_name" "$runtime_id" 2>&1)

  # Validate that we got a UDID back
  if ! echo "$new_udid" | grep -qE '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$'; then
    echo "  ERROR: simctl create did not return a valid UDID: $new_udid" >&2
    return 1
  fi

  echo "$new_udid"
  return 0
}

# --- Phase 1: Discovery ---

echo "Looking for $SIMULATOR_COUNT available iPhone simulators with iOS $RUNTIME..."

# Get all available simulators matching $SIM_DEVICE for the given runtime.
# Collect all candidates so Phase 2 can skip broken ones and still find enough healthy simulators.
# Format: "iPhone 17 Pro Max (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Shutdown)"
AVAILABLE_SIMS=$(xcrun simctl list devices available | grep -E -A 100 -- "-- iOS $RUNTIME" | grep "$SIM_DEVICE" | grep -E "\(" || true)

echo "=== Candidate simulators ==="
echo "$AVAILABLE_SIMS"

# Extract UDIDs and names
CANDIDATE_UDIDS=$(echo "$AVAILABLE_SIMS" | grep -oE "[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}")

# Build associative-style lookup: SIM_NAME_<udid_underscored>=name
for UDID in $CANDIDATE_UDIDS; do
  NAME=$(echo "$AVAILABLE_SIMS" | grep "$UDID" | sed 's/ (.*//g' | xargs)
  # Store name in a variable keyed by UDID (replace dashes with underscores for valid var name)
  UDID_KEY=$(echo "$UDID" | tr '-' '_')
  printf -v "SIM_NAME_${UDID_KEY}" '%s' "$NAME"
done

# --- Phase 1b: Create additional simulators if needed ---

FOUND_COUNT=$(echo "$CANDIDATE_UDIDS" | wc -w | tr -d ' ')
if [ "$FOUND_COUNT" -lt "$SIMULATOR_COUNT" ]; then
  NEEDED=$((SIMULATOR_COUNT - FOUND_COUNT))
  echo ""
  echo "Found only $FOUND_COUNT simulators, creating $NEEDED more ($SIM_DEVICE, iOS $RUNTIME)..."

  RUNTIME_ID=$(xcrun simctl list runtimes | grep "iOS $RUNTIME" | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.[^ ]+' | head -1)
  if [ -z "$RUNTIME_ID" ]; then
    echo "ERROR: Could not find runtime identifier for iOS $RUNTIME"
    exit 1
  fi

  for i in $(seq 1 $NEEDED); do
    NEW_UDID=$(xcrun simctl create "$SIM_DEVICE" "$SIM_DEVICE" "$RUNTIME_ID" 2>&1)
    if echo "$NEW_UDID" | grep -qE '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$'; then
      echo "  Created: $SIM_DEVICE ($NEW_UDID)"
      CANDIDATE_UDIDS="$CANDIDATE_UDIDS $NEW_UDID"
      UDID_KEY=$(echo "$NEW_UDID" | tr '-' '_')
      printf -v "SIM_NAME_${UDID_KEY}" '%s' "$SIM_DEVICE"
    else
      echo "  Failed to create simulator: $NEW_UDID"
    fi
  done
fi

# --- Phase 2: Boot, verify, and optionally recreate ---

echo ""
echo "=== Booting and verifying simulators ==="
VERIFIED_UDIDS=""
VERIFIED_COUNT=0

for UDID in $CANDIDATE_UDIDS; do
  # Stop once we have enough healthy simulators
  if [ "$VERIFIED_COUNT" -ge "$SIMULATOR_COUNT" ]; then
    echo "Reached $SIMULATOR_COUNT healthy simulators, skipping remaining candidates"
    break
  fi

  UDID_KEY=$(echo "$UDID" | tr '-' '_')
  SIM_NAME_VAR="SIM_NAME_${UDID_KEY}"
  SIM_NAME="${!SIM_NAME_VAR}"

  echo "Processing: $SIM_NAME ($UDID)"

  # Check current state
  STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o "(Booted)\|(Shutdown)" | tr -d '()' || true)

  if [ "$STATE" = "Booted" ]; then
    echo "  Already booted, verifying health..."
    if verify_simulator_booted "$UDID"; then
      echo "  OK - simulator is healthy"
      VERIFIED_UDIDS="$VERIFIED_UDIDS $UDID"
      VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
      continue
    fi
    echo "  Booted but unhealthy, will recreate"
  fi

  # Attempt to boot (Shutdown or unhealthy Booted)
  if [ "$STATE" = "Shutdown" ]; then
    echo "  Booting simulator..."
    if xcrun simctl boot "$UDID" 2>&1; then
      # Give it a moment then verify
      sleep 3
      if verify_simulator_booted "$UDID"; then
        echo "  OK - simulator booted successfully"
        VERIFIED_UDIDS="$VERIFIED_UDIDS $UDID"
        VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
        continue
      fi
      echo "  Boot command succeeded but verification failed"
    else
      echo "  Boot command failed"
    fi
  fi

  # Boot failed or verification failed — try to recreate
  echo "  Attempting to recreate simulator..."
  NEW_UDID=$(recreate_simulator "$UDID" "$SIM_NAME") || {
    echo "  SKIP - failed to recreate simulator for slot $SIM_NAME"
    continue
  }
  echo "  Created new simulator: $NEW_UDID"

  echo "  Booting new simulator..."
  if xcrun simctl boot "$NEW_UDID" 2>&1; then
    sleep 3
    if verify_simulator_booted "$NEW_UDID"; then
      echo "  OK - recreated simulator booted successfully"
      VERIFIED_UDIDS="$VERIFIED_UDIDS $NEW_UDID"
      VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
      continue
    fi
    echo "  Recreated simulator failed verification"
  else
    echo "  Failed to boot recreated simulator"
  fi

  # Cleanup the failed recreation
  echo "  SKIP - giving up on slot $SIM_NAME"
  xcrun simctl delete "$NEW_UDID" 2>/dev/null || true
done

# --- Phase 3: Validate and build outputs ---

# Trim leading space
VERIFIED_UDIDS=$(echo "$VERIFIED_UDIDS" | xargs)

VERIFIED_COUNT=$(echo "$VERIFIED_UDIDS" | wc -w | tr -d ' ')
echo ""
echo "=== Verification result: $VERIFIED_COUNT of $SIMULATOR_COUNT simulators healthy ==="

if [ "$VERIFIED_COUNT" -eq 0 ]; then
  echo "ERROR: No simulators are available after boot verification. Cannot proceed."
  echo "All candidate simulators failed to boot or were unhealthy."
  echo "Available iPhone simulators on this runner:"
  xcrun simctl list devices available | grep -E "iPhone"
  exit 1
fi

if [ "$VERIFIED_COUNT" -lt "$SIMULATOR_COUNT" ]; then
  echo "Warning: Only $VERIFIED_COUNT simulators available, requested $SIMULATOR_COUNT"
  echo "Continuing with reduced simulator count."
fi

# Build output variables from verified UDIDs with consecutive indices
SIMULATOR_UDIDS=""
PORT_MAPPING=""
DEVICES_YAML=""
INDEX=0

for UDID in $VERIFIED_UDIDS; do
  # Get simulator name for logging
  SIM_NAME=$(xcrun simctl list devices | grep "$UDID" | sed 's/ (.*//g' | xargs)
  echo "Verified simulator: $SIM_NAME (UDID: $UDID, port offset: $INDEX, WireMock port: $((8081 + INDEX)))"

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

# --- Phase 4: Output ---

echo ""
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
