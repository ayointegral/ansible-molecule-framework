#!/bin/bash
# Molecule Test Runner Script
# Runs molecule tests for specified roles

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROLES_DIR="${PROJECT_ROOT}/roles"

# Default values
ROLE=""
SCENARIO="default"
COMMAND="test"
DRIVER="docker"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --role ROLE       Role to test (e.g., common/base) [required]"
    echo "  -s, --scenario NAME   Molecule scenario [default: default]"
    echo "  -c, --command CMD     Molecule command (test, converge, verify, destroy)"
    echo "  -d, --driver DRIVER   Container driver (docker, podman) [default: docker]"
    echo "  -l, --list            List all roles with molecule tests"
    echo "  -h, --help            Show this help message"
}

list_roles() {
    echo "Roles with molecule tests:"
    echo ""
    find "${ROLES_DIR}" -path "*/molecule/default/molecule.yml" | while read -r mol_file; do
        role_dir=$(dirname "$(dirname "$(dirname "${mol_file}")")")
        role_name=$(echo "${role_dir}" | sed "s|${ROLES_DIR}/||")
        echo "  - ${role_name}"
    done
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--role)
            ROLE="$2"
            shift 2
            ;;
        -s|--scenario)
            SCENARIO="$2"
            shift 2
            ;;
        -c|--command)
            COMMAND="$2"
            shift 2
            ;;
        -d|--driver)
            DRIVER="$2"
            shift 2
            ;;
        -l|--list)
            list_roles
            exit 0
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

if [[ -z "${ROLE}" ]]; then
    echo -e "${RED}Error: Role is required${NC}"
    print_usage
    exit 1
fi

ROLE_PATH="${ROLES_DIR}/${ROLE}"

if [[ ! -d "${ROLE_PATH}" ]]; then
    echo -e "${RED}Error: Role not found: ${ROLE}${NC}"
    exit 1
fi

if [[ ! -d "${ROLE_PATH}/molecule/${SCENARIO}" ]]; then
    echo -e "${RED}Error: Scenario not found: ${SCENARIO}${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Molecule Test Runner${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Role: ${ROLE}"
echo "Scenario: ${SCENARIO}"
echo "Command: ${COMMAND}"
echo "Driver: ${DRIVER}"
echo ""

cd "${ROLE_PATH}"

# Set driver environment if needed
if [[ "${DRIVER}" == "podman" ]]; then
    export MOLECULE_DRIVER_NAME=podman
fi

# Run molecule
echo "Running: molecule ${COMMAND} -s ${SCENARIO}"
echo ""

export ANSIBLE_ALLOW_BROKEN_CONDITIONALS=true
molecule "${COMMAND}" -s "${SCENARIO}"

echo ""
echo -e "${GREEN}Molecule ${COMMAND} completed for ${ROLE}${NC}"
