#!/bin/bash
# Downloads Allure test plan and generates Marathon filtering config
# Resolves test IDs to class.method names by searching the codebase for setAllureId() calls
# Requires: allurectl installed, ALLURE_JOB_RUN_ID set

set -e

if [ -z "$ALLURE_JOB_RUN_ID" ]; then
  echo "No ALLURE_JOB_RUN_ID, skipping test plan filter"
  exit 0
fi

echo "=== Downloading Allure test plan ==="
allurectl job-run plan --output-file testplan.json

if [ ! -f testplan.json ]; then
  echo "No testplan.json generated, running all tests"
  exit 0
fi

echo "Test plan contents:"
cat testplan.json

TESTS=$(jq -c '.tests[]?' testplan.json 2>/dev/null || true)

if [ -z "$TESTS" ]; then
  echo "No tests in test plan, running all tests"
  exit 0
fi

TEST_FILTERS=()

while IFS= read -r test_entry; do
  [ -z "$test_entry" ] && continue

  selector=$(echo "$test_entry" | jq -r '.selector // ""')
  test_id=$(echo "$test_entry" | jq -r '.id // ""')

  if [ -n "$selector" ] && [ "$selector" != "" ]; then
    # Selector available — normalize to Class#method format for Marathon simple-test-name
    normalized=$(echo "$selector" | sed 's/\//./g')
    # Extract ClassName#method or ClassName.method, normalize to Class#method
    class_method=$(echo "$normalized" | awk -F'[.#]' '{if(NF>=2) print $(NF-1)"#"$NF; else print $0}')
    TEST_FILTERS+=("$class_method")
    echo "ID $test_id: using selector -> $class_method"
  elif [ -n "$test_id" ] && [ "$test_id" != "" ]; then
    # Selector empty — resolve from codebase by allureId
    echo "ID $test_id: selector empty, searching codebase..."

    match=$(grep -rn "setAllureId(${test_id})" TangemUITests/ 2>/dev/null | head -1 || true)

    if [ -z "$match" ]; then
      echo "  Warning: no test found with setAllureId($test_id), skipping"
      continue
    fi

    file=$(echo "$match" | cut -d: -f1)
    line=$(echo "$match" | cut -d: -f2)

    echo "  Found in $file:$line"

    # Find the class name: last 'class' declaration before the setAllureId line
    class_name=$(head -n "$line" "$file" | grep "class " | grep -v "//" | tail -1 | sed 's/.*class \([A-Za-z0-9_]*\).*/\1/')

    # Find the method name: last 'func test...' declaration before the setAllureId line
    method_name=$(head -n "$line" "$file" | grep "func test" | tail -1 | sed 's/.*func \(test[A-Za-z0-9_]*\).*/\1/')

    if [ -n "$class_name" ] && [ -n "$method_name" ]; then
      TEST_FILTERS+=("${class_name}#${method_name}")
      echo "  Resolved -> ${class_name}#${method_name}"
    else
      echo "  Warning: could not resolve class/method for ID $test_id (class=$class_name, method=$method_name)"
    fi
  fi
done <<< "$TESTS"

if [ ${#TEST_FILTERS[@]} -eq 0 ]; then
  echo "Error: no test filters resolved from test plan, failing to prevent running all tests"
  exit 1
fi

echo "Resolved ${#TEST_FILTERS[@]} test(s) from test plan"

# Build Marathon filter YAML file
FILTER_FILE="marathon-testplan-filter.yaml"
{
  echo "filteringConfiguration:"
  echo "  allowlist:"
  echo "    - type: \"simple-test-name\""
  echo "      values:"

  for filter in "${TEST_FILTERS[@]}"; do
    printf '        - "%s"\n' "$filter"
  done
} > "$FILTER_FILE"

echo "=== Generated Marathon test plan filter ==="
cat "$FILTER_FILE"

# Export path for subsequent workflow steps
echo "ALLURE_TESTPLAN_FILTER=$FILTER_FILE" >> "$GITHUB_ENV"
