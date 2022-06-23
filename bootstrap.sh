#!/bin/sh
# set -euo pipefail

# Install "Command line tools" xcode-select --install
# Install Homebrew -> https://brew.sh

echo "==== Installing dependencies... 🔜 ===="
 brew install mint
 mint install nicklockwood/SwiftFormat
echo "==== Dependencies succesfully installed ✅ ===="

echo "==== Running swiftformat ===="
 mint run swiftformat .
echo "==== Bootstrap competed 🎉 ===="