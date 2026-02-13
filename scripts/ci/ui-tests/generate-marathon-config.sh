#!/bin/bash
# Generate Marathon device configuration and Marathonfile
# Required env: DERIVED_DATA_PATH, PORT_MAPPING, DEVICES_YAML
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

# Find build directory dynamically (scheme may use different configuration)
echo "=== Looking for build products ==="
ls -la "$DERIVED_DATA_PATH/Build/Products/"

# Find the iphonesimulator directory (Debug or Release)
BUILD_DIR=$(find "$DERIVED_DATA_PATH/Build/Products" -maxdepth 1 -type d -name "*-iphonesimulator" | head -1)

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
XCTEST_PATH=$(find "$BUILD_DIR" -path "*/TangemUITests-Runner.app/PlugIns/*.xctest" | head -1)

echo "Found app: $APP_PATH"
echo "Found test runner: $TEST_RUNNER_PATH"
echo "Found xctest: $XCTEST_PATH"

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
  echo 'testOutputTimeoutMillis: 180000'
  echo 'testBatchTimeoutMillis: 600000'
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
  echo ''
  echo 'poolingStrategy:'
  echo '  type: "omni"'
  echo ''
  echo 'batchingStrategy:'
  echo '  type: "isolate"'
  echo ''
  echo 'sortingStrategy:'
  echo '  type: "no-sorting"'
  echo ''
  echo 'retryStrategy:'
  echo '  type: "fixed-quota"'
  echo '  totalAllowedRetryQuota: 30'
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
