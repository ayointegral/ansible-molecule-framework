#!/bin/bash
# Result Collection Script
# Collects and aggregates test results from various sources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPORTS_DIR="${PROJECT_ROOT}/ci/reports"
OUTPUT_FILE="${REPORTS_DIR}/aggregated_results.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Collecting test results...${NC}"

# Create reports directory if needed
mkdir -p "${REPORTS_DIR}"

# Find all JSON reports
JSON_REPORTS=$(find "${REPORTS_DIR}" -name "report_*.json" -type f 2>/dev/null | sort -r)

if [[ -z "${JSON_REPORTS}" ]]; then
    echo -e "${YELLOW}No JSON reports found in ${REPORTS_DIR}${NC}"
    exit 0
fi

# Count reports
REPORT_COUNT=$(echo "${JSON_REPORTS}" | wc -l | tr -d ' ')
echo "Found ${REPORT_COUNT} report(s)"

# Get latest report
LATEST_REPORT=$(echo "${JSON_REPORTS}" | head -1)
echo "Latest report: ${LATEST_REPORT}"

# Parse and display summary
if command -v jq &> /dev/null; then
    echo ""
    echo -e "${GREEN}Latest Report Summary:${NC}"
    echo "----------------------"
    jq -r '"Start Time: \(.start_time)"' "${LATEST_REPORT}"
    jq -r '"End Time: \(.end_time)"' "${LATEST_REPORT}"
    jq -r '"Duration: \(.total_duration | tostring | .[0:6])s"' "${LATEST_REPORT}"
    jq -r '"Passed: \(.passed)"' "${LATEST_REPORT}"
    jq -r '"Failed: \(.failed)"' "${LATEST_REPORT}"
    jq -r '"Skipped: \(.skipped)"' "${LATEST_REPORT}"
    jq -r '"Status: \(.overall_status | ascii_upcase)"' "${LATEST_REPORT}"
    
    # List failed stages if any
    FAILED=$(jq -r '.stages[] | select(.status == "failed") | .name' "${LATEST_REPORT}")
    if [[ -n "${FAILED}" ]]; then
        echo ""
        echo -e "${RED}Failed stages:${NC}"
        echo "${FAILED}" | while read -r stage; do
            echo "  - ${stage}"
        done
    fi
else
    echo -e "${YELLOW}jq not installed - showing raw report${NC}"
    cat "${LATEST_REPORT}"
fi

echo ""
echo -e "${GREEN}Results collection complete${NC}"
