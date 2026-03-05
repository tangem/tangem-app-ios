#!/bin/bash
set -e

# Setup orchestration: build the app first, then boot simulators + start WireMock.
#
# Why NOT parallel?  On an 8-core / 16GB runner, booting 8 simulators alongside
# the Xcode build causes extreme resource contention (load avg >600, 500 MB free
# RAM).  The resulting thrashing makes the "parallel" setup slower than sequential.
#
# Current order:
#   1. WireMock (background) — lightweight, mostly Docker I/O
#   2. Xcode build (foreground) — CPU + memory intensive
#   3. Simulators (foreground, after build) — CPU + memory intensive
#
# WireMock runs in the background during the build because Docker/Colima startup
# is I/O-bound and doesn't compete meaningfully with the compiler.

# Capture outputs from background processes
SIM_OUTPUT_FILE="simulators_output.txt"
WIREMOCK_LOG_FILE="wiremock_setup.log"
DOCKER_HOST_FILE="docker_host.env"

# PIDs for background processes (used by trap)
WIREMOCK_PID=""
RESOURCE_MONITOR_PID=""

# Cleanup trap — kills background process trees on any exit (error or signal)
cleanup_background() {
  local exit_code=$?
  for PID in $WIREMOCK_PID $RESOURCE_MONITOR_PID; do
    if [ -n "$PID" ]; then
      pkill -P "$PID" 2>/dev/null || true
      kill "$PID" 2>/dev/null || true
    fi
  done
  rm -f "$DOCKER_HOST_FILE" resource_monitor.log
  exit $exit_code
}
trap cleanup_background EXIT

echo "=== Starting Setup ==="

# Resource monitoring (lightweight: vm_stat only, no top which burns CPU)
echo "📊 Starting resource monitoring..."
(
  while true; do
    MEM_FREE=$(vm_stat | awk '/Pages free/ {free=$3} /Pages inactive/ {inactive=$3} END {gsub(/\./,"",free); gsub(/\./,"",inactive); print int((free+inactive)*4096/1024/1024)}')
    LOAD_AVG=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}')
    echo "$(date '+%H:%M:%S') - Load avg: ${LOAD_AVG:-?} | Free+inactive mem: ${MEM_FREE:-?}MB"
    sleep 30
  done
) > resource_monitor.log 2>&1 &
RESOURCE_MONITOR_PID=$!

# 1. Start WireMock (Background — I/O-bound, doesn't compete with the build)
echo "Starting WireMock Setup (Background)..."
(
    # Run setup-docker.sh (starts Colima, creates /var/run/docker.sock symlink)
    ./scripts/ci/ui-tests/setup-docker.sh

    # Ensure DOCKER_HOST is set if symlink creation failed
    if ! docker info &>/dev/null; then
      echo "Docker not accessible at default socket, finding Colima socket..."
      COLIMA_SOCKET="$HOME/.colima/default/docker.sock"
      if [ ! -S "$COLIMA_SOCKET" ]; then
        COLIMA_SOCKET=$(find "$HOME/.colima" -name "docker.sock" -type s 2>/dev/null | head -1)
      fi
      if [ -n "$COLIMA_SOCKET" ] && [ -S "$COLIMA_SOCKET" ]; then
        export DOCKER_HOST="unix://$COLIMA_SOCKET"
        echo "Set DOCKER_HOST=$DOCKER_HOST"
        # Persist for parent script and subsequent workflow steps
        echo "DOCKER_HOST=$DOCKER_HOST" > "$PWD/$DOCKER_HOST_FILE"
        if [ -n "$GITHUB_ENV" ]; then
          echo "DOCKER_HOST=$DOCKER_HOST" >> "$GITHUB_ENV"
        fi
        if ! docker info &>/dev/null; then
          echo "❌ ERROR: Docker still not accessible after setting DOCKER_HOST"
          exit 1
        fi
      else
        echo "❌ ERROR: Could not find Colima Docker socket"
        exit 1
      fi
    fi

    # Always rebuild — cleanup-docker.sh deletes the image after each run
    echo "🔨 Building WireMock image..."
    docker build -t tangem-wiremock -f tangem-api-mocks/Dockerfile tangem-api-mocks/

    # Start WireMock
    ./scripts/ci/ui-tests/wiremock-start.sh
) > "$WIREMOCK_LOG_FILE" 2>&1 & WIREMOCK_PID=$!

# 2. Build App (Foreground — CPU + memory intensive, needs full resources)
echo "Starting App Build (Foreground)..."
eval "$(rbenv init - bash)"
bundle exec fastlane build_for_marathon
echo "✅ App Build Completed"

# 3. Boot Simulators (Foreground, AFTER build — avoids resource contention)
echo "Starting Simulator Setup (after build)..."
ORIGINAL_GITHUB_OUTPUT="${GITHUB_OUTPUT:-}"
export GITHUB_OUTPUT="$PWD/$SIM_OUTPUT_FILE"
set +e
./scripts/ci/ui-tests/manage-simulators.sh
SIM_EXIT=$?
set -e
export GITHUB_OUTPUT="$ORIGINAL_GITHUB_OUTPUT"

# 4. Wait for WireMock (should be done by now since it started during the build)
echo "Waiting for WireMock..."
set +e
wait $WIREMOCK_PID
WIREMOCK_EXIT=$?
WIREMOCK_PID=""
set -e

# Import DOCKER_HOST from subshell if it was set
if [ -f "$DOCKER_HOST_FILE" ]; then
  echo "Importing DOCKER_HOST from WireMock subshell..."
  source "$DOCKER_HOST_FILE"
  export DOCKER_HOST
  echo "DOCKER_HOST=$DOCKER_HOST"
fi

# Aggregate simulator outputs into the real GITHUB_OUTPUT
if [ -f "$SIM_OUTPUT_FILE" ]; then
    echo "Exporting simulator outputs..."
    if [ -n "$GITHUB_OUTPUT" ]; then
      cat "$SIM_OUTPUT_FILE" >> "$GITHUB_OUTPUT"
    fi
    cat "$SIM_OUTPUT_FILE"
fi

# Stop resource monitor (trap will also handle this, but clean up early for the summary)
if [ -n "$RESOURCE_MONITOR_PID" ]; then
  kill $RESOURCE_MONITOR_PID 2>/dev/null || true
  RESOURCE_MONITOR_PID=""
  echo "📊 Resource usage summary:"
  tail -5 resource_monitor.log 2>/dev/null || echo "No resource data available"
fi

# Check for errors
SETUP_FAILED=false

if [ $WIREMOCK_EXIT -ne 0 ]; then
    echo "❌ WireMock Setup Failed! Log:"
    cat "$WIREMOCK_LOG_FILE" 2>/dev/null || echo "No WireMock log available"
    SETUP_FAILED=true
else
    echo "✅ WireMock Setup Completed"
fi

if [ $SIM_EXIT -ne 0 ]; then
    echo "❌ Simulator Setup Failed!"
    SETUP_FAILED=true
fi

# Cleanup temp files
rm -f "$SIM_OUTPUT_FILE" "$WIREMOCK_LOG_FILE" "$DOCKER_HOST_FILE" resource_monitor.log

if [ "$SETUP_FAILED" = true ]; then
    echo "❌ Setup failed, see errors above"
    exit 1
fi

echo "=== Setup All Done ==="
