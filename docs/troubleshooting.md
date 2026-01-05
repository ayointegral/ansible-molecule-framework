# Troubleshooting Guide

## Ansible Molecule Testing Framework

This document provides solutions to common issues encountered during development and testing.

---

## Table of Contents

1. [Molecule Issues](#molecule-issues)
2. [Docker Issues](#docker-issues)
3. [Podman Issues](#podman-issues)
4. [Windows Container Limitations](#windows-container-limitations)
5. [Ansible Issues](#ansible-issues)
6. [CI Pipeline Issues](#ci-pipeline-issues)

---

## Molecule Issues

### Role path not found

**Error:**
```
ERROR! the role 'xxx' was not found
```

**Solution:**
Use the full path in converge.yml:
```yaml
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}"
```

### Conditional deprecation warnings

**Error:**
```
ANSIBLE_ALLOW_BROKEN_CONDITIONALS is deprecated
```

**Solution:**
Set in molecule.yml provisioner config:
```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
```

### Idempotence test failures

**Cause:** Tasks are not idempotent (running twice produces changes).

**Solution:**
- Use `changed_when` for commands that always report changes
- Check if files/packages exist before creating them
- Use `creates` or `removes` parameters where applicable

---

## Docker Issues

### Systemd not working in containers

**Error:**
```
Failed to get D-Bus connection
```

**Solution:**
Use systemd-enabled images with proper configuration:
```yaml
platforms:
  - name: ubuntu-22.04
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
    privileged: true
    command: ""
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
```

### Docker-in-Docker (DinD) not working

**Limitation:** Docker cannot run inside Docker containers without special configuration.

**Workaround:** 
- Install Docker packages but skip service start
- Use `check_mode` for verification
- Mock Docker operations in tests

---

## Podman Issues

### Podman not found

**Error:**
```
Error: Cannot find molecule-podman driver
```

**Solution:**
```bash
pip install molecule-podman
```

### Rootless Podman issues

**Error:** Permission denied for cgroup or systemd.

**Solution:**
Run podman in rootful mode or configure cgroupv2:
```bash
podman machine set --rootful
```

---

## Windows Container Limitations

### Critical Information

**Windows containers have significant limitations that affect testing:**

1. **Host Requirements:**
   - Windows containers ONLY run on Windows hosts
   - Requires Docker Desktop with Windows container mode
   - Linux/macOS hosts CANNOT run Windows containers natively

2. **Hyper-V Required:**
   - Windows Server Core containers require Hyper-V or WSL2 backend
   - Nested virtualization required in VMs

3. **Image Size:**
   - Windows Server Core images are 4-5GB+
   - Significantly longer pull times

4. **Ansible Connection:**
   - Requires WinRM or SSH (Windows OpenSSH)
   - Different connection plugins needed

5. **Module Compatibility:**
   - Many Linux Ansible modules don't work on Windows
   - Use `win_*` modules instead:
     - `ansible.windows.win_feature` instead of `package`
     - `ansible.windows.win_service` instead of `service`
     - `ansible.windows.win_firewall_rule` instead of `ufw`

### Tested Windows Roles

The following Windows roles have been created but testing is limited:

| Role | Status | Notes |
|------|--------|-------|
| windows/iis | Created | Requires Windows host for testing |
| windows/windows_firewall | Created | Requires Windows host for testing |
| windows/windows_features | Created | Requires Windows host for testing |

### Alternative Testing Approaches

1. **Use Windows VM:**
   - Set up Windows Server VM with Docker
   - Run molecule tests from VM

2. **Use GitHub Actions:**
   - GitHub provides Windows runners
   - Configure CI to run Windows tests on Windows runners

3. **Mock Testing:**
   - Create mock scenarios that verify task structure
   - Skip actual execution in containers

### Example Windows CI Configuration (GitHub Actions)

```yaml
name: Windows Tests
on: [push, pull_request]
jobs:
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install ansible molecule molecule-docker
      - name: Run Windows molecule tests
        run: |
          cd roles/windows/iis
          molecule test
```

---

## Ansible Issues

### Galaxy collection not found

**Error:**
```
ERROR! couldn't resolve module/action 'community.general.xxx'
```

**Solution:**
```bash
ansible-galaxy collection install -r requirements.yml
```

### Variable undefined

**Error:**
```
'variable' is undefined
```

**Solution:**
- Check vars files are included
- Verify variable name spelling
- Use `default()` filter for optional variables

### Handler not running

**Issue:** Handler is notified but doesn't execute.

**Solution:**
- Flush handlers before dependent tasks:
```yaml
- name: Flush handlers
  ansible.builtin.meta: flush_handlers
```

---

## CI Pipeline Issues

### Simulator times out

**Error:**
```
Command timed out after 600 seconds
```

**Solution:**
- Increase timeout in molecule.yml
- Check for network issues during package downloads
- Use pre-built images

### Parallel test failures

**Issue:** Tests fail when run in parallel but pass individually.

**Cause:** Resource contention, port conflicts, or shared state.

**Solution:**
- Use unique network names per test
- Use different ports in parallel tests
- Run resource-intensive tests sequentially

### Report generation fails

**Solution:**
Ensure ci/reports directory exists:
```bash
mkdir -p ci/reports
```

---

## Common Error Messages Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `apt cache update failed` | Network issue | Add retry with delay |
| `service not found` | Service not installed | Check package installation |
| `permission denied` | Missing privileges | Add `become: true` |
| `file not found` | Path doesn't exist | Use `creates` parameter |
| `timeout` | Slow network/system | Increase timeouts |

---

## Getting Help

1. Check the [Molecule documentation](https://molecule.readthedocs.io/)
2. Check the [Ansible documentation](https://docs.ansible.com/)
3. Review ERRORS.md for recorded issues and resolutions
4. Open an issue on the project repository
