# Windows Role Testing Guide

This document explains how to test Ansible roles that target Windows hosts.

## Overview

Windows roles in this project use Ansible's WinRM connection to manage Windows hosts. Unlike Linux roles that use Docker containers, Windows roles require actual Windows infrastructure.

## Architecture Limitations

### Windows Server and ARM

**Windows Server does NOT support ARM architecture.**

Microsoft only provides x86_64 (x64) versions of Windows Server. This has important implications:

| Platform | Native Windows Server | Emulated (QEMU) | Recommended |
|----------|----------------------|-----------------|-------------|
| Intel Mac (x86_64) | VirtualBox, VMware | N/A | VirtualBox |
| Apple Silicon (M1-M4) | Not possible | Very slow (30-60+ min) | Delegated |
| Linux x86_64 | KVM, VirtualBox | N/A | KVM |
| Linux ARM64 | Not possible | Very slow | Delegated |

**Note:** Windows 11 (consumer) has ARM support, but Windows Server does not.

## Testing Scenarios

Each Windows role has multiple molecule scenarios:

### 1. Default Scenario (VirtualBox)
**Best for:** Intel Mac, Linux x86_64

```bash
cd roles/windows/iis
molecule test
```

Requires VirtualBox installed.

### 2. QEMU Scenario
**Best for:** Cross-platform testing

```bash
cd roles/windows/iis
molecule test -s qemu
```

On ARM systems, QEMU emulates x86_64 which is very slow. Not recommended for regular testing.

### 3. Delegated Scenario (Recommended for ARM)
**Best for:** Apple Silicon Macs, ARM Linux, CI/CD

Uses an existing Windows host via WinRM.

```bash
# Set connection details
export WINDOWS_HOST=192.168.1.100
export WINDOWS_USER=Administrator
export WINDOWS_PASSWORD=YourPassword

# Run tests
cd roles/windows/iis
molecule test -s delegated
```

## Setting Up a Windows Host

### Option 1: Azure VM (Recommended for CI/CD)

```bash
# Create a Windows Server VM
az vm create \
  --resource-group myResourceGroup \
  --name windows-test \
  --image Win2022Datacenter \
  --admin-username Administrator \
  --admin-password 'YourSecurePassword123!' \
  --size Standard_D2s_v3

# Enable WinRM
az vm run-command invoke \
  --resource-group myResourceGroup \
  --name windows-test \
  --command-id EnableRemotePS
```

### Option 2: AWS EC2

```bash
# Create a Windows Server instance
aws ec2 run-instances \
  --image-id ami-0abcd1234efgh5678 \  # Windows Server 2022 AMI
  --instance-type t3.medium \
  --key-name your-key \
  --security-group-ids sg-12345678

# Configure WinRM via user-data or SSM
```

### Option 3: Local VM (Intel Mac)

Use VirtualBox or VMware to create a Windows Server VM:

1. Download Windows Server 2022 Evaluation ISO
2. Create VM with 4GB RAM, 50GB disk
3. Install Windows Server
4. Enable WinRM (see below)

### Option 4: Parallels/UTM (Apple Silicon)

For Apple Silicon Macs, you can run Windows 11 ARM (not Server):

1. Download Windows 11 ARM ISO from Microsoft
2. Create VM in Parallels or UTM
3. Install Windows 11
4. Enable WinRM

**Note:** Windows 11 lacks some Server features but works for basic testing.

## Enabling WinRM on Windows

Run these PowerShell commands as Administrator on the Windows host:

```powershell
# Enable WinRM
Enable-PSRemoting -Force

# Configure WinRM for Ansible
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Configure firewall
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" `
  -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow

# For HTTPS (recommended for production)
$cert = New-SelfSignedCertificate -DnsName $(hostname) -CertStoreLocation Cert:\LocalMachine\My
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$(hostname)`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"

New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" `
  -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

## Testing Commands

### Using the Helper Script

The helper script auto-detects your system and selects the best provider:

```bash
# Test a Windows role
./scripts/windows-molecule-test.sh roles/windows/iis test

# Just converge (for debugging)
./scripts/windows-molecule-test.sh roles/windows/iis converge

# Syntax check only
./scripts/windows-molecule-test.sh roles/windows/iis syntax
```

### Using Make Targets

```bash
# Check prerequisites
make windows-check

# Install QEMU and Vagrant plugins
make windows-setup

# Test all Windows roles
make windows-test

# Test specific role
make windows-test-role ROLE=windows/iis
```

### Direct Molecule Commands

```bash
# Default scenario (VirtualBox)
cd roles/windows/iis && molecule test

# QEMU scenario
cd roles/windows/iis && molecule test -s qemu

# Delegated scenario
export WINDOWS_HOST=192.168.1.100
export WINDOWS_USER=Administrator
export WINDOWS_PASSWORD=YourPassword
cd roles/windows/iis && molecule test -s delegated
```

## Environment Variables

| Variable | Description | Required For |
|----------|-------------|--------------|
| `WINDOWS_HOST` | IP or hostname of Windows target | delegated |
| `WINDOWS_USER` | Username (usually Administrator) | delegated |
| `WINDOWS_PASSWORD` | Password for the user | delegated |
| `WINDOWS_PORT` | WinRM port (default: 5985) | delegated (optional) |
| `VAGRANT_DEFAULT_PROVIDER` | Force Vagrant provider | default, qemu |

## Troubleshooting

### WinRM Connection Failed

1. Verify the Windows host is reachable:
   ```bash
   ping $WINDOWS_HOST
   ```

2. Test WinRM connection:
   ```bash
   python -c "import winrm; s = winrm.Session('$WINDOWS_HOST', auth=('$WINDOWS_USER', '$WINDOWS_PASSWORD')); print(s.run_cmd('hostname'))"
   ```

3. Check Windows firewall allows WinRM (TCP 5985/5986)

### QEMU Too Slow

QEMU x86 emulation on ARM is inherently slow. Options:

1. Use delegated scenario with a remote Windows host
2. Use a cloud Windows VM
3. Only run syntax checks locally, full tests in CI

### Vagrant Box Not Found

Windows Vagrant boxes are large (~10GB). Download may take time:

```bash
# Pre-download the box
vagrant box add gusztavvargadr/windows-server-2022-standard
```

## CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
# Example GitHub Actions workflow
windows-test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install molecule ansible pywinrm
    
    - name: Test Windows roles
      env:
        WINDOWS_HOST: ${{ secrets.WINDOWS_HOST }}
        WINDOWS_USER: ${{ secrets.WINDOWS_USER }}
        WINDOWS_PASSWORD: ${{ secrets.WINDOWS_PASSWORD }}
      run: |
        cd roles/windows/iis
        molecule test -s delegated
```

## Windows Roles in This Project

| Role | Description |
|------|-------------|
| `windows/iis` | Install and configure IIS web server |
| `windows/windows_features` | Manage Windows features |
| `windows/windows_firewall` | Configure Windows Firewall rules |

## See Also

- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html)
- [WinRM Configuration](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html)
- [Molecule Documentation](https://molecule.readthedocs.io/)
