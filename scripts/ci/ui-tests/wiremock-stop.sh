#!/bin/bash
# Stop and remove WireMock containers
# Required env: SIMULATOR_COUNT

set -e

if [ -z "$SIMULATOR_COUNT" ]; then
  echo "ERROR: SIMULATOR_COUNT environment variable is required"
  exit 1
fi

for i in $(seq 1 $SIMULATOR_COUNT); do
  docker stop wiremock-$i 2>/dev/null || true
  docker rm wiremock-$i 2>/dev/null || true
done
