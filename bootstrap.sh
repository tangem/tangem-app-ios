#!/bin/sh
# set -euo pipefail

# Install "Command line tools" xcode-select --install
# Install Homebrew -> https://brew.sh

echo "==== Installing dependencies... 🔜 ===="
if which -a brew > /dev/null
then
    brew install mint
else
    echo "⚠️ Homebrew wasn't installed. Try to install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
mint install nicklockwood/SwiftFormat
echo "==== Dependencies succesfully installed ✅ ===="

echo "==== Running swiftformat ===="
 mint run swiftformat .
echo "==== Bootstrap competed 🎉 ===="