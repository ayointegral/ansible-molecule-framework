# Usage Guide

## Running Molecule Tests

### Test a Single Role

```bash
# Using make
make molecule ROLE=common/base

# Using script
./scripts/run_molecule.sh -r common/base

# Directly with molecule
cd roles/common/base
molecule test
```

### Run Specific Molecule Commands

```bash
# Only converge (apply role)
molecule converge

# Only verify
molecule verify

# Only destroy
molecule destroy

# Login to container
molecule login
```

### Test Multiple Roles

```bash
# Run all molecule tests
make molecule-all

# Using CI pipeline
python ci/simulator.py --stage molecule
```

## Using Different Scenarios

### Default (Docker)

```bash
molecule test -s default
```

### Podman

```bash
molecule test -s podman
# or
MOLECULE_DRIVER_NAME=podman molecule test
```

### Multi-Platform

```bash
cd molecule
molecule test -s multi-platform
```

## Running the CI Pipeline

### Full Pipeline

```bash
# Using make
make pipeline

# Using script
./ci/scripts/run_pipeline.sh
```

### Specific Stages

```bash
# Lint only
make lint

# Syntax check only
make syntax

# Molecule only
python ci/simulator.py --stage molecule
```

### Generate Reports

```bash
# JSON report
python ci/simulator.py --stage all --report json

# HTML report
python ci/simulator.py --stage all --report html

# JUnit report (for CI systems)
python ci/simulator.py --stage all --report junit
```

## Working with Inventories

### Structure

```
inventories/
├── live/           # Production environments
│   ├── platform/   # Platform services
│   └── apps/       # Application services
├── test/           # Test environments
│   ├── platform/
│   └── apps/
└── shared/         # Shared configurations
```

### Using Inventories

```bash
# Run playbook against specific environment
ansible-playbook playbooks/shared/site.yml \
  -i inventories/test/platform/platform-core/hosts.yml

# Check mode (dry run)
ansible-playbook playbooks/shared/configure.yml \
  -i inventories/live/apps/apps-web/hosts.yml \
  --check
```

## Common Tasks

### Create a New Role

```bash
# Initialize role structure
cd roles/<category>
ansible-galaxy role init <role_name>

# Add molecule scenario
cd <role_name>
molecule init scenario default --driver-name docker
```

### Run Validation

```bash
ansible-playbook playbooks/shared/validate.yml \
  -i inventories/test/platform/platform-core/hosts.yml
```

### Clean Up

```bash
# Remove all molecule containers
./scripts/cleanup.sh --containers

# Full cleanup
./scripts/cleanup.sh --all
```
