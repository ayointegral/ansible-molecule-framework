# Ansible Molecule Testing Framework Makefile
# ============================================

.PHONY: help install lint syntax test molecule molecule-all pipeline clean reports

# Variables
ROLE ?=
DRIVER ?= docker
SCENARIO ?= default
PYTHON := python3
PIP := pip3

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help message
	@echo "Ansible Molecule Testing Framework"
	@echo "==================================="
	@echo ""
	@echo "Usage: make [target] [ROLE=rolename] [DRIVER=docker|podman] [SCENARIO=default|podman|windows]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# Setup and Installation
install: ## Install all dependencies
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)Installing Ansible Galaxy requirements...$(NC)"
	ansible-galaxy install -r requirements.yml --force
	@echo "$(GREEN)Installation complete!$(NC)"

install-collections: ## Install only Ansible collections
	ansible-galaxy collection install -r requirements.yml --force

install-roles: ## Install only Ansible roles
	ansible-galaxy role install -r requirements.yml --force

# Linting
lint: lint-yaml lint-ansible ## Run all linters

lint-yaml: ## Run yamllint
	@echo "$(GREEN)Running yamllint...$(NC)"
	yamllint -c .yamllint.yml . || true

lint-ansible: ## Run ansible-lint
	@echo "$(GREEN)Running ansible-lint...$(NC)"
	ansible-lint --force-color || true

lint-python: ## Run Python linters
	@echo "$(GREEN)Running flake8...$(NC)"
	flake8 ci/ tests/ --max-line-length=120 || true

# Syntax Checks
syntax: ## Run Ansible syntax check on all playbooks
	@echo "$(GREEN)Checking playbook syntax...$(NC)"
	@find playbooks -name "*.yml" -exec ansible-playbook --syntax-check {} \; 2>/dev/null || true

syntax-roles: ## Check syntax for all roles
	@echo "$(GREEN)Checking role syntax...$(NC)"
	@for role in $$(find roles -mindepth 2 -maxdepth 2 -type d); do \
		echo "Checking $$role..."; \
		ansible-playbook --syntax-check -e "role_path=$$role" /dev/stdin <<< "- hosts: localhost\n  roles:\n    - $$role" 2>/dev/null || true; \
	done

# Molecule Testing
# Note: ANSIBLE_ALLOW_BROKEN_CONDITIONALS is needed for molecule-docker with Ansible 2.19+
MOLECULE_ENV := ANSIBLE_ALLOW_BROKEN_CONDITIONALS=true

molecule: ## Run molecule test for a specific role (use ROLE=name)
ifndef ROLE
	@echo "$(RED)Error: ROLE is required. Usage: make molecule ROLE=common/base$(NC)"
	@exit 1
endif
	@echo "$(GREEN)Running molecule test for role: $(ROLE)$(NC)"
	cd roles/$(ROLE) && $(MOLECULE_ENV) molecule test -s $(SCENARIO)

molecule-converge: ## Run molecule converge for a specific role
ifndef ROLE
	@echo "$(RED)Error: ROLE is required. Usage: make molecule-converge ROLE=common/base$(NC)"
	@exit 1
endif
	@echo "$(GREEN)Running molecule converge for role: $(ROLE)$(NC)"
	cd roles/$(ROLE) && $(MOLECULE_ENV) molecule converge -s $(SCENARIO)

molecule-verify: ## Run molecule verify for a specific role
ifndef ROLE
	@echo "$(RED)Error: ROLE is required$(NC)"
	@exit 1
endif
	@echo "$(GREEN)Running molecule verify for role: $(ROLE)$(NC)"
	cd roles/$(ROLE) && $(MOLECULE_ENV) molecule verify -s $(SCENARIO)

molecule-destroy: ## Destroy molecule instances for a specific role
ifndef ROLE
	@echo "$(RED)Error: ROLE is required$(NC)"
	@exit 1
