#!/bin/bash
# Find available simulators, boot them, and build port mapping for WireMock
# Required env: SIMULATOR_COUNT
# Optional env: RUNTIME (default: 26.2)
# Outputs to GITHUB_OUTPUT: simulator_udids, port_mapping, devices_yaml

set -e

# Timeout wrapper for macOS (no GNU timeout available).
# Runs a command with a deadline; kills it if it exceeds the limit.
# Usage: run_with_timeout <seconds> <command> [args...]
run_with_timeout() {
  local timeout=$1; shift
  "$@" &
  local cmd_pid=$!
  ( sleep "$timeout" && kill "$cmd_pid" 2>/dev/null ) &
  local timer_pid=$!
  wait "$cmd_pid" 2>/dev/null
  local exit_code=$?
  # Kill the timer subshell and its child sleep process
  pkill -P "$timer_pid" 2>/dev/null || true
  kill "$timer_pid" 2>/dev/null || true
  wait "$timer_pid" 2>/dev/null || true
  return $exit_code
}

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RUNTIME="${RUNTIME:-$(sed -n '2p' "$REPO_ROOT/.ios-sim-runtime" | tr -d '[:space:]')}"

# 1. Get list of ALL available iPhone simulators for the given runtime
# Format: "iPhone 17 Pro Max (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Shutdown)"
EXISTING_DEVICES=$(xcrun simctl list devices available | sed -n "/-- iOS $RUNTIME/,/^--/p" | grep -E "iPhone .+ \(") || true
EXISTING_COUNT=$(echo "$EXISTING_DEVICES" | grep -c . || echo "0")

if [ -z "$EXISTING_DEVICES" ]; then EXISTING_COUNT=0; fi

echo "Found $EXISTING_COUNT existing iPhone simulators."

# 1b. Health-check existing simulators — delete any whose data directory is missing
# (happens when CoreSimulator/Caches was cleaned while simulators were registered)
if [ -n "$EXISTING_DEVICES" ]; then
  HEALTHY_DEVICES=""
  CORRUPTED=0
  while IFS= read -r LINE; do
    UDID=$(echo "$LINE" | grep -oE "[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}")
    DATA_DIR="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data"
    if [ -d "$DATA_DIR" ]; then
      if [ -z "$HEALTHY_DEVICES" ]; then
        HEALTHY_DEVICES="$LINE"
      else
        HEALTHY_DEVICES="$HEALTHY_DEVICES
$LINE"
      fi
    else
      echo "⚠️ Simulator $UDID is corrupted (missing $DATA_DIR), deleting..."
      xcrun simctl delete "$UDID" 2>/dev/null || true
      CORRUPTED=$((CORRUPTED + 1))
    fi
  done <<< "$EXISTING_DEVICES"

  if [ $CORRUPTED -gt 0 ]; then
    echo "Deleted $CORRUPTED corrupted simulator(s)"
    EXISTING_DEVICES="$HEALTHY_DEVICES"
    EXISTING_COUNT=$(echo "$EXISTING_DEVICES" | grep -c . 2>/dev/null || echo "0")
    if [ -z "$EXISTING_DEVICES" ]; then EXISTING_COUNT=0; fi
    echo "Healthy simulators remaining: $EXISTING_COUNT"
  fi
fi

# 2. Check if we need to create more
NEEDED=$((SIMULATOR_COUNT - EXISTING_COUNT))

