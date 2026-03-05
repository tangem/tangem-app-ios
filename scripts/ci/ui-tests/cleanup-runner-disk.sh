#!/bin/bash
# Aggressive disk cleanup for the GitHub Actions self-hosted runner (builder4).
# Run this ON THE RUNNER MACHINE when "No space left on device" happens during
# "Prepare all required actions" or during the job. Workflow steps cannot run
# before actions are extracted, so this must be executed manually or via cron.
#
# Usage (on runner as runner user, e.g. builder4):
#   bash cleanup-runner-disk.sh
# Or from repo: ./scripts/ci/ui-tests/cleanup-runner-disk.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔍 Runner disk cleanup..."
df -h / | tail -1

# marathon-output in any workspace under _work
RUNNER_WORK="${RUNNER_WORK:-$HOME/actions-runner/_work}"
if [ -d "$RUNNER_WORK" ]; then
  echo "Cleaning marathon-output in workspaces..."
  find "$RUNNER_WORK" -maxdepth 4 -type d -name "marathon-output" -exec rm -rf {} + 2>/dev/null || true
fi

# Shared cache cleanup (DerivedData, Action temp files)
"$SCRIPT_DIR/cleanup-caches.sh"

echo "After cleanup:"
df -h / | tail -1
echo "✅ Done. Re-run the workflow."
