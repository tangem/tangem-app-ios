#!/bin/bash
# Setup Docker environment using Colima
# No parameters required

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
if ! colima status &> /dev/null; then
  # Clean up any stale instance before starting
  echo "Stopping any stale Colima instance..."
  colima stop --force 2>/dev/null || true
  colima delete --force 2>/dev/null || true

  echo "Starting Colima..."
  if ! colima start --cpu 4 --memory 8; then
    echo "First start attempt failed, cleaning up and retrying..."
    colima stop --force 2>/dev/null || true
    colima delete --force 2>/dev/null || true
    colima start --cpu 4 --memory 8
  fi
else
  echo "Colima already running"
fi

# Verify Docker is working
docker info
