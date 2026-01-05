#!/bin/bash
# Cleanup Script
# Removes temporary files, containers, and test artifacts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_REPORTS=false
CLEAN_CACHE=false
CLEAN_ALL=false
DRY_RUN=false

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --containers    Remove molecule containers"
    echo "  -i, --images        Remove molecule images"
    echo "  -r, --reports       Remove CI reports"
    echo "  -C, --cache         Remove Python cache"
    echo "  -a, --all           Remove everything"
    echo "  -d, --dry-run       Show what would be removed"
    echo "  -h, --help          Show this help message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        -i|--images)
            CLEAN_IMAGES=true
            shift
            ;;
        -r|--reports)
            CLEAN_REPORTS=true
            shift
            ;;
        -C|--cache)
            CLEAN_CACHE=true
            shift
            ;;
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
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
echo -e "${GREEN}  Cleanup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if ${DRY_RUN}; then
    echo -e "${YELLOW}DRY RUN MODE - No files will be deleted${NC}"
    echo ""
fi

# Clean containers
if ${CLEAN_CONTAINERS} || ${CLEAN_ALL}; then
    echo "Cleaning molecule containers..."
    CONTAINERS=$(docker ps -a --filter "name=molecule" --format "{{.Names}}" 2>/dev/null || true)
    if [[ -n "${CONTAINERS}" ]]; then
        echo "${CONTAINERS}" | while read -r container; do
            echo "  Removing: ${container}"
            if ! ${DRY_RUN}; then
                docker rm -f "${container}" 2>/dev/null || true
            fi
        done
    else
        echo "  No molecule containers found"
    fi
fi

# Clean images
if ${CLEAN_IMAGES} || ${CLEAN_ALL}; then
    echo ""
    echo "Cleaning molecule images..."
    IMAGES=$(docker images --filter "reference=molecule_local/*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    if [[ -n "${IMAGES}" ]]; then
        echo "${IMAGES}" | while read -r image; do
            echo "  Removing: ${image}"
            if ! ${DRY_RUN}; then
                docker rmi "${image}" 2>/dev/null || true
            fi
        done
    else
        echo "  No molecule images found"
    fi
fi

# Clean reports
if ${CLEAN_REPORTS} || ${CLEAN_ALL}; then
    echo ""
    echo "Cleaning CI reports..."
    REPORTS_DIR="${PROJECT_ROOT}/ci/reports"
    if [[ -d "${REPORTS_DIR}" ]]; then
        REPORT_COUNT=$(find "${REPORTS_DIR}" -type f -name "*.json" -o -name "*.html" -o -name "*.xml" 2>/dev/null | wc -l | tr -d ' ')
        echo "  Found ${REPORT_COUNT} report files"
        if ! ${DRY_RUN}; then
            find "${REPORTS_DIR}" -type f \( -name "*.json" -o -name "*.html" -o -name "*.xml" \) -delete
        fi
    fi
fi

# Clean cache
if ${CLEAN_CACHE} || ${CLEAN_ALL}; then
    echo ""
    echo "Cleaning Python cache..."
    if ! ${DRY_RUN}; then
        find "${PROJECT_ROOT}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find "${PROJECT_ROOT}" -type f -name "*.pyc" -delete 2>/dev/null || true
        find "${PROJECT_ROOT}" -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
        find "${PROJECT_ROOT}" -type d -name ".molecule" -exec rm -rf {} + 2>/dev/null || true
    fi
    echo "  Cache cleaned"
fi

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
