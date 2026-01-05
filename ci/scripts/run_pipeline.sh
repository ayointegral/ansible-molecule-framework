#!/bin/bash
# CI Pipeline Runner Script
# Runs the complete CI pipeline with configurable options

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CI_DIR="${PROJECT_ROOT}/ci"

# Default values
STAGE="all"
ROLE=""
PARALLEL=4
REPORT_FORMAT="json"
VERBOSE=""
DRY_RUN=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --stage STAGE     Stage to run (lint, syntax, molecule, all) [default: all]"
    echo "  -r, --role ROLE       Specific role to test (e.g., common/base)"
    echo "  -p, --parallel N      Number of parallel jobs [default: 4]"
    echo "  -f, --format FORMAT   Report format (json, html, junit) [default: json]"
    echo "  -v, --verbose         Enable verbose output"
    echo "  -d, --dry-run         Show what would be run"
    echo "  -h, --help            Show this help message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--stage)
            STAGE="$2"
            shift 2
            ;;
        -r|--role)
            ROLE="$2"
            shift 2
            ;;
        -p|--parallel)
            PARALLEL="$2"
            shift 2
            ;;
        -f|--format)
            REPORT_FORMAT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="--verbose"
            shift
            ;;
        -d|--dry-run)
            DRY_RUN="--dry-run"
            shift
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

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Ansible Molecule CI Pipeline${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Stage: ${STAGE}"
echo "Role: ${ROLE:-all}"
echo "Parallel: ${PARALLEL}"
echo "Report: ${REPORT_FORMAT}"
echo ""

# Build command
CMD="python3 ${CI_DIR}/simulator.py"
CMD="${CMD} --stage ${STAGE}"
CMD="${CMD} --parallel ${PARALLEL}"
CMD="${CMD} --report ${REPORT_FORMAT}"

if [[ -n "${ROLE}" ]]; then
    CMD="${CMD} --role ${ROLE}"
fi

if [[ -n "${VERBOSE}" ]]; then
    CMD="${CMD} ${VERBOSE}"
fi

if [[ -n "${DRY_RUN}" ]]; then
    CMD="${CMD} ${DRY_RUN}"
fi

echo "Executing: ${CMD}"
echo ""

# Run pipeline
cd "${PROJECT_ROOT}"
eval "${CMD}"
EXIT_CODE=$?

if [[ ${EXIT_CODE} -eq 0 ]]; then
    echo -e "\n${GREEN}Pipeline completed successfully!${NC}"
else
    echo -e "\n${RED}Pipeline failed with exit code ${EXIT_CODE}${NC}"
fi

exit ${EXIT_CODE}
