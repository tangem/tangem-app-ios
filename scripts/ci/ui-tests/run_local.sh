#!/bin/bash
# Local runner for parallel UI tests using Marathon
# Usage: ./scripts/run_local.sh [simulator_count] [test_class] [wiremock_path] [--skip-build]

set -e

# Cleanup function — runs on exit, error, or interrupt
cleanup() {
  echo "🧹 Cleaning up..."
  # Dump WireMock request journals before stopping containers
  if [ -n "$SIMULATOR_COUNT" ]; then
    WIREMOCK_LOGS_DIR="$(pwd)/marathon-output/wiremock-logs"
    mkdir -p "$WIREMOCK_LOGS_DIR"
    for i in $(seq 1 $SIMULATOR_COUNT); do
      WIREMOCK_PORT=$((8080 + i))
      echo "📋 Saving WireMock-$i request journal (port $WIREMOCK_PORT)..."
      curl -s "http://localhost:$WIREMOCK_PORT/__admin/requests" \
        > "$WIREMOCK_LOGS_DIR/wiremock-${i}-requests.json" 2>/dev/null || true
    done
    echo "📋 WireMock logs saved to $WIREMOCK_LOGS_DIR"
    # Capture diagnostic log files from simulator tmp directories
    SIM_LOGS_DIR="$(pwd)/marathon-output/simulator-logs"
    mkdir -p "$SIM_LOGS_DIR"
    for udid in $(xcrun simctl list devices booted -j | python3 -c "import sys,json;[print(d['udid']) for r in json.load(sys.stdin)['devices'].values() for d in r if d['state']=='Booted']" 2>/dev/null); do
      echo "📋 Collecting diagnostic logs from simulator $udid..."
      SIM_DATA="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data"
      # Find the diagnostic log file written by the app
      find "$SIM_DATA" -name "total_balance_diag.log" -exec cp {} "$SIM_LOGS_DIR/${udid}-total-balance.log" \; 2>/dev/null || true
    done
    echo "📋 Simulator diagnostic logs saved to $SIM_LOGS_DIR"
    ./scripts/ci/ui-tests/wiremock-stop.sh 2>/dev/null || true
  fi
  [ -f "$(pwd)/.github_output_mock" ] && rm -f "$(pwd)/.github_output_mock"
}
trap cleanup EXIT

# Default values
SIMULATOR_COUNT="${1:-2}"
TEST_CLASS="$2"
WIREMOCK_PATH="${3:-$(pwd)/tangem-api-mocks}"
SKIP_BUILD="${4:-}"

# Export early so all scripts can access
export SIMULATOR_COUNT

echo "🚀 Starting Local Parallel UI Tests"
echo "Simulators: $SIMULATOR_COUNT"
if [ -n "$TEST_CLASS" ]; then
    echo "Test Class: $TEST_CLASS"
fi
echo "WireMock Path: $WIREMOCK_PATH"
if [ "$SKIP_BUILD" = "--skip-build" ]; then
    echo "Build: SKIPPED"
fi

# Validate WireMock path
if [ ! -d "$WIREMOCK_PATH" ]; then
    echo "❌ WireMock path not found: $WIREMOCK_PATH"
    echo "   Please provide valid path: ./scripts/local_parallel_tests.sh 2 '' /path/to/tangem-api-mocks"
    exit 1
fi

# 1. Check Dependencies
echo "🔍 Checking dependencies..."
if ! command -v marathon &> /dev/null; then
    echo "❌ Marathon not found. Please run: ./bootstrap.sh --install-marathon"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi

# DerivedData path used by Fastlane and Marathon
DERIVED_DATA_PATH="$(pwd)/uitest-artifacts/test-results"
export DERIVED_DATA_PATH

# 2. Build App for Testing
if [ "$SKIP_BUILD" = "--skip-build" ]; then
    echo "⏭️ Skipping build (--skip-build flag provided)"
    if [ ! -d "$DERIVED_DATA_PATH" ]; then
        echo "❌ No previous build found at: $DERIVED_DATA_PATH"
        echo "   Run without --skip-build first to create a build."
        exit 1
    fi
else
    echo "🏗️ Building app for testing..."
    # Use fastlane to build (same as CI)
    eval "$(rbenv init - bash)"
    bundle exec fastlane build_for_marathon
    echo "✅ App built at: $DERIVED_DATA_PATH"
fi

# 3. Setup WireMock
echo "🐳 Setting up WireMock..."
./scripts/ci/ui-tests/setup-docker.sh
docker build -t tangem-wiremock -f "$WIREMOCK_PATH/Dockerfile" "$WIREMOCK_PATH/"
./scripts/ci/ui-tests/wiremock-start.sh

# 4. Setup Simulators
echo "📱 Setting up Simulators..."
GITHUB_OUTPUT="$(pwd)/.github_output_mock"
touch "$GITHUB_OUTPUT"
export GITHUB_OUTPUT

./scripts/ci/ui-tests/manage-simulators.sh

# Parse GITHUB_OUTPUT using Python to handle HEREDOCs safely
# The format produced by manage-simulators.sh is standard GitHub Actions output
cat << 'EOF' > parse_github_env.py
import sys
import re

env_file = sys.argv[1]
with open(env_file) as f:
    lines = f.readlines()

# Valid shell variable name pattern
var_pattern = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

i = 0
while i < len(lines):
    line = lines[i].strip()
    if not line:
        i += 1
        continue
        
    if '<<EOF' in line:
        key = line.split('<<')[0]
        if var_pattern.match(key):
            value = []
            i += 1
            while i < len(lines) and 'EOF' not in lines[i]:
                value.append(lines[i])
                i += 1
            # Escape single quotes for shell safety
            val_str = "".join(value).replace("'", "'\\''")
            # Uppercase key to match expected env var names
            print(f"export {key.upper()}='{val_str}'")
        else:
            i += 1
    elif '=' in line:
        key = line.split('=')[0]
        val = line.split('=', 1)[1]
        if var_pattern.match(key):
            # Uppercase key to match expected env var names
            print(f"export {key.upper()}='{val}'")
    i += 1
EOF

# Source the exported variables
eval "$(python3 parse_github_env.py "$GITHUB_OUTPUT")"

# Cleanup python script
rm parse_github_env.py

# Verify variables are set
if [ -z "$PORT_MAPPING" ] || [ -z "$DEVICES_YAML" ]; then
    echo "❌ Failed to parse simulator configuration."
    exit 1
fi

export PORT_MAPPING
export DEVICES_YAML

echo "✅ Simulators ready. Port Mapping: $PORT_MAPPING"

# 5. Generate Marathon Config
echo "📝 Generating Marathon config..."
export TEST_CLASS
./scripts/ci/ui-tests/generate-marathon-config.sh

# 6. Run Marathon
echo "🏃 Running Marathon..."
marathon run --marathonfile Marathonfile.generated

echo "✅ Tests completed!"
echo "📊 Report available at: marathon-output/html/index.html"

# Cleanup is handled automatically by the EXIT trap
