# Setup Guide

## Prerequisites

Before setting up the Ansible Molecule Testing Framework, ensure you have:

- **Python 3.9+** - Required for Ansible and Molecule
- **Docker** - Primary container runtime for testing
- **Git** - Version control
- **Make** - For running automation commands

### Optional Dependencies

- **Podman** - Alternative container runtime
- **jq** - JSON parsing for reports

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ansible-molecule
   ```

2. **Run the bootstrap script**
   ```bash
   ./scripts/bootstrap.sh
   ```

3. **Activate the virtual environment**
   ```bash
   source venv/bin/activate
   ```

4. **Verify installation**
   ```bash
   molecule --version
   ansible --version
   ```

## Manual Setup

If you prefer manual setup:

### 1. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

### 2. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 3. Install Ansible Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 4. Verify Docker

```bash
docker info
docker run hello-world
```

## Configuration

### Ansible Configuration

The `ansible.cfg` file contains project-specific settings:

- Role paths
- Inventory locations
- Log settings
- Connection defaults

### Molecule Configuration

Each role has its own `molecule/default/molecule.yml` with:

- Container platform definitions
- Provisioner settings
- Verifier configuration

## Troubleshooting

### Docker Permission Issues

```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Virtual Environment Issues

```bash
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Molecule Container Issues

```bash
# Clean up all molecule containers
./scripts/cleanup.sh --containers

# Destroy specific role containers
cd roles/common/base
molecule destroy
```
