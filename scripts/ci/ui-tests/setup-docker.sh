#!/bin/bash
# Setup Docker environment using Colima
# Outputs DOCKER_HOST to $GITHUB_ENV so all subsequent steps can use it

set -e

# Set custom paths to avoid permission issues
export COLIMA_HOME="$HOME/.colima"
export TMPDIR="$HOME/.colima/tmp"
mkdir -p "$TMPDIR"

# Check and install Colima if needed
if ! command -v colima &> /dev/null; then
  echo "Colima not found, installing..."
  brew install colima
else
  echo "Colima already installed: $(colima version)"
fi

# Check and install Docker CLI if needed
if ! command -v docker &> /dev/null; then
  echo "Docker CLI not found, installing..."
  brew install docker
else
  echo "Docker CLI already installed: $(docker --version)"
fi

# Start Colima if not running
# VM image is preserved between runs for warm restarts (~10s vs 30-60s cold start)
if ! colima status &>/dev/null; then
  echo "Stopping any stale Colima instance..."
  colima stop --force 2>/dev/null || true

  # Colima only runs WireMock containers (lightweight HTTP stub servers).
  # Keep resources minimal to leave CPU/memory for simulators and xcodebuild.
  REQUESTED_CPU=2
  REQUESTED_MEMORY=2

  echo "Starting Colima with CPU=$REQUESTED_CPU, Memory=${REQUESTED_MEMORY}GB..."
  if ! colima start --cpu "$REQUESTED_CPU" --memory "$REQUESTED_MEMORY" --mount-type virtiofs 2>&1; then
    echo "❌ First start attempt failed"
    
    # Check Colima error logs
    COLIMA_LOG_DIR="$HOME/.colima/_lima/colima"
    if [ -f "$COLIMA_LOG_DIR/ha.stderr.log" ]; then
      echo "=== Colima error log (last 50 lines) ==="
      tail -50 "$COLIMA_LOG_DIR/ha.stderr.log" || true
    fi
    if [ -f "$COLIMA_LOG_DIR/serial.log" ]; then
      echo "=== Colima serial log (last 30 lines) ==="
      tail -30 "$COLIMA_LOG_DIR/serial.log" || true
    fi
    
    echo "Attempting cleanup and retry..."
    colima stop --force 2>/dev/null || true
    # Delete corrupted instance if it exists
    colima delete --force 2>/dev/null || true
    sleep 2
    
    echo "Retrying Colima start..."
    if ! colima start --cpu "$REQUESTED_CPU" --memory "$REQUESTED_MEMORY" --mount-type virtiofs 2>&1; then
      echo "❌ ERROR: Colima failed to start after retry"
      echo "Colima status:"
      colima status || true
      echo "Check logs at: $COLIMA_LOG_DIR/"
      exit 1
    fi
  fi
else
  echo "Colima already running"
  COLIMA_STATUS=$(colima status 2>/dev/null || true)
  CURRENT_CPU=$(echo "$COLIMA_STATUS" | awk '/CPU/ {print $2+0}')
  CURRENT_MEMORY=$(echo "$COLIMA_STATUS" | awk '/Memory/ {gsub(/[^0-9]/,"",$2); print $2+0}')
  echo "Current resources: CPU ${CURRENT_CPU:-?}, Memory ${CURRENT_MEMORY:-?}"
fi

# Find the Colima Docker socket dynamically
COLIMA_SOCKET="$HOME/.colima/default/docker.sock"
if [ ! -S "$COLIMA_SOCKET" ]; then
  echo "Socket not at default path, searching..."
  COLIMA_SOCKET=$(find "$HOME/.colima" -name "docker.sock" -type s 2>/dev/null | head -1)
fi

if [ -z "$COLIMA_SOCKET" ] || [ ! -S "$COLIMA_SOCKET" ]; then
  echo "ERROR: Could not find Colima Docker socket!"
  echo "Colima status:"
  colima status || true
  echo "Contents of ~/.colima:"
  find "$HOME/.colima" -name "*.sock" 2>/dev/null || echo "No sockets found"
  exit 1
fi

echo "Found Docker socket: $COLIMA_SOCKET"

# Make Docker socket accessible at the default path
# This ensures ALL scripts/subprocesses can use Docker without DOCKER_HOST
if [ ! -S /var/run/docker.sock ]; then
  echo "Creating symlink: /var/run/docker.sock -> $COLIMA_SOCKET"
  ln -sf "$COLIMA_SOCKET" /var/run/docker.sock 2>/dev/null || {
    # If /var/run needs sudo, fall back to DOCKER_HOST
    echo "Cannot create symlink (no permissions), using DOCKER_HOST instead"
    export DOCKER_HOST="unix://$COLIMA_SOCKET"
    # Write to GITHUB_ENV so subsequent workflow steps get it too
    if [ -n "$GITHUB_ENV" ]; then
      echo "DOCKER_HOST=unix://$COLIMA_SOCKET" >> "$GITHUB_ENV"
    fi
  }
fi

# Verify Docker is working
echo "Verifying Docker connection..."
docker info
echo "✅ Docker is ready"
