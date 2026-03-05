#!/bin/bash
# Generate Marathon device configuration and Marathonfile
# Required env: DERIVED_DATA_PATH, PORT_MAPPING, DEVICES_YAML, SIMULATOR_COUNT
# Optional env: TEST_CLASS (for filtering specific test classes)

set -e

if [ -z "$DERIVED_DATA_PATH" ]; then
  echo "ERROR: DERIVED_DATA_PATH environment variable is required"
  exit 1
fi

if [ -z "$PORT_MAPPING" ]; then
  echo "ERROR: PORT_MAPPING environment variable is required"
  exit 1
fi

if [ -z "$DEVICES_YAML" ]; then
  echo "ERROR: DEVICES_YAML environment variable is required"
  exit 1
fi

# Batch size is calculated by calculate-simulator-count.sh based on the actual
# test count.  Falls back to 1 (maximum scheduling flexibility) when not set.
BATCH_SIZE="${MARATHON_BATCH_SIZE:-1}"
echo "Using batch size: $BATCH_SIZE (simulators: ${SIMULATOR_COUNT:-?})"

# Find build directory dynamically (scheme may use different configuration)
echo "=== Looking for build products ==="
ls -la "$DERIVED_DATA_PATH/Build/Products/"

# Find the iphonesimulator directory that contains UI test artifacts
# (DerivedData may contain multiple configs: alpha, production, etc.)
BUILD_DIR=$(find "$DERIVED_DATA_PATH/Build/Products" -maxdepth 2 -name "TangemUITests-Runner.app" -type d | head -1 | xargs -I{} dirname {})
# Fallback: if no test runner found, use any iphonesimulator directory
if [ -z "$BUILD_DIR" ]; then
  BUILD_DIR=$(find "$DERIVED_DATA_PATH/Build/Products" -maxdepth 1 -type d -name "*alpha*-iphonesimulator" | head -1)
fi
if [ -z "$BUILD_DIR" ]; then
  BUILD_DIR=$(find "$DERIVED_DATA_PATH/Build/Products" -maxdepth 1 -type d -name "*-iphonesimulator" | head -1)
fi

if [ -z "$BUILD_DIR" ]; then
  echo "ERROR: No iphonesimulator build directory found!"
  find "$DERIVED_DATA_PATH/Build/Products" -type d
  exit 1
fi

echo "Using build directory: $BUILD_DIR"

# Find actual paths to built artifacts
echo "=== Looking for build artifacts ==="
ls -la "$BUILD_DIR/" || { echo "Build directory not found!"; exit 1; }

# Find the main app (exclude Runner apps)
APP_PATH=$(find "$BUILD_DIR" -maxdepth 1 -name "*.app" ! -name "*Runner.app" | head -1)
TEST_RUNNER_PATH=$(find "$BUILD_DIR" -maxdepth 1 -name "TangemUITests-Runner.app" | head -1)
XCTEST_PATH=$(find "$BUILD_DIR" -path "*/PlugIns/TangemUITests.xctest" | head -1)

echo "Found app: $APP_PATH"
echo "Found test runner: $TEST_RUNNER_PATH"
echo "Found xctest: $XCTEST_PATH"

# If no separate test runner found, use the main app as test runner
if [ -z "$TEST_RUNNER_PATH" ] && [ -n "$APP_PATH" ]; then
  echo "Using main app as test runner (embedded tests)"
  TEST_RUNNER_PATH="$APP_PATH"
fi

if [ -z "$APP_PATH" ] || [ -z "$TEST_RUNNER_PATH" ] || [ -z "$XCTEST_PATH" ]; then
  echo "ERROR: Could not find all required build artifacts!"
  echo "Contents of build directory:"
  find "$BUILD_DIR" -name "*.app" -o -name "*.xctest"
  exit 1
fi

# Create Marathondevices file with worker and device configuration
echo "workers:" > Marathondevices
echo "  - transport:" >> Marathondevices
echo "      type: local" >> Marathondevices
echo "    devices:" >> Marathondevices
echo "$DEVICES_YAML" >> Marathondevices

echo "Generated Marathondevices:"
cat Marathondevices

# Generate Marathonfile.generated with echo (more reliable than heredoc)
{
  echo 'name: "Tangem iOS UI Tests"'
  echo 'outputDir: "marathon-output"'
  echo ''
  echo 'testOutputTimeoutMillis: 300000'
  echo 'testBatchTimeoutMillis: 480000'
  echo ''
  # Lower device init timeout since simulators are pre-booted and warmed up
  # Default is 300s; 60s is plenty for already-running simulators
  echo 'deviceInitializationTimeoutMillis: 60000'
  echo ''
  # Only keep video recordings for failed tests to save disk space
  echo 'screenRecordingPolicy: ON_FAILURE'
  echo ''
  echo 'vendorConfiguration:'
  echo '  type: "iOS"'
  echo '  bundle:'
  echo "    application: \"$APP_PATH\""
  echo "    testApplication: \"$TEST_RUNNER_PATH\""
  echo "    xctest: \"$XCTEST_PATH\""
  echo '  xctestrunEnv:'
  echo '    test:'
  echo "      SIMULATOR_PORT_MAPPING: \"$PORT_MAPPING\""
  # Reduce I/O overhead: suppress xcodebuild runner output
  echo '  hideRunnerOutput: true'
  echo '  compactOutput: true'
  echo '  xcresult:'
  echo '    pullingPolicy: ALWAYS'
  echo '    remoteClean: false'
  # No extra lifecycle commands — simulators are pre-warmed
  echo '  lifecycle:'
  echo '    onPrepare: []'
  echo ''
  echo 'poolingStrategy:'
  echo '  type: "omni"'
  echo ''
  echo 'batchingStrategy:'
  echo "  type: \"fixed-size\""
  echo "  size: $BATCH_SIZE"
  echo "  lastMileLength: 1"
  echo ''
  echo 'sortingStrategy:'
  echo '  type: "execution-time"'
  echo '  order: "desc"'
  echo '  percentile: 80.0'
  echo '  timeLimit: "-PT1H"'
  echo ''
  echo 'retryStrategy:'
  echo '  type: "fixed-quota"'
  echo '  totalAllowedRetryQuota: 20'
  echo '  retryPerTestQuota: 1'
  echo ''
  echo 'flakinessStrategy:'
  echo '  type: "ignore"'
  echo ''
  echo 'analyticsConfiguration:'
  echo '  type: "disabled"'
  echo ''
  echo 'debug: false'
} > Marathonfile.generated

# Add filtering config if test class specified
if [ -n "$TEST_CLASS" ]; then
  {
    echo ""
    echo "filteringConfiguration:"
    echo "  allowlist:"
    echo "    - type: \"simple-class-name\""
    echo "      values:"
    
    IFS=',' read -ra CLASSES <<< "$TEST_CLASS"
    for CLASS in "${CLASSES[@]}"; do
      # Trim whitespace and strip module prefix (e.g. "TangemUITests.ClassName" -> "ClassName")
      CLASS=$(echo "$CLASS" | xargs | sed 's/^[^.]*\.//')
      printf '        - "%s"\n' "$CLASS"
    done
  } >> Marathonfile.generated
fi

echo "Generated Marathonfile.generated:"
cat Marathonfile.generated
