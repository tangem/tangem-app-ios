#!/bin/bash

set -eo pipefail

# Install "Command line tools" xcode-select --install
# Install Homebrew -> https://brew.sh

usage() {
    echo "Usage: $0 [additional options]"
    echo
    echo "  Options:"
    echo
    echo "    --skip-ruby             -  Skip Ruby install"
    echo "    --skip-mint             -  Skip installing dependencies via Mint"
    echo "    --force-lint            -  Install SwiftFormat even on CI"
    echo "    --update-submodule      -  Git submodule update with --remote option"
    echo "    --install-marathon      -  Install Marathon CLI (for parallel UI tests)"
    exit 1;
}

OPT_RUBY=true
OPT_MINT=true
OPT_FORCE_LINT=false
OPT_SUBMODULE=false
OPT_INSTALL_MARATHON=false

while test $# -gt 0
do
    case "$1" in
        --skip-ruby)
            OPT_RUBY=false
            ;;
        --skip-mint)
            OPT_MINT=false
            ;;
        --update-submodule)
            OPT_SUBMODULE=true
            ;;
        --force-lint)
            OPT_FORCE_LINT=true
            ;;
        --install-marathon)
            OPT_INSTALL_MARATHON=true
            ;;
        *)
        usage 1>&2
        ;;
    esac
    shift
done

echo "🔜 Check & Install dependencies..."

if which -a brew > /dev/null; then
    echo "🟢 Homebrew installed. Skipping install"
else
    echo "🔴 Homebrew not installed. Start install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ "${CI}" = true && "${OPT_FORCE_LINT}" = false ]] ; then
    MINTFILE="./Utilities/Mintfile@ci"
    BREWFILE="./Utilities/Brewfile@ci"
else
    MINTFILE="./Utilities/Mintfile@local"
    BREWFILE="./Utilities/Brewfile@local"
fi

echo "🔄 Installing required Homebrew dependencies"
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file=${BREWFILE}
echo "✅ Required Homebrew dependencies succesfully installed"

if [[ "$OPT_RUBY" = true ]] ; then
    echo "🛠️ Installing Ruby version from '.ruby-version' file..."
    eval "$(rbenv init - bash)"
    RUBY_VERSION=$(cat .ruby-version)
    rbenv install "$RUBY_VERSION" --skip-existing
    rbenv local "$RUBY_VERSION"
    rbenv rehash
    echo "✅ Ruby version ${RUBY_VERSION} from '.ruby-version' file succesfully installed"
fi

echo "🔄 Installing required Ruby gems"
gem install bundler
bundle install
echo "✅ Required Ruby gems succesfully installed"

# Mint is still used for some dependencies because it's extremely difficult 
# to install a particular dependency version using Homebrew
# See https://github.com/nicklockwood/SwiftFormat/issues/695 for details
if [[ "$OPT_MINT" = true ]] ; then
    echo "🔄 Mint bootstrap dependencies"
    mint bootstrap --mintfile ${MINTFILE}
    echo "✅ Dependencies succesfully installed"
else
    echo "ℹ️ Skipping Mint dependencies installation"
fi

if [[ "$CI" = true || "$OPT_MINT" = false ]] ; then
    echo "ℹ️ Skipping SwiftFormat"
else
    echo "🚀 Running SwiftFormat"
    mint run swiftformat@0.55.5 . --config .swiftformat
fi

if [[ "$OPT_MINT" = false ]] ; then
    echo "ℹ️ Skipping SwiftGen"
else
    echo "🚀 Running SwiftGen"
    mint run swiftgen@6.6.3 config run --config swiftgen.yml 
fi

if [[ "$OPT_SUBMODULE" = true ]] ; then
    echo "🚀 Running submodule remote update"
    git submodule update --remote
fi

# Install Marathon CLI for parallel UI test execution (only when explicitly requested)
if [[ "$OPT_INSTALL_MARATHON" = true ]] ; then
    echo "🔄 Installing Marathon CLI for parallel UI tests"
    if which marathon > /dev/null; then
        echo "🟢 Marathon already installed"
        marathon version
    else
        echo "🔴 Marathon not installed. Installing via Homebrew..."
        HOMEBREW_NO_AUTO_UPDATE=1 brew tap malinskiy/tap
        HOMEBREW_NO_AUTO_UPDATE=1 brew install malinskiy/tap/marathon
        echo "✅ Marathon CLI successfully installed"
        marathon version
    fi
fi

echo "Bootstrap competed 🎉"
