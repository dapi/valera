#!/bin/bash
# Deploy status monitor with dynamic screen refresh
# Usage: ./scripts/deploy_status_monitor.sh <infra_dir> <stage> [timeout]

set -e

INFRA_DIR="$1"
STAGE="$2"
TIMEOUT="${3:-1200}"
APP="valera"

if [ -z "$INFRA_DIR" ]; then
  echo "Error: INFRA_DIR is not set"
  exit 1
fi

if [ ! -d "$INFRA_DIR" ]; then
  echo "Error: INFRA_DIR '$INFRA_DIR' does not exist"
  exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Handle Ctrl+C gracefully
cleanup() {
  echo ""
  echo -e "${YELLOW}Monitoring interrupted by user${NC}"
  tput cnorm  # Restore cursor visibility
  exit 130
}
trap cleanup INT TERM

START_TIME=$(date +%s)
ITERATION=0

# Initial clear and header
tput clear
echo "================================================================"
echo "  Deploy Status Monitor"
echo "================================================================"
echo "App:      $APP"
echo "Version:  $(./bin/semver 2>/dev/null || echo 'unknown')"
echo "Stage:    ${STAGE}"
echo "Start:    $(date -d @${START_TIME} '+%Y-%m-%d %H:%M:%S')"
echo "Timeout:  ${TIMEOUT}s"
echo "================================================================"
echo ""
echo "Checking status every 2 seconds..."
echo ""

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  ITERATION=$((ITERATION + 1))

  # Refresh display every iteration
  # Move cursor to line 11 (after header) and clear from there down
  tput cup 11 0
  tput ed

  echo -e "${YELLOW}[+${ELAPSED}s]${NC} Iteration ${ITERATION} - Checking status..."
  echo ""

  # Run the actual status check
  OUTPUT=$(cd "$INFRA_DIR" && direnv exec . make app-status APP="$APP" STAGE="$STAGE" 2>&1 || true)
  echo "$OUTPUT"

  # Check for consistent status
  if echo "$OUTPUT" | grep -q "Deployment status: consistent"; then
    echo ""
    echo -e "${GREEN}Deployment is consistent!${NC}"
    break
  fi

  # Check for timeout
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo -e "${RED}Timeout reached (${TIMEOUT}s).${NC}"
    echo "Deployment did not reach consistent state."
    exit 1
  fi

  sleep 2
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "================================================================"
echo -e "  ${GREEN}Deploy Status Summary${NC}"
echo "================================================================"
echo "Start:    $(date -d @${START_TIME} '+%Y-%m-%d %H:%M:%S')"
echo "End:      $(date -d @${END_TIME} '+%Y-%m-%d %H:%M:%S')"
echo "Duration: ${DURATION}s (${MINUTES}m ${SECONDS}s)"
echo "Iterations: ${ITERATION}"
echo "================================================================"
