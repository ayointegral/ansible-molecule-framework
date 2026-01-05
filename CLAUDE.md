# Ansible Molecule Testing Framework - AI Instructions

## Project Context

This is a production-grade Ansible testing infrastructure with:
- 26 roles with molecule tests
- 15 environment inventories (7 live + 7 test + 1 shared)
- Docker and Podman testing scenarios
- Windows role documentation (requires Windows host)
- CI/CD pipeline simulator

## Critical Configuration

### Ansible 2.19+ Compatibility

All molecule.yml files MUST include this environment variable in the provisioner section:

```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
```

This is required because molecule-docker playbooks use string conditionals that Ansible 2.19+ rejects by default.

### Role Path in converge.yml

All converge.yml files MUST use the full path, NOT basename:

```yaml
# CORRECT
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}"

# WRONG - will fail
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') | basename }}"
```

### meta/main.yml Structure

The `role_name` and `namespace` MUST be inside `galaxy_info`:

```yaml
# CORRECT
galaxy_info:
  author: Ansible Molecule Testing
  role_name: my_role
  namespace: my_namespace
  # ... other fields

# WRONG - will fail molecule prerun
galaxy_info:
  author: Ansible Molecule Testing
  # ... other fields
role_name: my_role
namespace: my_namespace
```

## Windows Roles

Windows roles use the `delegated` driver which requires:
1. A Windows host with WinRM enabled
2. Environment variables: WINDOWS_HOST, WINDOWS_USER, WINDOWS_PASSWORD

These roles will FAIL in CI without a Windows host. They should be:
- Skipped in automated CI pipelines
- Documented as requiring Windows host
- Tested manually when Windows infrastructure is available

## Common Errors and Fixes

### Error: "Conditional result was derived from value of type 'str'"
**Fix**: Add `ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"` to molecule.yml provisioner env

### Error: "the role 'rolename' was not found"
**Fix**: Use full `MOLECULE_PROJECT_DIRECTORY` path, not `| basename`

### Error: "Computed fully qualified role name does not follow galaxy requirements"
**Fix**: Move `role_name` and `namespace` inside `galaxy_info` block in meta/main.yml

### Error: "Failed to find driver delegated"
**Fix**: This is for Windows roles - skip in CI or ensure delegated driver is available

### Error: "No package matching 'X' is available"
**Fix**: Add apt cache update before package installation:
```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600
  when: ansible_os_family == 'Debian'
```

## Testing Commands

```bash
# Test a single role
cd roles/common/base && molecule test

# Test all roles via CI simulator
python3 ci/simulator.py --stage molecule

# List all roles with molecule tests
python3 ci/simulator.py --list-roles

# Run with verbose output
cd roles/common/base && molecule --debug test
```

## File Locations

- Roles: `roles/<category>/<role>/`
- Molecule configs: `roles/<category>/<role>/molecule/default/`
- CI Simulator: `ci/simulator.py`
- Progress tracking: `PROGRESS.md`
- Error tracking: `ERRORS.md`
- Research notes: `RESEARCH.md`

## Completion Criteria

The project is COMPLETE when:
- [x] All 15 environment inventories created
- [x] At least 15 roles implemented with molecule tests (26 roles exist)
- [x] Docker scenario working
- [x] Podman scenario configured
- [x] Windows scenario documented with limitations
- [x] CI/CD simulator runs all tests
- [x] README.md has full documentation
- [ ] All molecule tests pass (or failures documented in ERRORS.md)

## Current Status

- **26 roles** with molecule test configurations
- **18 roles failing** due to missing ANSIBLE_ALLOW_BROKEN_CONDITIONALS
- **3 Windows roles** expected to fail (require Windows host)
- **5 roles** need investigation for other issues

## Priority Fixes Needed

1. Add `ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"` to ALL molecule.yml files
2. Fix any converge.yml files using `| basename`
3. Fix any meta/main.yml files with role_name/namespace at root level
4. Document Windows role limitations in ERRORS.md
5. Run full molecule test suite and fix remaining issues
