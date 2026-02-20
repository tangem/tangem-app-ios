#!/bin/bash

set -euo pipefail

# --- Checking whether required tools are installed ---

echo "🛠️ Checking whether required tools are installed"

# Check if Xcode is installed
if xcode-select -p >/dev/null 2>&1; then
    echo "Xcode is installed: $(xcode-select -p)"
else
    echo "Xcode is not installed"
    echo "Install it from the Mac App Store or run: xcode-select --install"
    exit -1
fi

# --- Assembling assets ---

echo "🧩 Joining all parts into a single archive"
ARCHIVE_NAME="SPM_dependencies"
ARCHIVE_FILE="${ARCHIVE_NAME}.tar.gz"
cat $ARCHIVE_NAME* > $ARCHIVE_FILE

# --- Unarchiving the resulting archive ---

echo "📤 Unpacking the archive with app dependencies"
tar -xzf $ARCHIVE_FILE

# --- Cleanup temporary files ---

echo "🧹 Cleaning up temporary files after unarchiving"
if rm -rf $ARCHIVE_NAME*; then
    echo "✅ Cleanup complete"
else
    echo "⚠️ Warning: Failed to clean up some temporary files"
fi

# --- Open the project ---

echo "🏁 Finished"
xed "TangemApp.xcodeproj"
