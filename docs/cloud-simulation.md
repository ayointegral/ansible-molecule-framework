# Cloud Infrastructure Simulation

This document describes the free cloud emulators/simulators available for molecule testing.

## Overview

All cloud simulations use the **sidecar container pattern** - a real emulator runs alongside your test instance, allowing realistic integration testing without cloud costs.

## Available Emulators

| Cloud | Service | Emulator | Image | Port |
|-------|---------|----------|-------|------|
| AWS | S3, SQS, SNS, DynamoDB, Lambda, IAM, etc. | LocalStack | `localstack/localstack` | 4566 |
| AWS | S3 only | MinIO | `minio/minio` | 9000 |
| Azure | Blob, Queue, Table Storage | Azurite | `mcr.microsoft.com/azure-storage/azurite` | 10000-10002 |
| GCP | Cloud Storage | fake-gcs-server | `fsouza/fake-gcs-server` | 4443 |
| GCP | Pub/Sub | Pub/Sub Emulator | `google/cloud-sdk:emulators` | 8085 |
| Secrets | Vault | HashiCorp Vault | `hashicorp/vault` | 8200 |
| Service Discovery | Consul | HashiCorp Consul | `hashicorp/consul` | 8500 |

## AWS Simulation

### LocalStack (Comprehensive)

LocalStack provides a full AWS cloud stack for local development and testing.

**Supported Services (Free Tier):**
- S3 (Object Storage)
- SQS (Message Queues)
- SNS (Notifications)
- DynamoDB (NoSQL Database)
- Lambda (Serverless Functions)
- IAM (Identity Management)
- CloudWatch (Monitoring)
- Secrets Manager
- SSM Parameter Store
- And many more...

**Usage:**
```bash
cd roles/cloud/aws/localstack
molecule test
```

**Scenario:** `roles/cloud/aws/localstack/molecule/default/`

### MinIO (S3 Only)

For simpler S3-only testing, MinIO is lighter weight.

**Usage:**
```bash
cd roles/cloud/aws/s3
molecule test -s minio
```

**Scenario:** `roles/cloud/aws/s3/molecule/minio/`

## Azure Simulation

### Azurite (Storage)

Official Microsoft Azure Storage emulator.

**Supported Services:**
- Blob Storage
- Queue Storage
- Table Storage

**Connection String:**
```
DefaultEndpointsProtocol=http;
AccountName=devstoreaccount1;
AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;
BlobEndpoint=http://azurite:10000/devstoreaccount1;
QueueEndpoint=http://azurite:10001/devstoreaccount1;
TableEndpoint=http://azurite:10002/devstoreaccount1
```

**Usage:**
```bash
cd roles/cloud/azure/storage_account
molecule test -s azurite
```

**Scenario:** `roles/cloud/azure/storage_account/molecule/azurite/`

## GCP Simulation

### fake-gcs-server (Cloud Storage)

Emulates Google Cloud Storage API.

**Usage:**
```bash
cd roles/cloud/gcp/gcs
molecule test -s fakegcs
```

**Environment:**
```bash
export STORAGE_EMULATOR_HOST=http://fake-gcs:4443
```

**Scenario:** `roles/cloud/gcp/gcs/molecule/fakegcs/`

### Pub/Sub Emulator

Official Google Cloud Pub/Sub emulator.

**Usage:**
```bash
cd roles/cloud/gcp/pubsub
molecule test
```

**Environment:**
```bash
export PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
```

**Scenario:** `roles/cloud/gcp/pubsub/molecule/default/`

## Secrets Management

### HashiCorp Vault

Vault provides secrets management, encryption, and access control.

**Features Tested:**
- KV secrets engine (v2)
- Secrets CRUD operations
- Policies
- Dynamic secrets (database, AWS, etc.)

**Usage:**
```bash
cd roles/cloud/vault
molecule test
```

**Dev Mode Credentials:**
- Address: `http://vault:8200`
- Token: `root`

**Scenario:** `roles/cloud/vault/molecule/default/`

## Service Discovery

### HashiCorp Consul

Consul provides service discovery, health checking, and KV store.

**Features Tested:**
- Service registration
- Health checks
- KV store operations
- DNS-based service discovery

**Usage:**
```bash
cd roles/cloud/consul
molecule test
```

**Scenario:** `roles/cloud/consul/molecule/default/`

## Molecule Configuration Pattern

All cloud emulator scenarios follow this pattern in `molecule.yml`:

```yaml
platforms:
  # Main test instance
  - name: test-instance
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    networks:
      - name: emulator-network

  # Emulator sidecar
  - name: emulator-name
    image: emulator/image:latest
    pre_build_image: true
    command: "emulator start command"
    exposed_ports:
      - PORT/tcp
    networks:
      - name: emulator-network
```

## Python SDK Dependencies

Each scenario installs the appropriate SDK in `prepare.yml`:

| Cloud | Python Package |
|-------|---------------|
| AWS | `boto3`, `botocore` |
| Azure | `azure-storage-blob`, `azure-storage-queue`, `azure-data-tables` |
| GCP Storage | `google-cloud-storage` |
| GCP Pub/Sub | `google-cloud-pubsub` |
| Vault | `hvac` |
| Consul | `python-consul` |

## Testing All Cloud Scenarios

```bash
# Test all cloud roles
python3 ci/simulator.py --stage molecule --role cloud/aws/localstack
python3 ci/simulator.py --stage molecule --role cloud/aws/s3
python3 ci/simulator.py --stage molecule --role cloud/azure/storage_account
python3 ci/simulator.py --stage molecule --role cloud/gcp/gcs
python3 ci/simulator.py --stage molecule --role cloud/gcp/pubsub
python3 ci/simulator.py --stage molecule --role cloud/vault
python3 ci/simulator.py --stage molecule --role cloud/consul
```

## Limitations

1. **LocalStack Free Tier**: Some advanced features require Pro license
2. **Azure**: Only storage services available (no Compute, KeyVault simulation)
3. **GCP**: Limited to Storage and Pub/Sub emulators
4. **Network**: All containers must be on the same Docker network

## Adding New Emulators

To add a new cloud emulator:

1. Create scenario directory: `roles/cloud/<provider>/<service>/molecule/<scenario>/`
2. Add `molecule.yml` with sidecar container
3. Add `prepare.yml` to wait for emulator and install SDK
4. Add `converge.yml` with test operations
5. Add `verify.yml` to validate operations
6. Update this documentation
