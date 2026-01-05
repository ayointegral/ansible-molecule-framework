# Ansible Molecule Testing Framework

A comprehensive Ansible testing infrastructure with multi-environment support, cloud provider simulation, and both Linux and Windows container testing.

## Overview

This project provides a production-grade Ansible testing framework featuring:

- **15 Environment Compartments**: 7 Live, 7 Test, plus shared configuration
- **26 Ansible Roles**: Covering infrastructure, web, databases, monitoring, security, and cloud simulations
- **Molecule Testing**: Full test coverage with Docker and Podman support
- **Windows Support**: Windows Server Core container testing (requires Windows host)
- **CI/CD Simulation**: Local pipeline simulator for comprehensive testing
- **Cloud Simulations**: AWS, Azure, and GCP service simulation for testing

## Quick Start

### Prerequisites

- Python 3.9+
- Docker or Podman
- Ansible 2.12+

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd ansible-molecule

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy install -r requirements.yml
```

### Running Tests

```bash
# Run molecule test for a specific role
make molecule ROLE=common/base

# Run all molecule tests
make molecule-all

# Run with Podman instead of Docker
make molecule ROLE=common/base DRIVER=podman

# Run lint checks
make lint

# Run full CI pipeline
make pipeline
```

## Project Structure

```
ansible-molecule/
├── inventories/          # Environment inventories (15 total)
│   ├── live/             # Production environments (7)
│   ├── test/             # Test environments (7)
│   └── shared/           # Shared configuration
├── roles/                # Ansible roles (20+)
│   ├── common/           # Base system roles
│   ├── web/              # Web server roles
│   ├── containers/       # Container platform roles
│   ├── security/         # Security roles
│   ├── storage/          # Storage roles
│   ├── cloud/            # Cloud simulation roles
│   ├── databases/        # Database roles
│   ├── monitoring/       # Monitoring roles
│   └── windows/          # Windows-specific roles
├── molecule/             # Global molecule scenarios
├── playbooks/            # Ansible playbooks
├── ci/                   # CI/CD pipeline simulator
├── tests/                # Unit and integration tests
├── docs/                 # Documentation
└── scripts/              # Utility scripts
```

## Environment Matrix

### Live Environments (7)

| Environment | Purpose |
|-------------|---------|
| live-platform-core | Core infrastructure (DNS, DHCP) |
| live-platform-network | Network services (VPN, Load Balancers) |
| live-platform-security | Security services (Firewall, WAF) |
| live-platform-storage | Storage services (NFS, S3-compat) |
| live-apps-web | Web tier applications |
| live-apps-api | API/Backend services |
| live-apps-data | Data tier (databases, caches) |

### Test Environments (7)

Mirrors the live environment structure for testing.

## Available Roles

### Core Infrastructure
| Role | Description | Status |
|------|-------------|--------|
| common/base | Base system configuration | ✅ Tested |
| common/packages | Package management | ✅ Tested |
| common/users | User and group management | ✅ Tested |
| security/firewall | Firewall (ufw/firewalld/iptables) | ✅ Tested |

### Web & Containers
| Role | Description | Status |
|------|-------------|--------|
| web/nginx | Nginx web server with SSL | ✅ Tested |
| web/haproxy | HAProxy load balancer | ✅ Tested |
| containers/docker | Docker installation | ✅ Tested |
| containers/podman | Podman installation | ✅ Tested |

### Storage
| Role | Description | Status |
|------|-------------|--------|
| storage/disk_management | Disk/VHD simulation | ✅ Tested |
| storage/lvm | LVM management | ✅ Tested |
| storage/nfs | NFS server/client | ✅ Tested |

### Databases
| Role | Description | Status |
|------|-------------|--------|
| databases/postgresql | PostgreSQL server | ✅ Tested |
| databases/mysql | MySQL/MariaDB server | ✅ Tested |
| databases/redis | Redis cache | ✅ Tested |

### Cloud Simulations
| Role | Description | Status |
|------|-------------|--------|
| cloud/aws/s3 | S3 simulation (MinIO) | ✅ Tested |
| cloud/aws/ec2_simulation | EC2 metadata simulation | ✅ Tested |
| cloud/azure/storage_account | Azure Blob simulation (Azurite) | ✅ Tested |
| cloud/azure/keyvault | Key Vault simulation | ✅ Tested |
| cloud/gcp/gcs | GCS simulation | ✅ Tested |

### Monitoring
| Role | Description | Status |
|------|-------------|--------|
| monitoring/prometheus | Prometheus server | ✅ Tested |
| monitoring/grafana | Grafana dashboards | ✅ Tested |
| monitoring/alertmanager | Prometheus Alertmanager | ✅ Tested |
| monitoring/node_exporter | Prometheus Node Exporter | ✅ Tested |

### Windows (Requires Windows Host)
| Role | Description | Status |
|------|-------------|--------|
| windows/iis | IIS web server | ⚠️ Windows Only |
| windows/windows_firewall | Windows Firewall | ⚠️ Windows Only |
| windows/windows_features | Windows Features | ⚠️ Windows Only |

## Molecule Testing

### Running Tests

Each role has its own molecule tests in `roles/<category>/<role>/molecule/default/`.

```bash
# Test a specific role
cd roles/common/base
molecule test