if [ $NEEDED -gt 0 ]; then
  echo "Need to create $NEEDED more simulators..."
  
  # Determine which model to create
  if [ $EXISTING_COUNT -gt 0 ]; then
    # Reuse model of the first existing simulator
    # "iPhone 17 Pro Max (..." -> "iPhone 17 Pro Max"
    FIRST_LINE=$(echo "$EXISTING_DEVICES" | head -1)
    MODEL_NAME=$(echo "$FIRST_LINE" | sed 's/ (.*//' | xargs)
  else
    # No existing devices found - this should not happen on a properly configured agent
    echo "ERROR: No existing iPhone simulators found for iOS $RUNTIME! Cannot determine which model to clone."
    echo "This runner is expected to have at least one iPhone simulator pre-installed."
    echo "Available runtimes:"
    xcrun simctl list runtimes
    exit 1
  fi
  
  echo "Will create $NEEDED instances of '$MODEL_NAME'"
  
  # Resolve IDs
  DEV_TYPE_ID=$(xcrun simctl list devicetypes | grep -w "$MODEL_NAME" | head -1 | sed 's/.*(\(.*\))/\1/')
  
  if [ -z "$DEV_TYPE_ID" ]; then
    echo "ERROR: Could not resolve Device Type ID for '$MODEL_NAME'"
    # Fallback cleanup?
    exit 1
  fi
  
  RUNTIME_SUFFIX=$(echo "$RUNTIME" | tr '.' '-')
  RUNTIME_ID="com.apple.CoreSimulator.SimRuntime.iOS-$RUNTIME_SUFFIX"
  
  # Create in parallel
  CREATE_PIDS=()
  for i in $(seq 1 $NEEDED); do
    echo "Creating simulator #$i: '$MODEL_NAME'"
    xcrun simctl create "$MODEL_NAME" "$DEV_TYPE_ID" "$RUNTIME_ID" &
    CREATE_PIDS+=($!)
  done
  CREATE_FAILURES=0
  for pid in "${CREATE_PIDS[@]}"; do
    if ! wait "$pid"; then
      CREATE_FAILURES=$((CREATE_FAILURES + 1))
    fi
  done
  if [ $CREATE_FAILURES -gt 0 ]; then
    echo "WARNING: $CREATE_FAILURES simulator creation(s) failed"
  fi
  
  # Refresh list
  EXISTING_DEVICES=$(xcrun simctl list devices available | sed -n "/-- iOS $RUNTIME/,/^--/p" | grep -E "iPhone .+ \(")
fi

# 3. Select the required number of simulators
AVAILABLE_SIMS=$(echo "$EXISTING_DEVICES" | head -n $SIMULATOR_COUNT)

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

# Boot simulators that are not already booted (PARALLEL with staggered startup)
echo "Booting simulators in parallel with staggered startup..."
BATCH_SIZE=4  # Boot in batches to balance speed vs resource contention
SIMULATOR_ARRAY=($SIMULATOR_UDIDS)
TOTAL_SIMULATORS=${#SIMULATOR_ARRAY[@]}

for ((batch_start=0; batch_start<TOTAL_SIMULATORS; batch_start+=BATCH_SIZE)); do
  batch_end=$((batch_start + BATCH_SIZE))
  if [ $batch_end -gt $TOTAL_SIMULATORS ]; then
    batch_end=$TOTAL_SIMULATORS
  fi
  
  echo "Booting batch $((batch_start/BATCH_SIZE + 1)): simulators $((batch_start + 1))-$batch_end"
  
  # Boot current batch in parallel
  for ((i=batch_start; i<batch_end; i++)); do
    UDID=${SIMULATOR_ARRAY[$i]}
    STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o "(Booted)\|(Shutdown)" | tr -d '()')
    if [ "$STATE" = "Shutdown" ]; then
      echo "Booting simulator $UDID..."
      xcrun simctl boot "$UDID" &
    else
      echo "Simulator $UDID already booted"
    fi
  done
  wait
  
  # Small delay between batches to prevent resource spikes
  if [ $batch_end -lt $TOTAL_SIMULATORS ]; then
    echo "Waiting 3 seconds before next batch..."
    sleep 3
  fi
done

# Wait for simulators to be ready IN PARALLEL (with timeout to prevent indefinite hangs)
# xcrun simctl bootstatus -b blocks forever if system app never becomes ready,
# so we poll instead with a hard timeout per simulator.
BOOT_TIMEOUT=120  # seconds per simulator
BOOT_STATUS_DIR=$(mktemp -d)
echo "Waiting for all simulators to be ready in parallel (timeout: ${BOOT_TIMEOUT}s each)..."

