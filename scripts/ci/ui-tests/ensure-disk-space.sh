#!/bin/bash
# Free disk space before Marathon to avoid "No space left on device" when copying result bundles.
# Uses progressive cleanup — tries lightweight cleanup first, then increasingly aggressive
# stages until enough space is available or all options are exhausted.
#
# Usage: ./ensure-disk-space.sh [min_free_gb]
# Default min_free_gb: 10

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIN_FREE_GB="${1:-10}"
echo "🔍 Disk space check (target: ${MIN_FREE_GB}GB free)..."

# Parse available space in GB (portable: use 1K blocks then convert)
get_available_gb() {
  local avail_kb
  avail_kb=$(df -k . | tail -1 | awk '{print $4}')
  echo $((avail_kb / 1024 / 1024))
}

check_space() {
  AVAILABLE=$(get_available_gb)
  if [ "$AVAILABLE" -ge "$MIN_FREE_GB" ]; then
    echo "✅ Sufficient disk space (${AVAILABLE}GB free)"
    df -h / | tail -1
    exit 0
  fi
}

AVAILABLE=$(get_available_gb)
echo "Current available: ${AVAILABLE}GB"

# --- Stage 1: Remove previous marathon-output ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ] && [ -d "marathon-output" ]; then
  echo "🧹 Stage 1: Removing previous marathon-output..."
  rm -rf marathon-output
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 2: Basic cache cleanup (DerivedData Logs, action temp files) ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 2: Running basic cache cleanup..."
  "$SCRIPT_DIR/cleanup-caches.sh"
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 3: Clean DerivedData SourcePackages (re-resolved as needed, not cached) ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 3: Cleaning DerivedData SourcePackages..."
  find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 2 -type d -name "SourcePackages" -exec rm -rf {} + 2>/dev/null || true
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 4: Clean old DerivedData folders (keep only the most recent one) ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 4: Removing old DerivedData folders (keeping newest)..."
  DD_ROOT="$HOME/Library/Developer/Xcode/DerivedData"
  if [ -d "$DD_ROOT" ]; then
    NEWEST=$(ls -dt "$DD_ROOT"/*/ 2>/dev/null | head -1)
    if [ -n "$NEWEST" ]; then
      NEWEST_NAME=$(basename "$NEWEST")
      echo "  Keeping: $NEWEST_NAME"
      for dir in "$DD_ROOT"/*/; do
        if [ "$(basename "$dir")" != "$NEWEST_NAME" ] && [ "$(basename "$dir")" != "ModuleCache.noindex" ]; then
          echo "  Removing: $(basename "$dir")"
          rm -rf "$dir"
        fi
      done
    fi
  fi
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 5: Clean SPM global caches ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 5: Cleaning SPM global caches..."
  rm -rf "$HOME/Library/Caches/org.swift.swiftpm" 2>/dev/null || true
  rm -rf "$HOME/Library/org.swift.swiftpm" 2>/dev/null || true
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 6: Clean Homebrew cache ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 6: Cleaning Homebrew cache..."
  if command -v brew &>/dev/null; then
    brew cleanup --prune=all -s 2>/dev/null || true
    rm -rf "$(brew --cache)" 2>/dev/null || true
  fi
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 7: Clean CocoaPods download cache ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 7: Cleaning CocoaPods download cache..."
  rm -rf "$HOME/Library/Caches/CocoaPods" 2>/dev/null || true
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 8: Docker system prune (dangling images, build cache) ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 8: Pruning Docker resources..."
  if command -v docker &>/dev/null && docker info &>/dev/null; then
    docker system prune -f 2>/dev/null || true
    docker builder prune -f 2>/dev/null || true
  fi
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 9: Clean Xcode archives ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 9: Cleaning Xcode archives..."
  rm -rf "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null || true
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Stage 10: Clean old simulator device data (unavailable devices) ---
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "🧹 Stage 10: Removing unavailable simulator devices..."
  xcrun simctl delete unavailable 2>/dev/null || true
  AVAILABLE=$(get_available_gb)
  echo "  → ${AVAILABLE}GB free"
  check_space
fi

# --- Final check ---
AVAILABLE=$(get_available_gb)
if [ "$AVAILABLE" -lt "$MIN_FREE_GB" ]; then
  echo "❌ Still only ${AVAILABLE}GB free after all cleanup stages (need ${MIN_FREE_GB}GB)."
  echo ""
  echo "📊 Disk usage breakdown:"
  df -h /
  echo ""
  echo "Top space consumers in home directory:"
  du -sh "$HOME/Library/Developer" "$HOME/Library/Caches" "$HOME/.colima" "$HOME/actions-runner" 2>/dev/null | sort -rh || true
  echo ""
  echo "DerivedData breakdown:"
  du -sh "$HOME/Library/Developer/Xcode/DerivedData"/*/ 2>/dev/null | sort -rh | head -5 || true
  echo ""
  echo "CoreSimulator breakdown:"
  du -sh "$HOME/Library/Developer/CoreSimulator"/*/ 2>/dev/null | sort -rh | head -5 || true
  exit 1
fi

echo "✅ Sufficient disk space (${AVAILABLE}GB free)"
df -h / | tail -1
