#!/bin/bash
# Neutralize leftovers from a previous crashed run (stale test processes, booted
# simulators, WireMock containers). Safe and idempotent on a clean machine.
# Also used as the final cleanup step of the workflow so kill patterns live in one place.
# No required env.

set -e

DIAG_DIR="$HOME/ui-test-diagnostics"

echo "=== Preflight diagnostics ==="
memory_pressure -Q 2>/dev/null || vm_stat | head -6

echo "--- Booted simulators ---"
xcrun simctl list devices booted || true

echo "--- Stale test processes ---"
pgrep -fl "xcodebuild|marathon" || echo "none"

# If the host died mid-run, the previous run's memory log survives here
LAST_LOG=$(ls -t "$DIAG_DIR"/memory-monitor-*.log 2>/dev/null | head -1 || true)
if [ -n "$LAST_LOG" ]; then
  echo "--- Tail of previous memory monitor log: $LAST_LOG ---"
  tail -40 "$LAST_LOG" || true
fi

echo "=== Stopping stale test processes ==="
# Patterns are scoped so they can never match the runner agent or this script itself
pkill -f "xcodebuild.*-destination.*simulator" 2>/dev/null && echo "Sent SIGTERM to xcodebuild" || echo "No xcodebuild processes"
pkill -f "marathon.*Marathonfile" 2>/dev/null && echo "Sent SIGTERM to marathon" || echo "No marathon processes"
pkill -f "memory-monitor.sh" 2>/dev/null && echo "Killed stale memory monitor" || true
# Stale pid file from a crashed run could point at a recycled PID
rm -f "$DIAG_DIR/memory-monitor.pid"
sleep 5
pkill -9 -f "xcodebuild.*-destination.*simulator" 2>/dev/null && echo "Sent SIGKILL to xcodebuild" || echo "No remaining xcodebuild processes"
pkill -9 -f "marathon.*Marathonfile" 2>/dev/null && echo "Sent SIGKILL to marathon" || echo "No remaining marathon processes"

echo "=== Shutting down all simulators ==="
xcrun simctl shutdown all 2>/dev/null || true
xcrun simctl delete unavailable 2>/dev/null || true
# Sim-hosted testmanagerd dies with its simulator; kill stragglers only,
# scoped to simulator runtime paths so the host-side testmanagerd is untouched
pkill -9 -f "CoreSimulator.*testmanagerd" 2>/dev/null || true

echo "=== Cleaning stale Docker state ==="
if command -v colima &> /dev/null && colima status &> /dev/null; then
  if docker info &> /dev/null; then
    # Remove ALL wiremock containers regardless of count (previous run may have used more)
    docker ps -aq --filter "name=wiremock-" | xargs docker rm -f 2>/dev/null || true
    echo "Colima is healthy, leaving it running for reuse"
  else
    echo "Colima reports running but Docker daemon is unresponsive, resetting..."
    colima stop --force 2>/dev/null || true
    colima delete --force 2>/dev/null || true
  fi
else
  echo "Colima not running, nothing to clean"
fi

echo "✅ Preflight cleanup complete"
