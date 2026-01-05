#!/usr/bin/env python3
"""
CI Pipeline Simulator for Ansible Molecule Testing Framework

This simulator mimics a real CI/CD pipeline by running various stages
of testing and validation locally. It supports parallel execution,
reporting, and can simulate different CI environments.

Usage:
    python ci/simulator.py [OPTIONS]

Options:
    --stage STAGE       Run specific stage (lint, syntax, unit, molecule, all)
    --role ROLE         Run tests for specific role (e.g., common/base)
    --parallel N        Number of parallel jobs (default: 4)
    --env ENV           Environment to simulate (dev, staging, prod)
    --report FORMAT     Generate report (json, html, junit)
    --verbose           Enable verbose output
    --dry-run           Show what would be run without executing
"""

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field, asdict
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Optional


class StageStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    PASSED = "passed"
    FAILED = "failed"
    SKIPPED = "skipped"


@dataclass
class StageResult:
    name: str
    status: StageStatus
    duration: float = 0.0
    output: str = ""
    error: str = ""
    command: str = ""
    role: str = ""


@dataclass
class PipelineResult:
    start_time: str
    end_time: str = ""
    total_duration: float = 0.0
    stages: list = field(default_factory=list)
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    overall_status: str = "pending"


class Colors:
    """ANSI color codes for terminal output."""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def colorize(text: str, color: str) -> str:
    """Add color to text if terminal supports it."""
    if sys.stdout.isatty():
        return f"{color}{text}{Colors.ENDC}"
    return text