for UDID in $SIMULATOR_UDIDS; do
  (
    SECONDS_WAITED=0
    while [ $SECONDS_WAITED -lt $BOOT_TIMEOUT ]; do
      # Check device state via simctl list (with 10s timeout to prevent hangs)
      DEVICE_STATE=$(run_with_timeout 10 xcrun simctl list devices 2>/dev/null || true)
      if echo "$DEVICE_STATE" | grep "$UDID" | grep -q "(Booted)"; then
        echo "Simulator $UDID: booted and ready (${SECONDS_WAITED}s)"
        echo "ok" > "$BOOT_STATUS_DIR/$UDID"
        exit 0
      fi
      sleep 3
      SECONDS_WAITED=$((SECONDS_WAITED + 3))
    done
    # Timed out — attempt shutdown + reboot recovery
    echo "WARNING: Simulator $UDID did not boot within ${BOOT_TIMEOUT}s"
    echo "  Attempting shutdown + reboot..."
    run_with_timeout 15 xcrun simctl shutdown "$UDID" 2>/dev/null || true
    sleep 2
    run_with_timeout 15 xcrun simctl boot "$UDID" 2>/dev/null || true
    sleep 5
    RECOVERY_STATE=$(run_with_timeout 10 xcrun simctl list devices 2>/dev/null || true)
    if echo "$RECOVERY_STATE" | grep "$UDID" | grep -q "(Booted)"; then
      echo "  Simulator $UDID: recovered after reboot"
      echo "ok" > "$BOOT_STATUS_DIR/$UDID"
    else
      echo "  ERROR: Simulator $UDID failed to recover"
      echo "fail" > "$BOOT_STATUS_DIR/$UDID"
    fi
  ) &
done
wait

# Check results from parallel boot checks
BOOT_FAILURES=0
for UDID in $SIMULATOR_UDIDS; do
  if [ -f "$BOOT_STATUS_DIR/$UDID" ]; then
    STATUS=$(cat "$BOOT_STATUS_DIR/$UDID")
    if [ "$STATUS" = "fail" ]; then
      BOOT_FAILURES=$((BOOT_FAILURES + 1))
    fi
  else
    echo "WARNING: No boot status recorded for $UDID"
    BOOT_FAILURES=$((BOOT_FAILURES + 1))
  fi
done
rm -rf "$BOOT_STATUS_DIR"

if [ $BOOT_FAILURES -gt 0 ]; then
  echo "WARNING: $BOOT_FAILURES simulator(s) failed to boot"
  if [ $BOOT_FAILURES -eq $FOUND_COUNT ]; then
    echo "ERROR: All simulators failed to boot. Cannot proceed."
    exit 1
  fi
fi

# Post-boot settle time: let the OS schedule daemon startups before we start polling
BOOTED_COUNT=$((FOUND_COUNT - BOOT_FAILURES))
SETTLE_TIME=$((BOOTED_COUNT * 2))
if [ $SETTLE_TIME -lt 10 ]; then SETTLE_TIME=10; fi
if [ $SETTLE_TIME -gt 30 ]; then SETTLE_TIME=30; fi
echo "Waiting ${SETTLE_TIME}s for $BOOTED_COUNT simulator(s) to settle before daemon checks..."
sleep $SETTLE_TIME

