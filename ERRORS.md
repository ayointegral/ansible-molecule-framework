# Error Tracking

## Ansible Molecule Testing Framework

This document tracks errors encountered, their root causes, and resolutions.

---

## Template

```markdown
## [Date] - Error Title

### Context
What we were doing when this happened

### Error Message
```
Actual error output
```

### Root Cause
Why it happened

### Resolution
How we fixed it (or workaround)

### Prevention
How to avoid in future
```

---

## Error Log

## 2026-01-04 - Windows Roles Expected Failures

### Context
Windows roles (windows/iis, windows/windows_features, windows/windows_firewall) use the delegated driver which requires a Windows host with WinRM enabled.

### Error Message
```
Failed to find driver delegated
```

### Root Cause
Windows roles cannot be tested in Docker containers. They require:
1. A Windows host with WinRM enabled
2. Environment variables: WINDOWS_HOST, WINDOWS_USER, WINDOWS_PASSWORD

### Resolution
These roles are **expected to fail** in CI environments without Windows infrastructure. They should be:
- Skipped in automated CI pipelines
- Tested manually when Windows infrastructure is available

### Prevention
When adding Windows roles, always:
1. Use the delegated driver
2. Document Windows host requirements in the role README
3. Mark as expected failure in CI configuration

---

## 2026-01-04 - Ansible 2.19+ String Conditional Errors

### Context
Running molecule tests with Ansible 2.19+ on roles using molecule-docker playbooks.

### Error Message
```
Conditional result was derived from value of type 'str'. Conditionals must have a boolean result.
```

### Root Cause
molecule-docker internal playbooks use string conditionals like `when: (lookup('env', 'HOME'))` which Ansible 2.19+ rejects by default.

### Resolution
Add `ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"` to all molecule.yml files:

```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
```

### Prevention
Always include this environment variable in new molecule.yml files until molecule-docker is updated.

---

## 2026-01-04 - Role Not Found Error (basename)

### Context
Molecule test fails during converge phase with "role not found" error.

### Error Message
```
the role 'rolename' was not found
```

### Root Cause
Using `| basename` filter on `MOLECULE_PROJECT_DIRECTORY` in converge.yml strips the path.

### Resolution
Use full path in converge.yml:

```yaml
# CORRECT
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}"

# WRONG
roles:
  - role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') | basename }}"
```

### Prevention
Always use the full `MOLECULE_PROJECT_DIRECTORY` path without `| basename`.

---

## 2026-01-04 - Galaxy Role Name Validation Error

### Context
Molecule prerun fails with role name validation error.

### Error Message
```
Computed fully qualified role name does not follow galaxy requirements
```

### Root Cause
`role_name` and `namespace` placed at root level of meta/main.yml instead of inside `galaxy_info` block.

### Resolution
Move `role_name` and `namespace` inside `galaxy_info`:

```yaml
# CORRECT
galaxy_info:
  role_name: my_role
  namespace: my_namespace

# WRONG
galaxy_info:
  author: Someone
role_name: my_role
namespace: my_namespace
```

### Prevention
Always place role_name and namespace inside the galaxy_info block.

---

## 2026-01-04 - Reserved Variable Name Conflict (groups)

### Context
Role uses `groups` as a variable name which conflicts with Ansible's built-in magic variable.

### Error Message
```
The loop variable 'groups' is reserved
```
or unexpected behavior when iterating over groups.

### Root Cause
`groups` is a reserved Ansible magic variable that contains inventory group information.

### Resolution
Rename the variable to something like `user_groups`:

```yaml
# In defaults/main.yml
user_groups: []  # NOT groups: []

# In tasks/main.yml
loop: "{{ user_groups }}"  # NOT loop: "{{ groups }}"
```

### Prevention
Avoid using Ansible reserved variable names: `groups`, `hostvars`, `inventory_hostname`, `ansible_*`, etc.

---

## 2026-01-05 - UFW Idempotence Issue (SSH Port Conflict)

### Context
Running molecule idempotence test on security/firewall role with UFW backend fails.

### Error Message
```
Idempotence test failed because the following tasks reported changes:
- Open ports
- Apply SSH rate limiting
```

### Root Cause
The "Open ports" task adds port 22 with "allow" rule, then "Apply SSH rate limiting" task changes it to "limit" rule. On second run, this cycle repeats.

### Resolution
Skip port 22 in "Open ports" when SSH rate limiting is enabled:

```yaml
# In roles/security/firewall/tasks/ufw.yml
- name: Open ports
  community.general.ufw:
    rule: allow
    port: "{{ item.port | string }}"
    proto: "{{ item.protocol | default('tcp') }}"
  loop: "{{ firewall_open_ports | selectattr('port', 'ne', 22) | list if (firewall_ssh_rate_limit | bool) else firewall_open_ports }}"
```

### Prevention
When using rate limiting or special rules for specific ports, exclude those ports from generic "open ports" tasks.
