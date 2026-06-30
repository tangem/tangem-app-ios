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

if [[ "$OPT_MINT" = false ]] ; then
    echo "ℹ️ Skipping DS-Core generator"
else
    # DS-Core sources (tokens + icons) are vendored into the repo by the
    # `update-dscore` GitHub Action — no SPM resolve, no submodule, no clone.
    # The pinned upstream commit is stored in .dscore-source-commit for humans.
    echo "🎨 Generating DS-Core sources (tokens + icons)"
    DSCORE_GEN_DIR="Utilities/ds-core-generator"
    DSCORE_REQUIRED_NODE=$(cat .nvmrc)
    DSCORE_REQUIRED_NODE_MAJOR=$(echo "${DSCORE_REQUIRED_NODE}" | sed 's/^v//' | cut -d. -f1)

    # Switch to the required Node via nvm if available — otherwise just validate.
    # Look in the standard $NVM_DIR location first, then fall back to Homebrew's
    # nvm install path (brew nvm requires the user to manually create ~/.nvm and
    # export NVM_DIR; this fallback removes that first-run friction).
    NVM_SH=""
    if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]] ; then
        NVM_SH="${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    elif command -v brew >/dev/null 2>&1 && [[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]] ; then
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        mkdir -p "${NVM_DIR}"
        NVM_SH="$(brew --prefix)/opt/nvm/nvm.sh"
    fi
    if [[ -n "${NVM_SH}" ]] ; then
        # `--no-use` loads nvm functions without trying to activate a default version
        # (auto-use returns non-zero on an empty NVM_DIR and would trip `set -e`).
        set +e
        # shellcheck disable=SC1091
        . "${NVM_SH}" --no-use
        set -e
        nvm install
        nvm use "${DSCORE_REQUIRED_NODE}"
    fi

    if ! command -v node >/dev/null 2>&1 ; then
        echo "❌ Node not found. Install Node ${DSCORE_REQUIRED_NODE_MAJOR}+ (see .nvmrc) — e.g. 'brew install node' or 'nvm install'."
        exit 1
    fi
    DSCORE_CURRENT_NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
    if [[ "${DSCORE_CURRENT_NODE_MAJOR}" -lt "${DSCORE_REQUIRED_NODE_MAJOR}" ]] ; then
        echo "❌ Node $(node -v) is too old for the DS-Core generator. style-dictionary requires Node ${DSCORE_REQUIRED_NODE_MAJOR}+ (see .nvmrc)."
        exit 1
    fi

    # --ignore-scripts blocks postinstall execution in transitive deps (the standard
    # npm supply-chain attack vector). Both direct deps (style-dictionary,
    # @tokens-studio/sd-transforms) are pure-JS and don't need lifecycle scripts.
    # --cache pins the package cache to a project-local directory so we never
    # touch ~/.npm — global cache rot (root-owned files from a past `sudo npm`)
    # can't break our install.
    ( cd "${DSCORE_GEN_DIR}" \
        && npm ci --ignore-scripts --no-audit --no-fund --cache=.npm-cache \
        && npm run build )
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

echo "Bootstrap completed 🎉"
