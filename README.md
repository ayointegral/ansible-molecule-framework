# Ansible Molecule Testing Framework

A production-grade Ansible testing infrastructure featuring 30 roles with comprehensive Molecule tests, 15 environment configurations, cloud provider emulation, and multi-platform support including Linux and Windows.

[![CI](https://github.com/ayointegral/ansible-molecule-framework/actions/workflows/ci.yml/badge.svg)](https://github.com/ayointegral/ansible-molecule-framework/actions/workflows/ci.yml)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Environments](#environments)
- [Roles](#roles)
- [Cloud Simulation](#cloud-simulation)
- [Testing](#testing)
- [CI/CD Integration](#cicd-integration)
- [Windows Testing](#windows-testing)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Overview

This framework provides a complete infrastructure-as-code testing solution using Ansible and Molecule. It demonstrates best practices for:

- **Role Development**: Modular, reusable Ansible roles with proper structure
- **Testing**: Comprehensive testing with Molecule across multiple platforms
- **Environment Management**: Separate configurations for dev, staging, production, and more
- **Cloud Simulation**: Free cloud emulators (LocalStack, Azurite, etc.) for realistic testing
- **CI/CD Integration**: GitHub Actions workflows with full test coverage
- **Multi-Platform Support**: Linux (Ubuntu, Debian, Rocky Linux) and Windows Server

### Key Metrics

| Metric | Count |
|--------|-------|
| Ansible Roles | 30 |
| Environments | 15 (7 live + 7 test + 1 shared) |
| Test Platforms | 4 (Ubuntu, Debian, Rocky, Windows) |
| Cloud Emulators | 6 (LocalStack, MinIO, Azurite, fake-gcs, Vault, Consul) |

---

## Features

### Role Categories

| Category | Roles | Description |
|----------|-------|-------------|
| **common** | base, packages, users | Base system configuration |
| **containers** | docker, podman | Container runtime installation |
| **databases** | postgresql, mysql, redis | Database servers |
| **monitoring** | prometheus, grafana, alertmanager, node_exporter | Observability stack |
| **security** | firewall, hardening, certificates, selinux | Security configuration |
| **storage** | disk_management, lvm, nfs | Storage management |
| **web** | nginx, haproxy | Web servers and load balancers |
| **cloud/aws** | localstack, s3, ec2_simulation | AWS service simulation |
| **cloud/azure** | storage_account, keyvault | Azure service simulation |
| **cloud/gcp** | gcs, pubsub | GCP service simulation |
| **cloud** | vault, consul | HashiCorp tools |
| **windows** | iis, windows_features, windows_firewall | Windows Server roles |

### Testing Features

- **Multi-Platform Testing**: Test roles across Ubuntu, Debian, Rocky Linux, and Windows
- **Cloud Emulation**: Test cloud integrations without cloud costs using sidecar containers
- **Idempotence Verification**: Ensure roles can run multiple times without changes
- **Parallel Execution**: Run up to 8 tests concurrently in CI
- **Multiple Drivers**: Docker (primary), Podman, and Delegated

---

## Quick Start

### Prerequisites

- Python 3.9+
- Docker or Podman
- Ansible 2.15+

### Installation

```bash
# Clone the repository
git clone https://github.com/ayointegral/ansible-molecule-framework.git
cd ansible-molecule-framework

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
├── .github/workflows/          # GitHub Actions CI
│   ├── ci.yml                  # Main CI workflow
│   ├── _lint.yml               # Lint workflow
│   └── _molecule-test.yml      # Molecule test workflow
│
├── inventories/                # Environment configurations (15)
│   ├── live/                   # Production environments (7)
│   ├── test/                   # Test environments (7)
│   └── shared/                 # Shared configuration
│
├── roles/                      # Ansible roles (30)
│   ├── common/                 # base, packages, users
│   ├── containers/             # docker, podman
│   ├── databases/              # postgresql, mysql, redis
│   ├── monitoring/             # prometheus, grafana, alertmanager, node_exporter
│   ├── security/               # firewall, hardening, certificates, selinux
│   ├── storage/                # disk_management, lvm, nfs
│   ├── web/                    # nginx, haproxy
│   ├── cloud/                  # AWS, Azure, GCP, Vault, Consul
│   └── windows/                # iis, windows_features, windows_firewall
│
├── ci/                         # CI/CD tools
│   └── simulator.py            # Pipeline orchestrator
│
├── docs/                       # Documentation
│   ├── cloud-simulation.md     # Cloud emulator guide
│   ├── windows-testing.md      # Windows testing guide
│   └── ...
│
└── scripts/                    # Helper scripts
```

---

## Environments

### Live Environments (7)

| Environment | Purpose | Inventory Path |
|-------------|---------|----------------|
| live-platform-core | Core infrastructure (DNS, DHCP) | `inventories/live/live-platform-core/` |
| live-platform-network | Network services (VPN, Load Balancers) | `inventories/live/live-platform-network/` |
| live-platform-security | Security services (Firewall, WAF) | `inventories/live/live-platform-security/` |
| live-platform-storage | Storage services (NFS, S3-compat) | `inventories/live/live-platform-storage/` |
| live-apps-web | Web tier applications | `inventories/live/live-apps-web/` |
| live-apps-api | API/Backend services | `inventories/live/live-apps-api/` |
| live-apps-data | Data tier (databases, caches) | `inventories/live/live-apps-data/` |

### Test Environments (7)

Mirror environments for testing playbooks before applying to live systems.

### Shared Configuration

Common variables shared across all environments in `inventories/shared/`.

---

## Roles

### Complete Role Inventory

| Category | Role | Description | Platform | CI Status |
|----------|------|-------------|----------|-----------|
| common | base | System baseline configuration | Linux | Tested |
| common | packages | Package management | Linux | Tested |
| common | users | User and group management | Linux | Tested |
| containers | docker | Docker CE installation | Linux | Tested |
| containers | podman | Podman installation | Linux | Tested |
| databases | postgresql | PostgreSQL server | Linux | Tested |
| databases | mysql | MySQL/MariaDB server | Linux | Tested |
| databases | redis | Redis cache server | Linux | Tested |
| monitoring | prometheus | Prometheus metrics server | Linux | Tested |
| monitoring | grafana | Grafana visualization | Linux | Tested |
| monitoring | alertmanager | Prometheus Alertmanager | Linux | Tested |
| monitoring | node_exporter | Prometheus Node Exporter | Linux | Tested |
| security | firewall | UFW/firewalld/iptables | Linux | Tested |
| security | hardening | OS hardening | Linux | Tested |
| security | certificates | TLS certificate management | Linux | Tested |
| security | selinux | SELinux configuration | Linux | Tested |
| storage | disk_management | Disk partitioning | Linux | Tested |
| storage | lvm | LVM volume management | Linux | Tested |
| storage | nfs | NFS server and client | Linux | Tested |
| web | nginx | Nginx web server | Linux | Tested |
| web | haproxy | HAProxy load balancer | Linux | Tested |
| cloud/aws | localstack | LocalStack AWS emulator | Linux | Tested |
| cloud/aws | s3 | S3-compatible storage (MinIO) | Linux | Tested |
| cloud/aws | ec2_simulation | EC2 metadata simulation | Linux | Tested |
| cloud/azure | storage_account | Azure Blob simulation (Azurite) | Linux | Tested |
| cloud/azure | keyvault | Azure Key Vault simulation | Linux | Tested |
| cloud/gcp | gcs | GCS simulation (fake-gcs-server) | Linux | Tested |
| cloud/gcp | pubsub | Pub/Sub emulator | Linux | Tested |
| cloud | vault | HashiCorp Vault | Linux | Tested |
| cloud | consul | HashiCorp Consul | Linux | Tested |
| windows | iis | IIS Web Server | Windows | Manual |
| windows | windows_features | Windows Features | Windows | Manual |
| windows | windows_firewall | Windows Firewall | Windows | Manual |

---

## Cloud Simulation

Test cloud integrations without incurring cloud costs using free emulators as sidecar containers.

### Available Emulators

| Cloud | Emulator | Services | License |
|-------|----------|----------|---------|
| **AWS** | LocalStack | S3, SQS, SNS, DynamoDB, Lambda, IAM, CloudWatch | Free tier |
| **AWS** | MinIO | S3-compatible storage | Apache 2.0 |
| **Azure** | Azurite | Blob, Queue, Table storage | MIT (Microsoft) |
| **GCP** | fake-gcs-server | Cloud Storage | MIT |
| **GCP** | Pub/Sub Emulator | Pub/Sub messaging | Free |
| **Secrets** | HashiCorp Vault | KV secrets, policies | MPL 2.0 |
| **Discovery** | HashiCorp Consul | Service registry, KV store | MPL 2.0 |

### How It Works

Cloud roles use Docker sidecar containers to provide emulated cloud services:

```yaml
# molecule.yml example with LocalStack sidecar
platforms:
  - name: test-instance
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    networks:
      - name: localstack-network

  - name: localstack
    image: localstack/localstack:latest
    pre_build_image: true
    env:
      SERVICES: "s3,sqs,sns,dynamodb"
    networks:
      - name: localstack-network
```

### Running Cloud Tests

```bash
# Test AWS LocalStack integration
cd roles/cloud/aws/localstack && molecule test

# Test Azure Azurite integration
cd roles/cloud/azure/storage_account && molecule test

# Test HashiCorp Vault
cd roles/cloud/vault && molecule test
```

See [docs/cloud-simulation.md](docs/cloud-simulation.md) for detailed documentation.

---

## Testing

### Molecule Overview

Each role includes Molecule tests with:

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

# Debug mode - keep containers running
molecule test --destroy=never
molecule login -h instance-ubuntu

# Test specific scenario
molecule test -s podman
```

### Makefile Commands

```bash
make help           # Show all commands
make lint           # Run linting
make syntax         # Syntax check
make molecule ROLE=common/base  # Test specific role
make molecule-all   # Test all roles
make pipeline       # Run full pipeline
make clean          # Cleanup test artifacts
```

### CI Simulator

```bash
# List all roles with Molecule tests
python ci/simulator.py --list-roles

# Run all stages
python ci/simulator.py --stage all

# Run specific stage
python ci/simulator.py --stage lint
python ci/simulator.py --stage molecule

# Test specific role
python ci/simulator.py --stage molecule --role common/base

# Generate reports
python ci/simulator.py --stage all --report html
```

---

## CI/CD Integration

### GitHub Actions Pipeline

The CI pipeline runs on every push and PR:

| Job | Description | Roles Tested |
|-----|-------------|--------------|
| **Discover** | Find all roles with molecule tests | - |
| **Lint** | YAML and Ansible linting | - |
| **Syntax** | Playbook syntax validation | - |
| **Molecule Quick** | Standard role tests | 21 roles |
| **Molecule Cloud** | Cloud roles with emulators | 9 roles |
| **Summary** | Aggregate results | - |

### Test Matrix

**Standard Roles (21):**
- common/base, common/packages, common/users
- containers/docker, containers/podman
- databases/mysql, databases/postgresql, databases/redis
- monitoring/alertmanager, monitoring/grafana, monitoring/node_exporter, monitoring/prometheus
- security/certificates, security/firewall, security/hardening, security/selinux
- storage/disk_management, storage/lvm, storage/nfs
- web/haproxy, web/nginx

**Cloud Roles (9):**
- cloud/aws/localstack, cloud/aws/s3, cloud/aws/ec2_simulation
- cloud/azure/storage_account, cloud/azure/keyvault
- cloud/gcp/gcs, cloud/gcp/pubsub
- cloud/vault, cloud/consul

**Excluded (require Windows host):**
- windows/iis, windows/windows_features, windows/windows_firewall

---

## Windows Testing

Windows roles require a Windows host with WinRM enabled.

### Setup

```powershell
# Run as Administrator on Windows host
Enable-PSRemoting -Force
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
```

### Running Tests

```bash
# Set connection details
export WINDOWS_HOST=192.168.1.100
export WINDOWS_USER=Administrator
export WINDOWS_PASSWORD=YourPassword

# Run tests
cd roles/windows/iis
molecule test -s delegated
```

See [docs/windows-testing.md](docs/windows-testing.md) for detailed documentation.

---

## Configuration Reference

### Key Files

| File | Purpose |
|------|---------|
| `ansible.cfg` | Ansible configuration |
| `requirements.txt` | Python dependencies |
| `requirements.yml` | Ansible collections |
| `.yamllint.yml` | YAML linting rules |
| `Makefile` | Automation commands |

### Required Molecule Settings

All molecule.yml files must include:

```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
```

All converge.yml files must use the full path:

```yaml
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}"
```

---

## Troubleshooting

### Common Issues

#### Ansible 2.19+ String Conditional Errors

```
Conditional result was derived from value of type 'str'
```

**Fix**: Add `ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"` to molecule.yml provisioner env.

#### Role Not Found

```
the role 'rolename' was not found
```

**Fix**: Use full `MOLECULE_PROJECT_DIRECTORY` path in converge.yml, not `| basename`.

#### Galaxy Role Name Validation

```
Computed fully qualified role name does not follow galaxy requirements
```

**Fix**: Ensure `role_name` and `namespace` are inside `galaxy_info` block in meta/main.yml.

#### Docker Container Cleanup

```bash
# Remove all Molecule containers
docker ps -a | grep molecule | awk '{print $1}' | xargs docker rm -f

# Or use Make
make clean
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

1. Fork the repository
2. Create a feature branch
3. Make changes with molecule tests
4. Run `make lint` and `make molecule ROLE=<your-role>`
5. Update documentation
6. Submit pull request

### Adding a New Role

```bash
# Create role structure
mkdir -p roles/category/new_role/{defaults,handlers,meta,tasks,templates,vars,molecule/default}

# Create required files
touch roles/category/new_role/{defaults,handlers,meta,tasks}/main.yml
touch roles/category/new_role/molecule/default/{molecule,converge,verify}.yml
```

---

## Documentation

- [Cloud Simulation Guide](docs/cloud-simulation.md)
- [Windows Testing Guide](docs/windows-testing.md)
- [Setup Guide](docs/setup.md)
- [Usage Guide](docs/usage.md)
- [Troubleshooting](docs/troubleshooting.md)

## Error Tracking

All errors and resolutions are documented in [ERRORS.md](ERRORS.md).

## Progress Log

Development progress is tracked in [PROGRESS.md](PROGRESS.md).

---

## License

MIT License

## Acknowledgments

- [Jeff Geerling](https://github.com/geerlingguy) for excellent Docker images
- [Ansible](https://www.ansible.com/) for the automation platform
- [Molecule](https://molecule.readthedocs.io/) for the testing framework
- [LocalStack](https://localstack.cloud/) for AWS emulation
- [Azurite](https://github.com/Azure/Azurite) for Azure emulation
