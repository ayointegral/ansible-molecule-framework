#!/bin/bash
# Bootstrap Script
# Sets up the development environment for Ansible Molecule testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Ansible Molecule Bootstrap${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check Python
echo -n "Checking Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo -e "${GREEN}${PYTHON_VERSION}${NC}"
else
    echo -e "${RED}Python 3 not found${NC}"
    echo "Please install Python 3.9 or higher"
    exit 1
fi

# Check pip
echo -n "Checking pip... "
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}${PIP_VERSION}${NC}"
else
    echo -e "${RED}pip not found${NC}"
    echo "Please install pip"
    exit 1
fi

# Create virtual environment
echo ""
echo "Creating virtual environment..."
cd "${PROJECT_ROOT}"
if [[ ! -d "venv" ]]; then
    python3 -m venv venv
    echo -e "${GREEN}Virtual environment created${NC}"
else
    echo -e "${YELLOW}Virtual environment already exists${NC}"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Install Ansible Galaxy requirements
echo ""
echo "Installing Ansible Galaxy collections..."
if [[ -f "requirements.yml" ]]; then
    ansible-galaxy collection install -r requirements.yml
    ansible-galaxy role install -r requirements.yml || true
fi

# Check Docker
echo ""
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        echo -e "${GREEN}${DOCKER_VERSION}${NC}"
    else
        echo -e "${YELLOW}Docker installed but not running${NC}"
    fi
else
    echo -e "${YELLOW}Docker not installed${NC}"
    echo "Docker is required for Molecule testing"
fi

# Check Podman
echo -n "Checking Podman... "
if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version | cut -d' ' -f3)
    echo -e "${GREEN}${PODMAN_VERSION}${NC}"
else
    echo -e "${YELLOW}Podman not installed (optional)${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Bootstrap Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To activate the virtual environment:"
echo "  source venv/bin/activate"
echo ""
echo "To run molecule tests:"
echo "  make molecule ROLE=common/base"
echo ""
echo "To run the CI pipeline:"
echo "  make pipeline"
