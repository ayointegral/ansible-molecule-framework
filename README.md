# Ansible Molecule Testing Framework

A production-grade Ansible testing infrastructure featuring 26 roles with comprehensive Molecule tests, 15 environment configurations, and multi-platform support including Linux and Windows.

![Architecture Diagram](docs/architecture.png)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Environments](#environments)
- [Roles](#roles)
- [Testing](#testing)
- [CI/CD Integration](#cicd-integration)
- [Windows Testing](#windows-testing)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This framework provides a complete infrastructure-as-code testing solution using Ansible and Molecule. It demonstrates best practices for:

- **Role Development**: Modular, reusable Ansible roles with proper structure
- **Testing**: Comprehensive testing with Molecule across multiple platforms
- **Environment Management**: Separate configurations for dev, staging, production, and more
- **CI/CD Integration**: Ready-to-use pipeline simulator and GitHub Actions workflows
- **Multi-Platform Support**: Linux (Ubuntu, Debian, Rocky Linux) and Windows Server

### Key Metrics

| Metric | Count |
|--------|-------|
| Ansible Roles | 26 |
| Environments | 15 (7 live + 7 test + 1 shared) |
| Test Platforms | 4 (Ubuntu, Debian, Rocky, Windows) |
| Molecule Drivers | 4 (Docker, Podman, Vagrant, Delegated) |

---

## Features

### Role Categories

- **Common**: Base system configuration, package management, user management
- **Containers**: Docker and Podman installation and configuration
- **Databases**: PostgreSQL, MySQL/MariaDB, Redis
- **Monitoring**: Prometheus, Grafana, Alertmanager, Node Exporter
- **Security**: Multi-backend firewall management (UFW, firewalld, iptables)
- **Storage**: Disk management, LVM, NFS server/client
- **Web**: Nginx web server, HAProxy load balancer
- **Cloud**: AWS (S3, EC2), Azure (Storage, Key Vault), GCP (GCS) simulations
- **Windows**: IIS, Windows Features, Windows Firewall

### Testing Features

- **Multi-Platform Testing**: Test roles across Ubuntu, Debian, Rocky Linux, and Windows
- **Idempotence Verification**: Ensure roles can run multiple times without changes
- **Verification Playbooks**: Assert expected state after role execution
- **Parallel Execution**: Run tests concurrently for faster feedback
- **Multiple Drivers**: Docker (primary), Podman, Vagrant, and Delegated

### CI/CD Features

- **Pipeline Simulator**: Local CI simulation with lint, syntax, and molecule stages
- **Multiple Report Formats**: JSON, HTML, and JUnit output
- **GitHub Actions Ready**: Pre-configured workflow templates
- **Makefile Automation**: Simple commands for common operations

---

## Architecture

The framework is organized into four main layers:

### 1. Infrastructure Layer
Manages 15 environment configurations with hierarchical variable inheritance:

```
inventories/
├── production/          # Live production environment
├── staging/             # Pre-production testing
├── development/         # Developer environment
├── qa/                  # Quality assurance
├── uat/                 # User acceptance testing
├── dr/                  # Disaster recovery
├── dmz/                 # DMZ/perimeter network
├── *_test/              # Mirror test environments (7)
└── shared/              # Shared variables across all
    ├── group_vars/
    └── host_vars/
```

### 2. Roles Layer
26 modular roles organized by function:

```
roles/
├── common/              # base, packages, users
├── containers/          # docker, podman
├── databases/           # postgresql, mysql, redis
├── monitoring/          # prometheus, grafana, alertmanager, node_exporter
├── security/            # firewall
├── storage/             # disk_management, lvm, nfs
├── web/                 # nginx, haproxy
├── cloud/
│   ├── aws/             # s3, ec2_simulation
│   ├── azure/           # storage_account, keyvault
│   └── gcp/             # gcs
└── windows/             # iis, windows_features, windows_firewall
```

### 3. Testing Layer
Molecule-based testing with multiple drivers and scenarios:

- **Drivers**: Docker, Podman, Vagrant, Delegated
- **Scenarios**: default, podman, qemu, delegated
- **Platforms**: Ubuntu 22.04, Debian 12, Rocky Linux 9, Windows Server

### 4. CI/CD Layer
Automated testing pipeline with the CI Simulator:

```
ci/
└── simulator.py         # Pipeline orchestrator
    ├── Lint Stage       # YAML and Ansible linting
    ├── Syntax Stage     # Playbook syntax validation
    └── Molecule Stage   # Full role testing
```

---

## Quick Start

### Prerequisites

- Python 3.9+
- Docker or Podman
- Ansible 2.15+

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ansible-molecule.git
cd ansible-molecule

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml
```

### Run Your First Test

```bash
# Test the base role
cd roles/common/base
molecule test

# Or use Make
make molecule ROLE=common/base
```

### Run All Tests

```bash
# Using Make
make molecule-all

# Using CI Simulator
python ci/simulator.py --stage molecule
```

---

## Project Structure

```
ansible-molecule/
├── ansible.cfg                 # Ansible configuration
├── requirements.txt            # Python dependencies
├── requirements.yml            # Ansible collections
├── Makefile                    # Automation commands
├── .yamllint.yml               # YAML linting rules
│
├── inventories/                # Environment configurations
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── staging/
│   ├── development/
│   ├── qa/
│   ├── uat/
│   ├── dr/
│   ├── dmz/
│   ├── production_test/
│   ├── staging_test/
│   ├── development_test/
│   ├── qa_test/
│   ├── uat_test/
│   ├── dr_test/
│   ├── dmz_test/
│   └── shared/
│       ├── group_vars/
│       └── host_vars/
│
├── roles/                      # Ansible roles
│   ├── common/
│   │   ├── base/
│   │   │   ├── defaults/main.yml
│   │   │   ├── handlers/main.yml
│   │   │   ├── meta/main.yml
│   │   │   ├── tasks/main.yml
│   │   │   ├── templates/
│   │   │   ├── vars/
│   │   │   └── molecule/
│   │   │       └── default/
│   │   │           ├── molecule.yml
│   │   │           ├── converge.yml
│   │   │           └── verify.yml
│   │   ├── packages/
│   │   └── users/
│   ├── containers/
│   ├── databases/
│   ├── monitoring/
│   ├── security/
│   ├── storage/
│   ├── web/
│   ├── cloud/
│   └── windows/
│
├── ci/                         # CI/CD tools
│   └── simulator.py
│
├── scripts/                    # Helper scripts
│   └── windows-molecule-test.sh
│
└── docs/                       # Documentation
    ├── architecture.d2
    ├── architecture.png
    ├── environments.md
    ├── roles.md
    ├── setup.md
    ├── troubleshooting.md
    ├── usage.md
    └── windows-testing.md
```

---

## Environments

### Live Environments (7)

| Environment | Purpose | Inventory Path |
|-------------|---------|----------------|
| production | Live production systems | `inventories/production/` |
| staging | Pre-production validation | `inventories/staging/` |
| development | Development and debugging | `inventories/development/` |
| qa | Quality assurance testing | `inventories/qa/` |
| uat | User acceptance testing | `inventories/uat/` |
| dr | Disaster recovery | `inventories/dr/` |
| dmz | Perimeter/DMZ network | `inventories/dmz/` |

### Test Environments (7)

Mirror environments for testing playbooks before applying to live:

- `production_test`, `staging_test`, `development_test`
- `qa_test`, `uat_test`, `dr_test`, `dmz_test`

### Shared Configuration

Common variables shared across all environments:

```yaml
# inventories/shared/group_vars/all.yml
---
# Organization defaults
org_name: "MyOrganization"
org_domain: "example.com"

# Common packages
common_packages:
  - vim
  - curl
  - wget
  - htop

# NTP servers
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
```

### Using Environments

```bash
# Run playbook against specific environment
ansible-playbook site.yml -i inventories/production/

# Override default inventory
ansible-playbook site.yml -i inventories/staging/

# Use environment-specific variables
ansible-playbook site.yml -i inventories/qa/ -e "deploy_version=2.0.0"
```

---

## Roles

### Role Summary

| Category | Role | Description | Platforms |
|----------|------|-------------|-----------|
| common | base | System baseline configuration | Linux |
| common | packages | Package management | Linux |
| common | users | User and group management | Linux |
| containers | docker | Docker CE installation | Linux |
| containers | podman | Podman installation | Linux |
| databases | postgresql | PostgreSQL server | Linux |
| databases | mysql | MySQL/MariaDB server | Linux |
| databases | redis | Redis cache server | Linux |
| monitoring | prometheus | Prometheus metrics server | Linux |
| monitoring | grafana | Grafana visualization | Linux |
| monitoring | alertmanager | Prometheus Alertmanager | Linux |
| monitoring | node_exporter | Prometheus Node Exporter | Linux |
| security | firewall | UFW/firewalld/iptables | Linux |
| storage | disk_management | Disk partitioning | Linux |
| storage | lvm | LVM volume management | Linux |
| storage | nfs | NFS server and client | Linux |
| web | nginx | Nginx web server | Linux |
| web | haproxy | HAProxy load balancer | Linux |
| cloud/aws | s3 | S3-compatible storage (MinIO) | Linux |
| cloud/aws | ec2_simulation | EC2 metadata simulation | Linux |
| cloud/azure | storage_account | Azure Blob simulation | Linux |
| cloud/azure | keyvault | Azure Key Vault simulation | Linux |
| cloud/gcp | gcs | GCS simulation | Linux |
| windows | iis | IIS Web Server | Windows |
| windows | windows_features | Windows Features | Windows |
| windows | windows_firewall | Windows Firewall | Windows |

### Role Structure

Each role follows Ansible best practices:

```
roles/<category>/<role>/
├── defaults/
│   └── main.yml          # Default variables (lowest precedence)
├── files/                # Static files
├── handlers/
│   └── main.yml          # Event handlers
├── meta/
│   └── main.yml          # Role metadata and dependencies
├── tasks/
│   └── main.yml          # Main task file
├── templates/            # Jinja2 templates
├── vars/
│   ├── main.yml          # Role variables
│   ├── debian.yml        # Debian-specific variables
│   └── redhat.yml        # RedHat-specific variables
└── molecule/
    └── default/
        ├── molecule.yml  # Molecule configuration
        ├── converge.yml  # Role application playbook
        └── verify.yml    # Verification playbook
```

### Using Roles

```yaml
# In a playbook
---
- name: Configure web servers
  hosts: webservers
  become: true
  
  roles:
    - role: common/base
    - role: common/packages
      vars:
        packages_install:
          - nginx
          - certbot
    - role: web/nginx
      vars:
        nginx_worker_processes: auto
        nginx_sites:
          - name: example.com
            server_name: example.com
            root: /var/www/example
```

---

## Testing

### Molecule Overview

Molecule is used for testing Ansible roles. Each role includes:

- **molecule.yml**: Test configuration
- **converge.yml**: Playbook to apply the role
- **verify.yml**: Playbook to verify expected state

### Test Sequence

1. **dependency**: Install role dependencies
2. **cleanup**: Clean up previous test artifacts
3. **destroy**: Destroy any existing test instances
4. **syntax**: Check playbook syntax
5. **create**: Create test instances
6. **prepare**: Prepare instances (install prerequisites)
7. **converge**: Apply the role
8. **idempotence**: Run converge again, verify no changes
9. **verify**: Run verification playbook
10. **cleanup**: Clean up test artifacts
11. **destroy**: Destroy test instances

### Running Tests

```bash
# Full test cycle
cd roles/common/base
molecule test

# Individual stages
molecule create      # Create test instances
molecule converge    # Apply the role
molecule verify      # Run verification
molecule destroy     # Cleanup

# Debug mode
molecule --debug test

# Keep instances after test
molecule test --destroy=never

# Test specific scenario
molecule test -s podman
```

### Makefile Commands

```bash
# Lint all roles
make lint

# Syntax check all roles
make syntax

# Test single role
make molecule ROLE=common/base

# Test all roles
make molecule-all

# Clean up Docker containers
make clean
```

### CI Simulator

The CI Simulator (`ci/simulator.py`) provides local CI/CD simulation:

```bash
# List all roles with Molecule tests
python ci/simulator.py --list-roles

# Run all stages
python ci/simulator.py --stage all

# Run specific stage
python ci/simulator.py --stage lint
python ci/simulator.py --stage syntax
python ci/simulator.py --stage molecule

# Test specific role
python ci/simulator.py --stage molecule --role common/base

# Dry run
python ci/simulator.py --stage all --dry-run

# Generate reports
python ci/simulator.py --stage all --report html
python ci/simulator.py --stage all --report json
python ci/simulator.py --stage all --report junit

# Parallel execution
python ci/simulator.py --stage molecule --parallel 4
```

### Test Platforms

| Platform | Image | Use Case |
|----------|-------|----------|
| Ubuntu 22.04 | geerlingguy/docker-ubuntu2204-ansible | Primary Linux testing |
| Debian 12 | geerlingguy/docker-debian12-ansible | Debian compatibility |
| Rocky Linux 9 | geerlingguy/docker-rockylinux9-ansible | RHEL compatibility |
| Windows Server | N/A (delegated) | Windows role testing |

### Molecule Configuration

Example `molecule.yml`:

```yaml
---
driver:
  name: docker

platforms:
  - name: instance-ubuntu
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
    privileged: true
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    tmpfs:
      - /run
      - /tmp
    command: ""

  - name: instance-rocky
    image: geerlingguy/docker-rockylinux9-ansible:latest
    pre_build_image: true
    privileged: true
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    tmpfs:
      - /run
      - /tmp
    command: ""

provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
  playbooks:
    converge: converge.yml
    verify: verify.yml

verifier:
  name: ansible

lint: |
  yamllint .
  ansible-lint
```

---

## CI/CD Integration

### GitHub Actions

Example workflow (`.github/workflows/molecule.yml`):

```yaml
---
name: Molecule Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install yamllint ansible-lint
      
      - name: Run linters
        run: |
          yamllint .
          ansible-lint

  molecule:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        role:
          - common/base
          - common/packages
          - common/users
          - containers/docker
          - containers/podman
          - databases/postgresql
          - databases/mysql
          - databases/redis
          - monitoring/prometheus
          - monitoring/grafana
          - web/nginx
          - web/haproxy
          - security/firewall
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          ansible-galaxy collection install -r requirements.yml
      
      - name: Run Molecule
        run: |
          cd roles/${{ matrix.role }}
          molecule test
        env:
          PY_COLORS: '1'
          ANSIBLE_FORCE_COLOR: '1'
```

### GitLab CI

Example `.gitlab-ci.yml`:

```yaml
---
stages:
  - lint
  - test

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"

.molecule-job:
  image: python:3.11
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - pip install -r requirements.txt
    - ansible-galaxy collection install -r requirements.yml

lint:
  stage: lint
  image: python:3.11
  script:
    - pip install yamllint ansible-lint
    - yamllint .
    - ansible-lint

molecule-common-base:
  extends: .molecule-job
  stage: test
  script:
    - cd roles/common/base && molecule test

molecule-web-nginx:
  extends: .molecule-job
  stage: test
  script:
    - cd roles/web/nginx && molecule test
```

---

## Windows Testing

### Architecture Limitations

Windows Server requires x86_64 architecture. This impacts testing options:

| Platform | Native Support | Emulated | Recommended |
|----------|---------------|----------|-------------|
| Intel Mac (x64) | VirtualBox, VMware | N/A | VirtualBox |
| Apple Silicon (M1-M4) | Not available | QEMU (very slow) | Delegated |
| Linux x64 | KVM, VirtualBox | N/A | KVM |
| Linux ARM64 | Not available | QEMU (very slow) | Delegated |

### Testing Scenarios

#### 1. Delegated (Recommended for ARM)

Uses a remote Windows host:

```bash
# Set connection details
export WINDOWS_HOST=192.168.1.100
export WINDOWS_USER=Administrator
export WINDOWS_PASSWORD=YourPassword

# Run tests
cd roles/windows/iis
molecule test -s delegated
```

#### 2. VirtualBox (x64 systems)

```bash
cd roles/windows/iis
molecule test  # Uses default VirtualBox scenario
```

#### 3. QEMU (Not recommended for ARM)

```bash
cd roles/windows/iis
molecule test -s qemu  # Very slow on ARM
```

### Windows Host Setup

Enable WinRM on the Windows host:

```powershell
# Run as Administrator
Enable-PSRemoting -Force
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Configure firewall
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" `
  -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
```

### Helper Script

```bash
# Auto-detect platform and run appropriate scenario
./scripts/windows-molecule-test.sh roles/windows/iis test

# Just converge
./scripts/windows-molecule-test.sh roles/windows/iis converge
```

---

## Configuration Reference

### ansible.cfg

```ini
[defaults]
inventory = inventories/development
roles_path = roles
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
callbacks_enabled = profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

### requirements.txt

```
ansible-core>=2.15
molecule>=6.0
molecule-docker>=2.1
molecule-vagrant>=1.0
ansible-lint>=6.0
yamllint>=1.32
pywinrm>=0.4.3
```

### requirements.yml

```yaml
---
collections:
  - name: community.general
    version: ">=7.0.0"
  - name: ansible.posix
    version: ">=1.5.0"
  - name: community.docker
    version: ">=3.4.0"
  - name: ansible.windows
    version: ">=2.0.0"
  - name: community.windows
    version: ">=2.0.0"
```

### .yamllint.yml

```yaml
---
extends: default

rules:
  line-length:
    max: 120
    level: warning
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no']
  comments:
    min-spaces-from-content: 1
  braces:
    max-spaces-inside: 1
  brackets:
    max-spaces-inside: 1

ignore: |
  .git/
  venv/
  .tox/
```

---

## Troubleshooting

### Common Issues

#### Ansible 2.19+ String Conditional Errors

**Error:**
```
Conditional result was derived from value of type 'str'
```

**Solution:** Add to molecule.yml:
```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
```

#### Role Not Found

**Error:**
```
the role 'rolename' was not found
```

**Solution:** Use full path in converge.yml:
```yaml
# Correct
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}"

# Wrong
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') | basename }}"
```

#### Galaxy Role Name Validation

**Error:**
```
Computed fully qualified role name does not follow galaxy requirements
```

**Solution:** Ensure `role_name` and `namespace` are inside `galaxy_info`:
```yaml
# Correct
galaxy_info:
  role_name: my_role
  namespace: my_namespace

# Wrong
galaxy_info:
  author: Someone
role_name: my_role
```

#### Docker Container Cleanup

```bash
# Remove all Molecule containers
docker ps -a | grep molecule | awk '{print $1}' | xargs docker rm -f

# Or use Make
make clean
```

#### Windows WinRM Connection Failed

1. Verify connectivity: `ping $WINDOWS_HOST`
2. Check WinRM port: `nc -zv $WINDOWS_HOST 5985`
3. Test with Python:
   ```python
   import winrm
   s = winrm.Session('192.168.1.100', auth=('Administrator', 'password'))
   print(s.run_cmd('hostname'))
   ```

### Debug Mode

```bash
# Verbose Molecule output
molecule --debug test

# Keep containers for debugging
molecule test --destroy=never
molecule login -h instance-ubuntu

# Ansible verbose output
molecule converge -- -vvv
```

---

## Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run linters: `make lint`
5. Run tests: `make molecule ROLE=your-role`
6. Submit pull request

### Adding a New Role

```bash
# Create role structure
mkdir -p roles/category/new_role/{defaults,handlers,meta,tasks,templates,vars,molecule/default}

# Create required files
touch roles/category/new_role/{defaults,handlers,meta,tasks}/main.yml
touch roles/category/new_role/molecule/default/{molecule,converge,verify}.yml

# Use an existing role as template
cp -r roles/common/base/molecule/default/* roles/category/new_role/molecule/default/
```

### Code Style

- Follow [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- Use YAML syntax, not key=value
- Include comments for complex logic
- Use fully qualified collection names (FQCN)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Jeff Geerling](https://github.com/geerlingguy) for excellent Docker images
- [Ansible](https://www.ansible.com/) for the automation platform
- [Molecule](https://molecule.readthedocs.io/) for the testing framework
- [D2](https://d2lang.com/) for diagram generation
