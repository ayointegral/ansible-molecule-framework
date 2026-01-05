# Fix All Molecule Test Failures

## Current Task

Fix all failing molecule tests in the Ansible Molecule Testing Framework project. The CI simulator shows 18 of 26 roles failing.

---

## Immediate Actions Required

### Step 1: Fix ANSIBLE_ALLOW_BROKEN_CONDITIONALS

Find ALL molecule.yml files missing this configuration and add it:

```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"
```

**Command to find missing files:**
```bash
for f in $(find roles -path "*/molecule/default/molecule.yml" -type f); do
  if ! grep -q "ANSIBLE_ALLOW_BROKEN_CONDITIONALS" "$f" 2>/dev/null; then
    echo "MISSING: $f"
  fi
done
```

### Step 2: Fix converge.yml Role Paths

Find and fix any converge.yml using `| basename`:

```bash
grep -r "| basename" roles/ --include="converge.yml"
```

Change from:
```yaml
- role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') | basename }}"
```

To:
```yaml
- role: "{{ lookup('env', 'MOLECULE_PROJECT_DIRECTORY') }}"
```

### Step 3: Fix meta/main.yml Structure

Find meta files with role_name/namespace at root level:

```bash
find roles -path "*/meta/main.yml" -type f -exec grep -l "^role_name:" {} \;
```

Move `role_name` and `namespace` inside the `galaxy_info` block.

### Step 4: Skip Windows Roles in CI

Windows roles (iis, windows_firewall, windows_features) use the `delegated` driver which requires a Windows host. These should be documented as expected failures and skipped in CI.

Update ERRORS.md to document this limitation.

### Step 5: Test Each Fixed Role

After fixing a role, test it:
```bash
cd roles/<category>/<role> && molecule test
```

### Step 6: Run Full Test Suite

After all fixes:
```bash
python3 ci/simulator.py --stage molecule
```

---

## Known Issues by Role

| Role | Issue | Fix Required |
|------|-------|--------------|
| common/base | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| common/packages | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| common/users | Missing env var or other | Investigate and fix |
| containers/docker | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| containers/podman | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| databases/postgresql | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| security/firewall | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| storage/nfs | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| storage/disk_management | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| storage/lvm | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| web/nginx | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| web/haproxy | Missing env var | Add ANSIBLE_ALLOW_BROKEN_CONDITIONALS |
| cloud/aws/ec2_simulation | Unknown | Investigate converge failure |
| monitoring/alertmanager | Unknown | Investigate converge failure |
| monitoring/node_exporter | Unknown | Investigate converge failure |
| windows/iis | Delegated driver | Document as Windows-only |
| windows/windows_firewall | Delegated driver | Document as Windows-only |
| windows/windows_features | Delegated driver | Document as Windows-only |

---

## Workflow Per Role Fix

1. Check molecule.yml has `ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "true"`
2. Check converge.yml uses full `MOLECULE_PROJECT_DIRECTORY` (no `| basename`)
3. Check meta/main.yml has role_name/namespace inside galaxy_info
4. Run `molecule test` to verify
5. If fails, read the error and fix accordingly
6. Update PROGRESS.md with result

---

## Files to Update

- **PROGRESS.md**: Log each fix and test result
- **ERRORS.md**: Document any persistent failures with root cause
- **CLAUDE.md**: Update if new patterns discovered

---

## Completion Criteria

The task is COMPLETE when:
- All 26 roles have correct molecule.yml configuration
- At least 20 roles pass molecule tests
- Windows roles (3) are documented as requiring Windows host
- ERRORS.md documents any remaining failures
- Full CI run shows mostly green

When ALL criteria are met, output: <promise>COMPLETE</promise>

---

## If Stuck

If a role keeps failing after multiple fix attempts:
1. Document the exact error in ERRORS.md
2. Note what was tried
3. Mark the role as "needs investigation" in PROGRESS.md
4. Move on to the next role
5. If more than 5 roles are stuck, output: <promise>NEEDS_HELP</promise>
