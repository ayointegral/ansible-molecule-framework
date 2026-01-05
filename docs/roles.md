# Roles Documentation

## Role Categories

### Common Roles

#### common/base
Base system configuration including timezone, hostname, and SSH settings.

**Variables:**
- `base_timezone`: System timezone (default: UTC)
- `base_hostname`: System hostname
- `base_locale`: System locale

#### common/packages
Package management for common system utilities.

**Variables:**
- `base_packages`: List of packages to install
- `package_state`: Package state (present/latest)

### Web Roles

#### web/nginx
Nginx web server installation and configuration.

**Variables:**
- `nginx_worker_processes`: Worker process count
- `nginx_vhosts`: Virtual host configurations
- `nginx_ssl_enabled`: Enable SSL support

#### web/haproxy
HAProxy load balancer configuration.

**Variables:**
- `haproxy_frontends`: Frontend definitions
- `haproxy_backends`: Backend server pools

### Container Roles

#### containers/docker
Docker CE installation.

**Variables:**
- `docker_version`: Docker version to install
- `docker_users`: Users to add to docker group

#### containers/podman
Podman container runtime installation.

**Variables:**
- `podman_registries`: Container registries

### Security Roles

#### security/firewall
Firewall management (iptables/firewalld/ufw).

**Variables:**
- `firewall_backend`: Backend (iptables/firewalld/ufw)
- `firewall_rules`: Firewall rule definitions

### Storage Roles

#### storage/nfs
NFS server and client configuration.

**Variables:**
- `nfs_exports`: NFS export definitions
- `nfs_mounts`: Client mount points

#### storage/lvm
LVM (Logical Volume Manager) configuration.

**Variables:**
- `lvm_volume_groups`: Volume group definitions
- `lvm_logical_volumes`: Logical volume definitions

### Database Roles

#### databases/postgresql
PostgreSQL database server.

**Variables:**
- `postgresql_version`: PostgreSQL version
- `postgresql_databases`: Database definitions
- `postgresql_users`: User definitions

#### databases/redis
Redis cache server.

**Variables:**
- `redis_bind_address`: Listen address
- `redis_maxmemory`: Maximum memory
- `redis_password`: Authentication password

### Monitoring Roles

#### monitoring/prometheus
Prometheus metrics server.

**Variables:**
- `prometheus_version`: Prometheus version
- `prometheus_scrape_configs`: Scrape target configurations

### Cloud Simulation Roles

#### cloud/aws/s3
S3-compatible storage (MinIO).

**Variables:**
- `minio_root_user`: Admin username
- `minio_root_password`: Admin password
- `minio_buckets`: Bucket definitions

#### cloud/azure/storage_account
Azure Blob Storage simulation (Azurite).

**Variables:**
- `azurite_blob_port`: Blob service port
- `azurite_loose_mode`: Enable loose mode

#### cloud/gcp/gcs
GCS simulation (fake-gcs-server).

**Variables:**
- `fake_gcs_port`: Service port
- `fake_gcs_buckets`: Initial buckets

## Creating New Roles

1. Create role directory structure
2. Add defaults/main.yml with variables
3. Add tasks/main.yml with implementation
4. Add molecule test scenario
5. Document in this file