class CIPipeline:
    """Main CI Pipeline Simulator class."""

    def __init__(self, project_root: Path, verbose: bool = False, dry_run: bool = False):
        self.project_root = project_root
        self.roles_dir = project_root / "roles"
        self.verbose = verbose
        self.dry_run = dry_run
        self.results = PipelineResult(start_time=datetime.now().isoformat())

    def discover_roles(self) -> list:
        """Discover all roles with molecule tests (supports up to 3 levels)."""
        roles = []
        for category in self.roles_dir.iterdir():
            if category.is_dir() and not category.name.startswith('.'):
                for role in category.iterdir():
                    if role.is_dir():
                        molecule_dir = role / "molecule" / "default"
                        if molecule_dir.exists():
                            roles.append(f"{category.name}/{role.name}")
                        else:
                            # Check for 3rd level (e.g., cloud/aws/s3)
                            for subrole in role.iterdir():
                                if subrole.is_dir():
                                    sub_molecule_dir = subrole / "molecule" / "default"
                                    if sub_molecule_dir.exists():
                                        roles.append(f"{category.name}/{role.name}/{subrole.name}")
        return sorted(roles)

    def run_command(self, command: str, cwd: Path = None, env: dict = None) -> tuple:
        """Execute a shell command and return output."""
        if self.dry_run:
            return 0, f"[DRY RUN] Would execute: {command}", ""

        full_env = os.environ.copy()
        if env:
            full_env.update(env)

        try:
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd or self.project_root,
                capture_output=True,
                text=True,
                env=full_env,
                timeout=600  # 10 minute timeout
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", "Command timed out after 600 seconds"
        except Exception as e:
            return 1, "", str(e)

    def run_lint(self, role: str = None) -> StageResult:
        """Run YAML and Ansible linting."""
        start = time.time()
        name = f"lint:{role}" if role else "lint:all"

        if role:
            role_path = self.roles_dir / role.replace('/', '/')
            cmd = f"yamllint -c .yamllint.yml {role_path}"
        else:
            cmd = "yamllint -c .yamllint.yml roles/"

        returncode, stdout, stderr = self.run_command(cmd)
        status = StageStatus.PASSED if returncode == 0 else StageStatus.FAILED

        # Also run ansible-lint if available
        if role:
            lint_cmd = f"ansible-lint {self.roles_dir / role.replace('/', '/')}"
        else:
            lint_cmd = "ansible-lint roles/"

        lint_rc, lint_out, lint_err = self.run_command(lint_cmd)
        if lint_rc != 0:
            status = StageStatus.FAILED
            stdout += f"\n\nAnsible-lint output:\n{lint_out}"
            stderr += lint_err

        return StageResult(
            name=name,
            status=status,
            duration=time.time() - start,
            output=stdout,
            error=stderr,
            command=cmd,
            role=role or "all"
        )

    def run_syntax(self, role: str = None) -> StageResult:
        """Run Ansible syntax check."""
        start = time.time()
        name = f"syntax:{role}" if role else "syntax:all"

        if role:
            role_path = self.roles_dir / role.replace('/', '/')
            converge = role_path / "molecule" / "default" / "converge.yml"
            if converge.exists():
                cmd = f"ansible-playbook --syntax-check {converge}"
            else:
                return StageResult(
                    name=name,
                    status=StageStatus.SKIPPED,
                    duration=0,
                    output="No converge.yml found",
                    role=role
                )
        else:
            # Check all playbooks
            cmd = "find playbooks -name '*.yml' -exec ansible-playbook --syntax-check {} \\;"

        returncode, stdout, stderr = self.run_command(cmd)
        status = StageStatus.PASSED if returncode == 0 else StageStatus.FAILED

        return StageResult(
            name=name,
            status=status,
            duration=time.time() - start,
            output=stdout,
            error=stderr,
            command=cmd,
            role=role or "all"
        )

    def run_molecule(self, role: str, scenario: str = "default") -> StageResult:
        """Run Molecule tests for a role."""
        start = time.time()
        name = f"molecule:{role}:{scenario}"

        role_path = self.roles_dir / role.replace('/', '/')
        cmd = f"molecule test -s {scenario}"

        returncode, stdout, stderr = self.run_command(cmd, cwd=role_path)
        status = StageStatus.PASSED if returncode == 0 else StageStatus.FAILED

        return StageResult(
            name=name,
            status=status,
            duration=time.time() - start,
            output=stdout,
            error=stderr,
            command=cmd,
            role=role
        )

    def run_stage(self, stage: str, role: str = None, parallel: int = 4) -> list:
        """Run a specific stage of the pipeline."""
        results = []

        if stage == "lint":
            if role:
                results.append(self.run_lint(role))
            else:
                roles = self.discover_roles()
                with ThreadPoolExecutor(max_workers=parallel) as executor:
                    futures = {executor.submit(self.run_lint, r): r for r in roles}
                    for future in as_completed(futures):
                        results.append(future.result())

        elif stage == "syntax":
            if role:
                results.append(self.run_syntax(role))
            else:
                roles = self.discover_roles()
                with ThreadPoolExecutor(max_workers=parallel) as executor:
                    futures = {executor.submit(self.run_syntax, r): r for r in roles}
                    for future in as_completed(futures):
                        results.append(future.result())

        elif stage == "molecule":
            if role:
                results.append(self.run_molecule(role))
            else:
                roles = self.discover_roles()
                # Run molecule tests sequentially by default (resource intensive)
                for r in roles:
                    results.append(self.run_molecule(r))

        elif stage == "all":
            # Run all stages in order
            for s in ["lint", "syntax", "molecule"]:
                stage_results = self.run_stage(s, role, parallel)
                results.extend(stage_results)
                # Stop if any stage fails
                if any(r.status == StageStatus.FAILED for r in stage_results):
                    break

        return results

    def print_result(self, result: StageResult):
        """Print a single stage result."""
        if result.status == StageStatus.PASSED:
            status_str = colorize("PASSED", Colors.GREEN)
        elif result.status == StageStatus.FAILED:
            status_str = colorize("FAILED", Colors.RED)
        elif result.status == StageStatus.SKIPPED:
            status_str = colorize("SKIPPED", Colors.WARNING)
        else:
            status_str = colorize("RUNNING", Colors.BLUE)

        print(f"  [{status_str}] {result.name} ({result.duration:.2f}s)")

        if self.verbose and result.output:
            print(f"    Output: {result.output[:200]}...")
        if result.status == StageStatus.FAILED and result.error:
            print(f"    {colorize('Error:', Colors.RED)} {result.error[:200]}...")

    def print_summary(self):
        """Print pipeline execution summary."""
        print("\n" + "=" * 60)
        print(colorize("Pipeline Summary", Colors.BOLD))
        print("=" * 60)

        passed = sum(1 for r in self.results.stages if r.status == StageStatus.PASSED)
        failed = sum(1 for r in self.results.stages if r.status == StageStatus.FAILED)
        skipped = sum(1 for r in self.results.stages if r.status == StageStatus.SKIPPED)

        print(f"  Total stages: {len(self.results.stages)}")
        print(f"  {colorize('Passed:', Colors.GREEN)} {passed}")
        print(f"  {colorize('Failed:', Colors.RED)} {failed}")
        print(f"  {colorize('Skipped:', Colors.WARNING)} {skipped}")
        print(f"  Duration: {self.results.total_duration:.2f}s")

        if failed == 0:
            print(f"\n{colorize('Pipeline PASSED', Colors.GREEN)}")
        else:
            print(f"\n{colorize('Pipeline FAILED', Colors.RED)}")

        self.results.passed = passed
        self.results.failed = failed
        self.results.skipped = skipped
        self.results.overall_status = "passed" if failed == 0 else "failed"

    def generate_report(self, format: str, output_path: Path = None):
        """Generate a report in the specified format."""
        if output_path is None:
            output_path = self.project_root / "ci" / "reports"
        output_path.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        if format == "json":
            report_file = output_path / f"report_{timestamp}.json"
            report_data = {
                "start_time": self.results.start_time,
                "end_time": self.results.end_time,
                "total_duration": self.results.total_duration,
                "passed": self.results.passed,
                "failed": self.results.failed,
                "skipped": self.results.skipped,
                "overall_status": self.results.overall_status,
                "stages": [
                    {
                        "name": s.name,
                        "status": s.status.value,
                        "duration": s.duration,
                        "role": s.role,
                        "command": s.command,
                        "output": s.output[:500] if s.output else "",
                        "error": s.error[:500] if s.error else ""
                    }
                    for s in self.results.stages
                ]
            }
            with open(report_file, 'w') as f:
                json.dump(report_data, f, indent=2)
            print(f"\nJSON report saved to: {report_file}")

        elif format == "junit":
            report_file = output_path / f"junit_{timestamp}.xml"
            xml_content = self._generate_junit_xml()
            with open(report_file, 'w') as f:
                f.write(xml_content)
            print(f"\nJUnit report saved to: {report_file}")

        elif format == "html":
            report_file = output_path / f"report_{timestamp}.html"
            html_content = self._generate_html_report()
            with open(report_file, 'w') as f:
                f.write(html_content)
            print(f"\nHTML report saved to: {report_file}")

    def _generate_junit_xml(self) -> str:
        """Generate JUnit XML format report."""
        tests = len(self.results.stages)
        failures = self.results.failed
        time_total = self.results.total_duration

        xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="ansible-molecule-pipeline" tests="{tests}" failures="{failures}" time="{time_total:.2f}">
