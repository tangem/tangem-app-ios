#!/bin/bash
# Shared cache cleanup for the self-hosted runner.
# Removes expendable Xcode/Simulator caches while preserving Build/Products for incremental builds.
# Called from: workflow pre-checkout, ensure-disk-space.sh, workflow post-run, cleanup-runner-disk.sh
#
# Usage: ./cleanup-caches.sh [--workspace /path] [--aggressive]
#   --workspace /path : also clean workspace artifacts
#   --aggressive      : additionally clean SPM caches, Homebrew cache, old DerivedData

set -e

WORKSPACE=""
AGGRESSIVE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --aggressive) AGGRESSIVE=true; shift ;;
    *) shift ;;
  esac
done

echo "🧹 Running shared cache cleanup..."

# 1. DerivedData Logs, DocumentationCache, Index (keep Build/Products for cache)
if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
  echo "  Cleaning DerivedData Logs, DocumentationCache, and Index..."
  find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 2 -type d \( -name "Logs" -o -name "DocumentationCache" -o -name "Index.noindex" \) -exec rm -rf {} + 2>/dev/null || true
fi

# 2. Action temp files (critical for self-hosted runners)
if [ -n "$GITHUB_WORKSPACE" ]; then
  ACTIONS_WORK="$(cd "$GITHUB_WORKSPACE/../.." 2>/dev/null && pwd)"
  if [ -d "$ACTIONS_WORK/_actions/_temp_" ]; then
    echo "  Cleaning Action temp files..."
    rm -rf "$ACTIONS_WORK/_actions/_temp_"* 2>/dev/null || true
  fi
fi

# NOTE: CoreSimulator/Caches is intentionally NOT cleaned here.
# Removing it corrupts reused simulators (device data becomes unlocatable).

# 3. Workspace artifacts (if --workspace provided)
if [ -n "$WORKSPACE" ] && [ -d "$WORKSPACE" ]; then
  echo "  Cleaning workspace artifacts in $WORKSPACE..."
  rm -rf "$WORKSPACE/marathon-output" 2>/dev/null || true
  rm -rf "$WORKSPACE/wiremock-logs" 2>/dev/null || true
  rm -rf "$WORKSPACE/allure-results" 2>/dev/null || true
  rm -rf "$WORKSPACE/uitest-artifacts" 2>/dev/null || true
fi

# 4. Aggressive cleanup (when called with --aggressive)
if [ "$AGGRESSIVE" = true ]; then
  echo "  Running aggressive cleanup..."

  # Old DerivedData folders (keep only the newest)
  DD_ROOT="$HOME/Library/Developer/Xcode/DerivedData"
  if [ -d "$DD_ROOT" ]; then
    NEWEST=$(ls -dt "$DD_ROOT"/*/ 2>/dev/null | head -1)
    if [ -n "$NEWEST" ]; then
      NEWEST_NAME=$(basename "$NEWEST")
      for dir in "$DD_ROOT"/*/; do
        DIR_NAME=$(basename "$dir")
        if [ "$DIR_NAME" != "$NEWEST_NAME" ] && [ "$DIR_NAME" != "ModuleCache.noindex" ]; then
          echo "    Removing old DerivedData: $DIR_NAME"
          rm -rf "$dir"
        fi
      done
    fi
  fi

  # DerivedData SourcePackages (re-resolved as needed)
  find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 2 -type d -name "SourcePackages" -exec rm -rf {} + 2>/dev/null || true

  # SPM global caches
  rm -rf "$HOME/Library/Caches/org.swift.swiftpm" 2>/dev/null || true

  # Homebrew cache
  if command -v brew &>/dev/null; then
    brew cleanup --prune=all -s 2>/dev/null || true
  fi

  # CocoaPods download cache
  rm -rf "$HOME/Library/Caches/CocoaPods" 2>/dev/null || true

  # Xcode archives
  rm -rf "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null || true

  # Unavailable simulator devices
  xcrun simctl delete unavailable 2>/dev/null || true
fi

echo "  Cleanup done."