# Test with specific scenario
molecule test -s podman

# Run only converge (apply the role)
molecule converge

# Run only verify (run assertions)
molecule verify

# Debug - leave containers running
molecule test --destroy=never
```

### Supported Platforms

- Ubuntu 22.04 (geerlingguy/docker-ubuntu2204-ansible)
- Debian 12 (geerlingguy/docker-debian12-ansible)
- Rocky Linux 9 (geerlingguy/docker-rockylinux9-ansible)
- Windows Server 2022 (requires Windows host)

## CI/CD Pipeline Simulator

The local pipeline simulator runs all tests in sequence:

```bash
# Run full pipeline
python ci/simulator.py --stage all

# Run specific stage
python ci/simulator.py --stage lint
python ci/simulator.py --stage molecule --role common/base

# Generate reports
python ci/simulator.py --stage all --report html

# List all testable roles
python ci/simulator.py --list-roles

# Dry run
python ci/simulator.py --stage all --dry-run
```

### Pipeline Stages

1. **Lint**: ansible-lint, yamllint
2. **Syntax**: ansible-playbook --syntax-check
3. **Unit**: pytest unit tests
4. **Molecule**: Role-level molecule tests

## Makefile Commands

```bash
make help           # Show all commands
make lint           # Run linting
make syntax         # Syntax check
make molecule ROLE=<role>  # Test specific role
make molecule-all   # Test all roles
make pipeline       # Run full pipeline
make clean          # Cleanup test artifacts
make reports        # Generate test reports
```

## Configuration

### ansible.cfg

The main Ansible configuration with optimized settings for testing.

### requirements.yml

Ansible Galaxy collection requirements:
- community.general
- community.docker
- community.mysql
- community.postgresql
- ansible.windows (for Windows roles)
- community.windows (for Windows roles)

### requirements.txt

Python dependencies for running tests.

## Windows Testing

Windows roles require special configuration:

1. Windows containers only run on Windows hosts
2. For Linux/macOS, use delegated driver with Windows VMs
3. Configure WinRM on target Windows systems

```bash
# Set environment variables for Windows testing
export WINDOWS_HOST=your-windows-vm-ip
export WINDOWS_USER=Administrator
export WINDOWS_PASSWORD=your-password

# Run Windows role test
cd roles/windows/iis
molecule test
```

## Documentation

- [Setup Guide](docs/setup.md)
- [Usage Guide](docs/usage.md)
- [Role Documentation](docs/roles.md)
- [Environment Guide](docs/environments.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Architecture](ARCHITECTURE.md)

## Error Tracking

All errors and resolutions are documented in [ERRORS.md](ERRORS.md).

## Progress Log

Development progress is tracked in [PROGRESS.md](PROGRESS.md).

## Research Notes

Technical research and decisions are documented in [RESEARCH.md](RESEARCH.md).

## Contributing

1. Create a feature branch
2. Implement changes with molecule tests
3. Run `make lint` and `make molecule ROLE=<your-role>`
4. Update documentation
5. Submit pull request

## License

MIT License
