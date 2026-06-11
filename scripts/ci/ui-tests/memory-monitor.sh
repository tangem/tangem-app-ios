#!/bin/bash
# Periodically snapshot host memory state while tests run. The log lives outside
# the workspace so it survives runner death and checkout cleanup; preflight-cleanup.sh
# prints its tail on the next run if the host died mid-run.
# Optional env: MONITOR_INTERVAL (seconds, default: 60),
#               MONITOR_LOG (default: $HOME/ui-test-diagnostics/memory-monitor-<run id>-<attempt>.log)

# No set -e: the monitor must survive transient failures under the very memory
# pressure it is diagnosing — losing the final samples would defeat its purpose

INTERVAL="${MONITOR_INTERVAL:-60}"
LOG="${MONITOR_LOG:-$HOME/ui-test-diagnostics/memory-monitor-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}.log}"
mkdir -p "$(dirname "$LOG")"

# Keep the 10 most recent logs on the machine
ls -t "$(dirname "$LOG")"/memory-monitor-*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

echo "Memory monitor started: pid $$, interval ${INTERVAL}s, log $LOG"

while true; do
  {
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="
    memory_pressure -Q 2>/dev/null || vm_stat | head -6
    XC_COUNT=$(pgrep -f "xcodebuild" 2>/dev/null | wc -l | tr -d ' ')
    XC_RSS_MB=$(ps -axo rss,command | awk '/xcodebuild/ && !/awk/ {s+=$1} END {printf "%d", s/1024}')
    echo "xcodebuild: count=$XC_COUNT total_rss=${XC_RSS_MB}MB"
    echo "--- Top 5 processes by RSS ---"
    ps -axo rss=,pid=,comm= | sort -rn | head -5 | awk '{printf "%6d MB  %s %s\n", $1/1024, $2, $3}'
    docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' 2>/dev/null | grep wiremock || true
  } >> "$LOG" 2>&1
  sleep "$INTERVAL"
done
