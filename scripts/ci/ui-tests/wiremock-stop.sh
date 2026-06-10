#!/bin/bash
# Stop and remove WireMock containers
# No required env (removes all wiremock-* containers regardless of count)

set -e

docker ps -aq --filter "name=wiremock-" | xargs docker rm -f 2>/dev/null || true
