#!/bin/bash
# Notification Script
# Sends notifications about pipeline results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPORTS_DIR="${PROJECT_ROOT}/ci/reports"

# Default values
NOTIFICATION_TYPE="console"
STATUS=""
MESSAGE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE     Notification type (console, slack, email) [default: console]"
    echo "  -s, --status STATUS Pipeline status (passed, failed)"
    echo "  -m, --message MSG   Custom message"
    echo "  -h, --help          Show this help message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            NOTIFICATION_TYPE="$2"
            shift 2
            ;;
        -s|--status)
            STATUS="$2"
            shift 2
            ;;
        -m|--message)
            MESSAGE="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Get status from latest report if not provided
if [[ -z "${STATUS}" ]]; then
    LATEST_REPORT=$(find "${REPORTS_DIR}" -name "report_*.json" -type f 2>/dev/null | sort -r | head -1)
    if [[ -n "${LATEST_REPORT}" ]] && command -v jq &> /dev/null; then
        STATUS=$(jq -r '.overall_status' "${LATEST_REPORT}")
    else
        STATUS="unknown"
    fi
fi

# Build notification message
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

if [[ -z "${MESSAGE}" ]]; then
    MESSAGE="Pipeline ${STATUS} on ${HOSTNAME} at ${TIMESTAMP}"
fi

# Send notification based on type
case ${NOTIFICATION_TYPE} in
    console)
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  Pipeline Notification${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        if [[ "${STATUS}" == "passed" ]]; then
            echo -e "Status: ${GREEN}${STATUS^^}${NC}"
        elif [[ "${STATUS}" == "failed" ]]; then
            echo -e "Status: ${RED}${STATUS^^}${NC}"
        else
            echo -e "Status: ${YELLOW}${STATUS^^}${NC}"
        fi
        echo "Message: ${MESSAGE}"
        echo "Time: ${TIMESTAMP}"
        echo ""
        ;;
    slack)
        echo "Slack notifications not configured"
        echo "To enable, set SLACK_WEBHOOK_URL environment variable"
        if [[ -n "${SLACK_WEBHOOK_URL}" ]]; then
            PAYLOAD="{\"text\": \"${MESSAGE}\"}"
            curl -s -X POST -H 'Content-type: application/json' \
                --data "${PAYLOAD}" "${SLACK_WEBHOOK_URL}"
        fi
        ;;
    email)
        echo "Email notifications not configured"
        echo "To enable, configure mail settings"
        ;;
    *)
        echo -e "${RED}Unknown notification type: ${NOTIFICATION_TYPE}${NC}"
        exit 1
        ;;
esac

echo "Notification sent successfully"