endif
	cd roles/$(ROLE) && $(MOLECULE_ENV) molecule destroy -s $(SCENARIO)

molecule-all: ## Run molecule tests for all roles
	@echo "$(GREEN)Running molecule tests for all roles...$(NC)"
	$(PYTHON) ci/simulator.py --stage molecule

molecule-list: ## List all roles with molecule tests
	@echo "$(GREEN)Roles with molecule tests:$(NC)"
	@find roles -name "molecule.yml" -exec dirname {} \; | sed 's|/molecule/.*||' | sort -u

# CI/CD Pipeline
pipeline: ## Run full CI/CD pipeline
	@echo "$(GREEN)Running full CI/CD pipeline...$(NC)"
	$(PYTHON) ci/simulator.py --all

pipeline-lint: ## Run pipeline lint stage only
	$(PYTHON) ci/simulator.py --stage lint

pipeline-syntax: ## Run pipeline syntax stage only
	$(PYTHON) ci/simulator.py --stage syntax

pipeline-unit: ## Run pipeline unit test stage only
	$(PYTHON) ci/simulator.py --stage unit

pipeline-integration: ## Run pipeline integration stage only
	$(PYTHON) ci/simulator.py --stage integration

# Testing
test: ## Run all tests (unit + integration)
	@echo "$(GREEN)Running all tests...$(NC)"
	pytest tests/ -v --tb=short

test-unit: ## Run unit tests only
	pytest tests/unit/ -v --tb=short

test-integration: ## Run integration tests only
	pytest tests/integration/ -v --tb=short

# Reports
reports: ## Generate all reports
	@echo "$(GREEN)Generating reports...$(NC)"
	$(PYTHON) ci/simulator.py --generate-reports
	@echo "Reports saved to ci/reports/"

reports-html: ## Generate HTML report
	$(PYTHON) ci/simulator.py --generate-reports --format html

reports-junit: ## Generate JUnit XML report
	$(PYTHON) ci/simulator.py --generate-reports --format junit