# Verify system daemons are responsive on each simulator (PARALLEL)
echo "Verifying system daemon readiness..."
DAEMON_STATUS_DIR=$(mktemp -d)
for UDID in $SIMULATOR_UDIDS; do
  (
    MAX_RETRIES=30
    RETRY=0
    while [ $RETRY -lt $MAX_RETRIES ]; do
      DAEMON_OUTPUT=$(run_with_timeout 10 xcrun simctl spawn "$UDID" launchctl print system 2>/dev/null || true)
      if echo "$DAEMON_OUTPUT" | grep -q "com.apple.springboard"; then
        echo "Simulator $UDID: SpringBoard daemon is running (attempt $((RETRY + 1)))"
        echo "ok" > "$DAEMON_STATUS_DIR/$UDID"
        exit 0
      fi
      RETRY=$((RETRY + 1))
      echo "Simulator $UDID: waiting for system daemons (attempt $RETRY/$MAX_RETRIES)..."
      sleep 3
    done

    # Daemon check timed out — attempt recovery: shutdown -> erase -> reboot -> recheck
    echo "WARNING: Simulator $UDID daemons not ready after $MAX_RETRIES attempts. Attempting recovery..."
    run_with_timeout 15 xcrun simctl shutdown "$UDID" 2>/dev/null || true
    sleep 2
    run_with_timeout 15 xcrun simctl erase "$UDID" 2>/dev/null || true
    sleep 2
    run_with_timeout 15 xcrun simctl boot "$UDID" 2>/dev/null || true
    sleep 5

    # Recheck after recovery
    RECOVERY_RETRIES=10
    for r in $(seq 1 $RECOVERY_RETRIES); do
      DAEMON_OUTPUT=$(run_with_timeout 10 xcrun simctl spawn "$UDID" launchctl print system 2>/dev/null || true)
      if echo "$DAEMON_OUTPUT" | grep -q "com.apple.springboard"; then
        echo "Simulator $UDID: recovered after erase+reboot (attempt $r)"
        echo "ok" > "$DAEMON_STATUS_DIR/$UDID"
        exit 0
      fi
      echo "Simulator $UDID: recovery daemon check $r/$RECOVERY_RETRIES..."
      sleep 3
    done

    echo "ERROR: Simulator $UDID failed daemon recovery"
    echo "fail" > "$DAEMON_STATUS_DIR/$UDID"
  ) &
done
wait

# Check daemon readiness results
DAEMON_FAILURES=0
DAEMON_FAILED_UDIDS=""
for UDID in $SIMULATOR_UDIDS; do
  if [ -f "$DAEMON_STATUS_DIR/$UDID" ]; then
    if [ "$(cat "$DAEMON_STATUS_DIR/$UDID")" = "fail" ]; then
      DAEMON_FAILURES=$((DAEMON_FAILURES + 1))
      DAEMON_FAILED_UDIDS="$DAEMON_FAILED_UDIDS $UDID"
    fi
  else
    echo "WARNING: No daemon status recorded for $UDID"
    DAEMON_FAILURES=$((DAEMON_FAILURES + 1))
    DAEMON_FAILED_UDIDS="$DAEMON_FAILED_UDIDS $UDID"
  fi
done
rm -rf "$DAEMON_STATUS_DIR"

if [ $DAEMON_FAILURES -gt 0 ]; then
  echo "WARNING: $DAEMON_FAILURES simulator(s) have unresponsive system daemons"

  # Exclude unhealthy simulators from pool
  echo "Excluding unhealthy simulators and rebuilding pool..."
  for FAILED_UDID in $DAEMON_FAILED_UDIDS; do
    echo "Shutting down unhealthy simulator $FAILED_UDID..."
    run_with_timeout 15 xcrun simctl shutdown "$FAILED_UDID" 2>/dev/null || true
  done

  # Rebuild SIMULATOR_UDIDS, PORT_MAPPING, DEVICES_YAML excluding failed simulators
  NEW_SIMULATOR_UDIDS=""
  NEW_PORT_MAPPING=""
  NEW_DEVICES_YAML=""
  NEW_INDEX=0
  for UDID in $SIMULATOR_UDIDS; do
    IS_FAILED=false
    for FAILED_UDID in $DAEMON_FAILED_UDIDS; do
      if [ "$UDID" = "$FAILED_UDID" ]; then
        IS_FAILED=true
        break
      fi
    done
    if [ "$IS_FAILED" = "false" ]; then
      NEW_SIMULATOR_UDIDS="$NEW_SIMULATOR_UDIDS $UDID"
      if [ -n "$NEW_PORT_MAPPING" ]; then
        NEW_PORT_MAPPING="$NEW_PORT_MAPPING,$UDID:$NEW_INDEX"
      else
        NEW_PORT_MAPPING="$UDID:$NEW_INDEX"
      fi
      NEW_DEVICES_YAML=$(printf '%s\n      - type: simulator\n        udid: "%s"' "$NEW_DEVICES_YAML" "$UDID")
      NEW_INDEX=$((NEW_INDEX + 1))
    fi
  done

  SIMULATOR_UDIDS="$NEW_SIMULATOR_UDIDS"
  PORT_MAPPING="$NEW_PORT_MAPPING"
  DEVICES_YAML="$NEW_DEVICES_YAML"

  HEALTHY_COUNT=$(echo "$SIMULATOR_UDIDS" | wc -w | tr -d ' ')
  echo "Healthy simulator pool: $HEALTHY_COUNT simulator(s)"

  if [ "$HEALTHY_COUNT" -eq 0 ]; then
    echo "ERROR: Zero healthy simulators remaining. Cannot proceed."
    exit 1
  fi
