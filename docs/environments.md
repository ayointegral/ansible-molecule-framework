# Environment Guide

## Ansible Molecule Testing Framework

This document describes the 15 environment compartments and their organization.

---

## Environment Matrix

### Overview

The framework uses 15 separate environment compartments:
- **7 Live environments**: Production-grade configurations
- **7 Test environments**: Testing and development configurations  
- **1 Shared environment**: Common configurations shared across all environments

### Directory Structure

```
inventories/
├── live/                          # Production environments
│   ├── platform/                  # Platform infrastructure
│   │   ├── platform-core/         # Core services (DNS, NTP, etc.)
│   │   ├── platform-network/      # Network services
│   │   ├── platform-security/     # Security services
│   │   └── platform-storage/      # Storage services
│   └── apps/                      # Application workloads
│       ├── apps-web/              # Web tier
│       ├── apps-api/              # API/Backend tier
│       └── apps-data/             # Data tier
├── test/                          # Test environments (mirrors live)
│   ├── platform/
│   │   ├── platform-core/
│   │   ├── platform-network/
│   │   ├── platform-security/
│   │   └── platform-storage/
│   └── apps/
│       ├── apps-web/
│       ├── apps-api/
│       └── apps-data/
└── shared/                        # Shared configurations
    ├── hosts.yml
    └── group_vars/
        └── all.yml
```

---

## Live Environments

### Platform Layer

#### live-platform-core
**Purpose:** Core infrastructure services that all other services depend on.

**Typical Services:**
- DNS (BIND, Unbound)
- NTP (chrony, ntpd)
- LDAP/AD integration
- Certificate Authority
- Logging infrastructure (rsyslog)

**Example hosts.yml:**
```yaml
all:
  children:
    dns_servers:
      hosts:
        dns01.example.com:
        dns02.example.com:
    ntp_servers:
      hosts:
        ntp01.example.com:
```

#### live-platform-network
**Purpose:** Network infrastructure and connectivity services.

**Typical Services:**
- Load balancers (HAProxy, Nginx)
- VPN servers (OpenVPN, WireGuard)
- Reverse proxies
- Service mesh components

#### live-platform-security
**Purpose:** Security and access control services.

**Typical Services:**
- Firewalls
- WAF (Web Application Firewall)
- IDS/IPS
- Security scanning
- Vault/secrets management

#### live-platform-storage
**Purpose:** Storage infrastructure services.

**Typical Services:**
- NFS servers
- S3-compatible storage (MinIO)
- Backup services
- Distributed storage (GlusterFS, Ceph)

### Application Layer

#### live-apps-web
**Purpose:** Web-facing application tier.

**Typical Services:**
- Web servers (Nginx, Apache)
- Frontend applications
- Static content servers
- CDN origins

#### live-apps-api
**Purpose:** API and backend application tier.

**Typical Services:**
- Application servers
- API gateways
- Microservices
- Message queues

#### live-apps-data
**Purpose:** Data storage and processing tier.

**Typical Services:**
- Databases (PostgreSQL, MySQL, MongoDB)
- Caches (Redis, Memcached)
- Search engines (Elasticsearch)
- Data processing (Kafka, Spark)

---

## Test Environments

Test environments mirror the live structure exactly, allowing:
- Safe testing of configuration changes
- Development of new playbooks
- Integration testing before production deployment

### Differences from Live

| Aspect | Live | Test |
|--------|------|------|
| Resource sizing | Production-grade | Minimal/shared |
| Redundancy | High availability | Single instance |
| Data | Real/sensitive | Synthetic/sanitized |
| Access | Restricted | Development team |
| Monitoring | Full alerting | Reduced |

---

## Shared Environment

### Purpose
Contains configurations common to all environments:
- Default variables
- Common group_vars
- Shared templates
- Cross-environment secrets (encrypted)

### group_vars/all.yml Example
```yaml
---
# Common variables across all environments

# DNS
common_dns_servers:
  - 8.8.8.8
  - 8.8.4.4

# NTP
common_ntp_servers:
  - time.nist.gov
  - pool.ntp.org

# Timezone
common_timezone: UTC

# Package management
common_epel_enabled: true
common_package_update: false

# Security
common_password_policy:
  min_length: 12
  require_uppercase: true
  require_lowercase: true
  require_numbers: true
  require_special: true

# Monitoring
common_monitoring_enabled: true
common_prometheus_scrape_interval: 15s
```

---

## Usage

### Running playbooks against specific environments

```bash
# Deploy to live platform core
ansible-playbook -i inventories/live/platform/platform-core/hosts.yml \
    playbooks/live/platform/deploy-core.yml

# Deploy to test apps data
ansible-playbook -i inventories/test/apps/apps-data/hosts.yml \
    playbooks/test/apps/deploy-data.yml

# Include shared variables
ansible-playbook -i inventories/live/platform/platform-core/hosts.yml \
    -i inventories/shared/hosts.yml \
    playbooks/live/platform/deploy-core.yml
```

### Environment-specific variables

Use group_vars within each environment directory:
```
inventories/live/platform/platform-core/
├── hosts.yml
└── group_vars/
    └── all.yml          # Variables for this environment
```

### Cross-environment playbooks

For operations spanning multiple environments, use the shared inventory:
```bash
ansible-playbook -i inventories/shared/hosts.yml \
    playbooks/shared/validate.yml --limit "live_*"
```

---

## Best Practices

1. **Separation of Concerns:**
   - Keep environment-specific configs in their directories
   - Use shared only for truly common settings

2. **Variable Precedence:**
   - Shared < Environment group_vars < Host vars
   - Override shared defaults as needed

3. **Secrets Management:**
   - Use ansible-vault for sensitive data
   - Different vault passwords per environment tier

4. **Testing Workflow:**
   - Always test in test environment first
   - Mirror live structure exactly
   - Use same playbooks with different inventories

5. **Documentation:**
   - Document environment-specific requirements
   - Keep host files updated
   - Track changes in version control