# Utilities
clean: ## Clean up temporary files and caches
	@echo "$(GREEN)Cleaning up...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".molecule" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.retry" -delete 2>/dev/null || true
	rm -rf ci/reports/*.html ci/reports/*.xml ci/reports/*.json 2>/dev/null || true
	rm -f ansible.log 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-molecule: ## Clean up all molecule instances
	@echo "$(GREEN)Destroying all molecule instances...$(NC)"
	@for role in $$(find roles -name "molecule.yml" -exec dirname {} \; | sed 's|/molecule/.*||' | sort -u); do \
		echo "Cleaning $$role..."; \
		cd $$role && molecule destroy --all 2>/dev/null || true; \
		cd - > /dev/null; \
	done

check-deps: ## Check if all dependencies are installed
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@command -v ansible >/dev/null 2>&1 || echo "$(RED)ansible not found$(NC)"
	@command -v molecule >/dev/null 2>&1 || echo "$(RED)molecule not found$(NC)"
	@command -v docker >/dev/null 2>&1 || echo "$(YELLOW)docker not found (optional)$(NC)"
	@command -v podman >/dev/null 2>&1 || echo "$(YELLOW)podman not found (optional)$(NC)"
	@command -v ansible-lint >/dev/null 2>&1 || echo "$(RED)ansible-lint not found$(NC)"
	@command -v yamllint >/dev/null 2>&1 || echo "$(RED)yamllint not found$(NC)"
	@echo "$(GREEN)Dependency check complete!$(NC)"

# Bootstrap
bootstrap: ## Initial project setup
	@echo "$(GREEN)Bootstrapping project...$(NC)"
	./scripts/bootstrap.sh

# Environment-specific targets
env-live: ## Show live environment inventory
	ansible-inventory --list -i inventories/live/

env-test: ## Show test environment inventory
	ansible-inventory --list -i inventories/test/

# Windows-specific targets
windows-test: ## Run Windows role tests (auto-detects QEMU/provider)
	@echo "$(GREEN)Running Windows role tests...$(NC)"
	@./scripts/windows-molecule-test.sh roles/windows/iis test
	@./scripts/windows-molecule-test.sh roles/windows/windows_features test
	@./scripts/windows-molecule-test.sh roles/windows/windows_firewall test

windows-test-role: ## Run Windows test for specific role (use ROLE=windows/iis)
ifndef ROLE
	@echo "$(RED)Error: ROLE is required. Usage: make windows-test-role ROLE=windows/iis$(NC)"
	@exit 1
endif
	@./scripts/windows-molecule-test.sh roles/$(ROLE) test

windows-converge: ## Run Windows converge for specific role (use ROLE=windows/iis)
ifndef ROLE
	@echo "$(RED)Error: ROLE is required. Usage: make windows-converge ROLE=windows/iis$(NC)"
	@exit 1
endif
	@./scripts/windows-molecule-test.sh roles/$(ROLE) converge

windows-check: ## Check Windows testing prerequisites
	@echo "$(GREEN)Checking Windows testing prerequisites...$(NC)"
	@echo ""
	@echo "Architecture: $$(uname -m)"
	@echo ""
	@echo "QEMU:"
	@command -v qemu-system-x86_64 >/dev/null 2>&1 && echo "  $(GREEN)qemu-system-x86_64 found$(NC)" || echo "  $(RED)qemu-system-x86_64 not found$(NC)"
	@vagrant plugin list 2>/dev/null | grep -q vagrant-qemu && echo "  $(GREEN)vagrant-qemu plugin installed$(NC)" || echo "  $(RED)vagrant-qemu plugin not installed$(NC)"
	@echo ""
	@echo "VirtualBox:"
	@command -v VBoxManage >/dev/null 2>&1 && echo "  $(GREEN)VirtualBox found$(NC)" || echo "  $(YELLOW)VirtualBox not found$(NC)"
	@echo ""
	@echo "Delegated (Remote Host):"
	@[ -n "$$WINDOWS_HOST" ] && echo "  $(GREEN)WINDOWS_HOST=$$WINDOWS_HOST$(NC)" || echo "  $(YELLOW)WINDOWS_HOST not set$(NC)"
	@[ -n "$$WINDOWS_PASSWORD" ] && echo "  $(GREEN)WINDOWS_PASSWORD is set$(NC)" || echo "  $(YELLOW)WINDOWS_PASSWORD not set$(NC)"
	@echo ""
	@echo "Ansible Windows Collections:"
	@ansible-galaxy collection list 2>/dev/null | grep -q ansible.windows && echo "  $(GREEN)ansible.windows installed$(NC)" || echo "  $(RED)ansible.windows not installed$(NC)"
	@ansible-galaxy collection list 2>/dev/null | grep -q community.windows && echo "  $(GREEN)community.windows installed$(NC)" || echo "  $(RED)community.windows not installed$(NC)"

windows-setup: ## Install Windows testing dependencies
	@echo "$(GREEN)Installing Windows testing dependencies...$(NC)"
	@echo ""
	@echo "Installing QEMU..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		brew install qemu || echo "$(YELLOW)QEMU install failed - may already be installed$(NC)"; \
	elif [ -f /etc/debian_version ]; then \
		sudo apt-get install -y qemu-system-x86 qemu-utils; \
	elif [ -f /etc/redhat-release ]; then \
		sudo dnf install -y qemu-kvm qemu-img; \
	fi
	@echo ""
	@echo "Installing vagrant-qemu plugin..."
	@vagrant plugin install vagrant-qemu || echo "$(YELLOW)Plugin install failed - may already be installed$(NC)"
	@echo ""
	@echo "Installing Ansible Windows collections..."
	@ansible-galaxy collection install ansible.windows community.windows --force
	@echo ""
	@echo "$(GREEN)Windows testing setup complete!$(NC)"

# Default target
.DEFAULT_GOAL := help
