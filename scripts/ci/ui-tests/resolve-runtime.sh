#!/bin/bash
# Resolve the simulator device model and iOS runtime version.
# Reads from .ios-sim-runtime but falls back to the latest available iOS runtime
# if the configured version is not installed (e.g., Xcode was updated).
#
# Usage: source this script, then use $RESOLVED_DEVICE and $RESOLVED_RUNTIME.
# Also exports IOS_SIM_RUNTIME for Fastlane compatibility.

_RESOLVE_REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

RESOLVED_DEVICE=$(sed -n '1p' "$_RESOLVE_REPO_ROOT/.ios-sim-runtime" | xargs)
_CONFIGURED_RUNTIME=$(sed -n '2p' "$_RESOLVE_REPO_ROOT/.ios-sim-runtime" | tr -d '[:space:]')

# Check if the configured runtime is actually available on this machine
if xcrun simctl list runtimes available 2>/dev/null | grep -q "iOS ${_CONFIGURED_RUNTIME} "; then
  RESOLVED_RUNTIME="$_CONFIGURED_RUNTIME"
else
  echo "WARNING: iOS $_CONFIGURED_RUNTIME runtime is not available on this machine"
  echo "  Available runtimes:"
  xcrun simctl list runtimes available 2>/dev/null | grep "iOS" || echo "  (none)"

  # Fall back to the latest available iOS runtime
  RESOLVED_RUNTIME=$(xcrun simctl list runtimes available 2>/dev/null | grep "iOS" | tail -1 | sed -E 's/.*iOS ([0-9]+\.[0-9]+).*/\1/')

  if [ -z "$RESOLVED_RUNTIME" ]; then
    echo "ERROR: No iOS runtimes available! Check Xcode installation."
    # Don't exit — let the caller decide how to handle this
  else
    echo "  Falling back to: iOS $RESOLVED_RUNTIME"
  fi
fi

# Export for Fastlane and sub-processes
export IOS_SIM_RUNTIME="${RESOLVED_RUNTIME}"
export IOS_SIM_DEVICE="${RESOLVED_DEVICE}"

unset _RESOLVE_REPO_ROOT _CONFIGURED_RUNTIME
