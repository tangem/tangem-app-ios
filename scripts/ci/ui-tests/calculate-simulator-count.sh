#!/bin/bash
set -euo pipefail

# Calculate the optimal number of simulators and Marathon batch size based on
# the actual test count. This avoids wasting time on device-preparation overhead
# for simulators that will sit idle because there aren't enough tests to keep
# them busy, and reduces per-test runner-launch overhead for large test suites.
#
# Inputs (environment variables):
#   TEST_CLASS      — comma-separated class names (optional; empty = all tests)
#   MAX_SIMULATORS  — upper bound from workflow input (default 8)
#
# Output:
#   Writes SIMULATOR_COUNT and MARATHON_BATCH_SIZE to $GITHUB_ENV

TESTS_DIR="TangemUITests/Tests"
TESTS_PER_SIM=3    # sweet spot: amortises ~40s device-prep overhead
MIN_SIMULATORS=2   # always keep basic parallelism
MAX_SIMULATORS="${MAX_SIMULATORS:-8}"

count_test_methods() {
    local file="$1"
    grep -c '^\s*func test' "$file" 2>/dev/null || echo 0
}

# --- Count tests -------------------------------------------------------

TEST_COUNT=0

if [ -n "${TEST_CLASS:-}" ]; then
    # Specific class(es) requested (comma-separated, e.g. "BlockchainSmokeUITests,SendUITests")
    IFS=',' read -ra CLASSES <<< "$TEST_CLASS"
    for CLASS in "${CLASSES[@]}"; do
        # Strip optional module prefix (TangemUITests.)
        CLASS="${CLASS#TangemUITests.}"
        CLASS=$(echo "$CLASS" | xargs)   # trim whitespace

        # Find the matching .swift file
        FILE=$(find "$TESTS_DIR" -name "${CLASS}.swift" -type f 2>/dev/null | head -1)
        if [ -n "$FILE" ]; then
            COUNT=$(count_test_methods "$FILE")
            echo "  ${CLASS}: ${COUNT} test(s) in ${FILE}"
            TEST_COUNT=$((TEST_COUNT + COUNT))
        else
            echo "  ⚠️ ${CLASS}: file not found under ${TESTS_DIR}, skipping"
        fi
    done
else
    # All tests
    while IFS= read -r FILE; do
        COUNT=$(count_test_methods "$FILE")
        TEST_COUNT=$((TEST_COUNT + COUNT))
    done < <(find "$TESTS_DIR" -name "*.swift" -type f 2>/dev/null)
fi

if [ "$TEST_COUNT" -eq 0 ]; then
    echo "⚠️ Could not detect any test methods — falling back to MAX_SIMULATORS ($MAX_SIMULATORS)"
    OPTIMAL=$MAX_SIMULATORS
else
    # Formula: min(MAX, max(MIN, ceil(TEST_COUNT / TESTS_PER_SIM)))
    RAW=$(( (TEST_COUNT + TESTS_PER_SIM - 1) / TESTS_PER_SIM ))  # ceil division
    OPTIMAL=$RAW
    [ "$OPTIMAL" -lt "$MIN_SIMULATORS" ] && OPTIMAL=$MIN_SIMULATORS
    [ "$OPTIMAL" -gt "$MAX_SIMULATORS" ] && OPTIMAL=$MAX_SIMULATORS
fi

# --- Calculate batch size -----------------------------------------------
# Target ~4 batches per simulator: enough scheduling flexibility with
# significantly less runner-launch overhead than batch=1.
#   BATCH = max(1, min(MAX_BATCH, floor(tests_per_sim / BATCHES_PER_SIM)))

BATCHES_PER_SIM=4
MAX_BATCH=8

if [ "$TEST_COUNT" -eq 0 ] || [ "$OPTIMAL" -eq 0 ]; then
    BATCH_SIZE=1
else
    TESTS_PER_SIMULATOR=$(( (TEST_COUNT + OPTIMAL - 1) / OPTIMAL ))  # ceil
    BATCH_SIZE=$(( TESTS_PER_SIMULATOR / BATCHES_PER_SIM ))
    [ "$BATCH_SIZE" -lt 1 ] && BATCH_SIZE=1
    [ "$BATCH_SIZE" -gt "$MAX_BATCH" ] && BATCH_SIZE=$MAX_BATCH
fi

# --- Export results -----------------------------------------------------

echo "📊 Simulator count calculation:"
echo "   Tests detected : $TEST_COUNT"
echo "   Tests/simulator: $TESTS_PER_SIM"
echo "   Raw (ceil)     : $(( (TEST_COUNT + TESTS_PER_SIM - 1) / TESTS_PER_SIM ))"
echo "   Min/Max bounds : $MIN_SIMULATORS / $MAX_SIMULATORS"
echo "   ➜ SIMULATOR_COUNT=$OPTIMAL"
echo ""
echo "📊 Batch size calculation:"
echo "   Tests/simulator: $(( (TEST_COUNT + OPTIMAL - 1) / OPTIMAL ))"
echo "   Target batches : $BATCHES_PER_SIM per simulator"
echo "   Max batch cap  : $MAX_BATCH"
echo "   ➜ MARATHON_BATCH_SIZE=$BATCH_SIZE"

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "SIMULATOR_COUNT=$OPTIMAL" >> "$GITHUB_ENV"
    echo "MARATHON_BATCH_SIZE=$BATCH_SIZE" >> "$GITHUB_ENV"
else
    # Local run — just export for the current shell
    export SIMULATOR_COUNT=$OPTIMAL
    export MARATHON_BATCH_SIZE=$BATCH_SIZE
    echo "(local mode: exported SIMULATOR_COUNT=$OPTIMAL, MARATHON_BATCH_SIZE=$BATCH_SIZE)"
fi