'''
        for stage in self.results.stages:
            xml += f'  <testcase name="{stage.name}" time="{stage.duration:.2f}">\n'
            if stage.status == StageStatus.FAILED:
                xml += f'    <failure message="Stage failed">{stage.error}</failure>\n'
            elif stage.status == StageStatus.SKIPPED:
                xml += '    <skipped/>\n'
            xml += '  </testcase>\n'

        xml += '</testsuite>\n'
        return xml

    def _generate_html_report(self) -> str:
        """Generate HTML format report."""
        return f'''<!DOCTYPE html>
<html>
<head>
    <title>CI Pipeline Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .passed {{ color: green; }}
        .failed {{ color: red; }}
        .skipped {{ color: orange; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        th {{ background-color: #4CAF50; color: white; }}
        tr:nth-child(even) {{ background-color: #f2f2f2; }}
        .summary {{ margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 5px; }}
    </style>
</head>
<body>
    <h1>CI Pipeline Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Start Time: {self.results.start_time}</p>
        <p>End Time: {self.results.end_time}</p>
        <p>Duration: {self.results.total_duration:.2f}s</p>
        <p class="passed">Passed: {self.results.passed}</p>
        <p class="failed">Failed: {self.results.failed}</p>
        <p class="skipped">Skipped: {self.results.skipped}</p>
        <p><strong>Overall Status: <span class="{self.results.overall_status}">{self.results.overall_status.upper()}</span></strong></p>
    </div>
    <h2>Stage Results</h2>
    <table>
        <tr>
            <th>Stage</th>
            <th>Role</th>
            <th>Status</th>
            <th>Duration</th>
        </tr>
        {''.join(f"<tr><td>{s.name}</td><td>{s.role}</td><td class='{s.status.value}'>{s.status.value.upper()}</td><td>{s.duration:.2f}s</td></tr>" for s in self.results.stages)}
    </table>
</body>
</html>'''


def main():
    parser = argparse.ArgumentParser(
        description="CI Pipeline Simulator for Ansible Molecule Testing"
    )
    parser.add_argument(
        "--stage", "-s",
        choices=["lint", "syntax", "molecule", "all"],
        default="all",
        help="Stage to run (default: all)"
    )
    parser.add_argument(
        "--role", "-r",
        help="Specific role to test (e.g., common/base)"
    )
    parser.add_argument(
        "--parallel", "-p",
        type=int,
        default=4,
        help="Number of parallel jobs (default: 4)"
    )
    parser.add_argument(
        "--report",
        choices=["json", "html", "junit"],
        help="Generate report in specified format"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be run without executing"
    )
    parser.add_argument(
        "--list-roles",
        action="store_true",
        help="List all roles with molecule tests and exit"
    )

    args = parser.parse_args()

    # Find project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # Initialize pipeline
    pipeline = CIPipeline(
        project_root=project_root,
        verbose=args.verbose,
        dry_run=args.dry_run
    )

    # List roles if requested
    if args.list_roles:
        roles = pipeline.discover_roles()
        print(f"Found {len(roles)} roles with molecule tests:")
        for role in roles:
            print(f"  - {role}")
        sys.exit(0)

    # Print header
    print(colorize("=" * 60, Colors.BOLD))
    print(colorize("  Ansible Molecule CI Pipeline Simulator", Colors.BOLD))
    print(colorize("=" * 60, Colors.BOLD))
    print(f"  Stage: {args.stage}")
    print(f"  Role: {args.role or 'all'}")
    print(f"  Parallel jobs: {args.parallel}")
    if args.dry_run:
        print(colorize("  [DRY RUN MODE]", Colors.WARNING))
    print()

    # Run pipeline
    start_time = time.time()

    try:
        results = pipeline.run_stage(args.stage, args.role, args.parallel)
        pipeline.results.stages = results

        # Print results
        print(colorize("\nStage Results:", Colors.BOLD))
        for result in results:
            pipeline.print_result(result)

    except KeyboardInterrupt:
        print(colorize("\n\nPipeline interrupted by user", Colors.WARNING))
        sys.exit(130)

    # Finalize
    pipeline.results.end_time = datetime.now().isoformat()
    pipeline.results.total_duration = time.time() - start_time

    # Print summary
    pipeline.print_summary()

    # Generate report if requested
    if args.report:
        pipeline.generate_report(args.report)

    # Exit with appropriate code
    sys.exit(0 if pipeline.results.failed == 0 else 1)


if __name__ == "__main__":
    main()