fi

# Warm up SpringBoard on each simulator to prevent "Application failed preflight checks" / "Busy" errors
# This forces SpringBoard to complete its initialization before Marathon sends test batches
echo "Warming up SpringBoard on simulators..."
WARMUP_FAILURES=0
WARMUP_MAX_ATTEMPTS=3
for UDID in $SIMULATOR_UDIDS; do
  echo "Warming up $UDID..."
  WARMUP_SUCCESS=false
  for attempt in $(seq 1 $WARMUP_MAX_ATTEMPTS); do
    if run_with_timeout 20 xcrun simctl launch "$UDID" com.apple.Preferences 2>/dev/null; then
      sleep 1
      run_with_timeout 10 xcrun simctl terminate "$UDID" com.apple.Preferences 2>/dev/null || true
      WARMUP_SUCCESS=true
      if [ "$attempt" -gt 1 ]; then
        echo "Simulator $UDID: warmup succeeded on attempt $attempt"
      fi
      break
    else
      echo "WARNING: Warmup attempt $attempt/$WARMUP_MAX_ATTEMPTS failed for $UDID"
      if [ "$attempt" -lt "$WARMUP_MAX_ATTEMPTS" ]; then
        sleep 5
      fi
    fi
  done
  if [ "$WARMUP_SUCCESS" = "false" ]; then
    echo "WARNING: Failed to warm up $UDID after $WARMUP_MAX_ATTEMPTS attempts — SpringBoard may not be fully initialized"
    WARMUP_FAILURES=$((WARMUP_FAILURES + 1))
  fi
done

if [ $WARMUP_FAILURES -gt 0 ]; then
  echo "WARNING: $WARMUP_FAILURES simulator(s) failed SpringBoard warm-up. Allowing extra settle time..."
  sleep 15
else
  # All warmups succeeded; short settle time is sufficient since
  # SpringBoard is confirmed running and the final verification below
  # will catch any remaining issues
  sleep 3
fi

# Final verification: ensure all simulators can respond to simctl commands
echo "Final system readiness verification..."
FINAL_FAILURES=0
for UDID in $SIMULATOR_UDIDS; do
  if run_with_timeout 10 xcrun simctl spawn "$UDID" uname -a >/dev/null 2>&1; then
    echo "Simulator $UDID: responsive"
  else
    echo "WARNING: Simulator $UDID is NOT responsive to spawn commands"
    FINAL_FAILURES=$((FINAL_FAILURES + 1))
  fi
done

TOTAL_POOL=$(echo "$SIMULATOR_UDIDS" | wc -w | tr -d ' ')
PASSING=$((TOTAL_POOL - FINAL_FAILURES))
if [ "$PASSING" -eq 0 ]; then
  echo "ERROR: No simulators passed final verification. Cannot proceed."
  exit 1
fi
if [ "$FINAL_FAILURES" -gt 0 ]; then
  echo "WARNING: $FINAL_FAILURES/$TOTAL_POOL simulator(s) failed final verification ($PASSING healthy)"
fi

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
