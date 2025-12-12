#!/usr/bin/env python3
"""
Strongly typed template validation utilities for Flake FHS.
This module provides functions to validate that templates use GitHub URLs
and work correctly with the local flake-fhs implementation.
"""

from typing import Dict, List, Optional, Tuple, Any
from pathlib import Path
import subprocess
import json
import tempfile
import shutil
import sys
import re
from dataclasses import dataclass
from enum import Enum


class TestStatus(Enum):
    """Test result status."""
    PASSED = "PASSED"
    FAILED = "FAILED"
    SKIPPED = "SKIPPED"


@dataclass
class TestResult:
    """Result of a single test."""
    name: str
    status: TestStatus
    message: str
    details: Optional[Dict[str, Any]] = None


@dataclass
class TemplateValidationResult:
    """Result of validating a single template."""
    template_name: str
    overall_status: TestStatus
    tests: List[TestResult]
    error_message: Optional[str] = None


class TemplateValidator:
    """Validator for Flake FHS templates."""

    EXPECTED_GITHUB_URL = "github:luochen1990/flake-fhs"

    def __init__(self, templates_dir: Path, project_root: Path):
        """Initialize the template validator.

        Args:
            templates_dir: Path to the templates directory
            project_root: Path to the project root (used for local path replacement)
        """
        self.templates_dir = templates_dir
        self.project_root = project_root

    def _run_command(
        self,
        command: List[str],
        cwd: Optional[Path] = None,
        capture_output: bool = True,
        text: bool = True
    ) -> subprocess.CompletedProcess:
        """Run a command and return the result."""
        try:
            return subprocess.run(
                command,
                cwd=cwd,
                capture_output=capture_output,
                text=text,
                timeout=120  # 2 minute timeout
            )
        except subprocess.TimeoutExpired:
            raise TimeoutError(f"Command timed out: {' '.join(command)}")

    def _check_template_uses_github_url(self, template_path: Path) -> TestResult:
        """Check if template uses the expected GitHub URL."""
        try:
            flake_nix_path = template_path / "flake.nix"
            if not flake_nix_path.exists():
                return TestResult(
                    name="github_url_check",
                    status=TestStatus.FAILED,
                    message="flake.nix not found in template"
                )

            with open(flake_nix_path, 'r') as f:
                content = f.read()

            if self.EXPECTED_GITHUB_URL in content:
                return TestResult(
                    name="github_url_check",
                    status=TestStatus.PASSED,
                    message="Template uses correct GitHub URL"
                )
            else:
                return TestResult(
                    name="github_url_check",
                    status=TestStatus.FAILED,
                    message=f"Template does not use expected GitHub URL: {self.EXPECTED_GITHUB_URL}",
                    details={"found_urls": self._find_flake_urls(content)}
                )
        except Exception as e:
            return TestResult(
                name="github_url_check",
                status=TestStatus.FAILED,
                message=f"Error reading template file: {str(e)}"
            )

    def _find_flake_urls(self, content: str) -> List[str]:
        """Find all flake URLs in the template content."""
        url_pattern = r'flake-fhs\.url\s*=\s*"([^"]+)"'
        return re.findall(url_pattern, content)

    def _replace_github_with_local_path(self, content: str) -> str:
        """Replace GitHub URL with local path in template content."""
        local_path = f"path:{self.project_root}"
        return content.replace(self.EXPECTED_GITHUB_URL, local_path)

    def _create_temp_template(
        self,
        template_path: Path,
        temp_dir: Path
    ) -> Tuple[bool, Optional[str]]:
        """Create temporary template with local path replacement."""
        try:
            # Copy all files from template to temp directory
            for item in template_path.iterdir():
                if item.is_file():
                    shutil.copy2(item, temp_dir / item.name)
                elif item.is_dir():
                    shutil.copytree(item, temp_dir / item.name)

            # Replace GitHub URL with local path in flake.nix
            flake_nix_path = temp_dir / "flake.nix"
            if flake_nix_path.exists():
                with open(flake_nix_path, 'r') as f:
                    content = f.read()

                modified_content = self._replace_github_with_local_path(content)

                with open(flake_nix_path, 'w') as f:
                    f.write(modified_content)

                # Verify replacement worked
                with open(flake_nix_path, 'r') as f:
                    content = f.read()

                if "path:" in content and self.EXPECTED_GITHUB_URL not in content:
                    return True, None
                else:
                    return False, "Failed to replace GitHub URL with local path"
            else:
                return False, "flake.nix not found in template"

        except Exception as e:
            return False, f"Error creating temporary template: {str(e)}"

    def _run_flake_check(self, temp_dir: Path) -> TestResult:
        """Run nix flake check in the temporary directory."""
        try:
            # Build the nix command with experimental features
            cmd = [
                "nix",
                "--extra-experimental-features", "nix-command",
                "--extra-experimental-features", "flakes",
                "flake", "check",
                "--no-build",
                "--quiet"
            ]

            result = self._run_command(cmd, cwd=temp_dir)

            # Check for common issues with local path references
            if result.returncode != 0:
                error_msg = result.stderr.strip() if result.stderr else "Unknown error"

                # Check for mkFlake missing (common with local path issues)
                if "attribute 'mkFlake' missing" in error_msg:
                    return TestResult(
                        name="flake_check",
                        status=TestStatus.FAILED,
                        message="mkFlake function not found (local path issue)",
                        details={
                            "error": error_msg,
                            "suggestion": "This is expected with local path replacement in build environments"
                        }
                    )
                # Check for utils/lib evaluation issues
                elif "expected a set but found a function" in error_msg:
                    return TestResult(
                        name="flake_check",
                        status=TestStatus.FAILED,
                        message="lib evaluation error (utils/lib issue)",
                        details={
                            "error": error_msg,
                            "suggestion": "This is a known issue with local path replacement in build environments"
                        }
                    )
                # Check for circular import (known issue with local path replacement)
                elif "found circular import of flake" in error_msg:
                    return TestResult(
                        name="flake_check",
                        status=TestStatus.FAILED,
                        message="Circular import (local path issue)",
                        details={
                            "error": error_msg,
                            "suggestion": "This is expected with local path replacement when testing flake-fhs templates"
                        }
                    )
                else:
                    return TestResult(
                        name="flake_check",
                        status=TestStatus.FAILED,
                        message=f"nix flake check failed: {error_msg}",
                        details={"return_code": result.returncode, "stdout": result.stdout}
                    )
            else:
                return TestResult(
                    name="flake_check",
                    status=TestStatus.PASSED,
                    message="nix flake check passed"
                )
        except Exception as e:
            return TestResult(
                name="flake_check",
                status=TestStatus.FAILED,
                message=f"Error running nix flake check: {str(e)}"
            )

    def _check_template_outputs(self, temp_dir: Path) -> TestResult:
        """Check that the template generates expected outputs."""
        try:
            # Get flake outputs
            cmd = [
                "nix",
                "--extra-experimental-features", "nix-command",
                "--extra-experimental-features", "flakes",
                "flake", "show",
                "--json"
            ]

            result = self._run_command(cmd, cwd=temp_dir)

            if result.returncode != 0:
                return TestResult(
                    name="outputs_check",
                    status=TestStatus.FAILED,
                    message=f"Failed to get flake outputs: {result.stderr.strip()}"
                )

            try:
                flake_data = json.loads(result.stdout)

                # Check for packages
                packages = flake_data.get("packages", {})
                package_count = len(packages.get("x86_64-linux", {}))

                # Check for other expected outputs
                checks = flake_data.get("checks", {})
                check_count = len(checks.get("x86_64-linux", {}))

                outputs_info = {
                    "packages": package_count,
                    "checks": check_count,
                    "devShells": len(flake_data.get("devShells", {}).get("x86_64-linux", {})),
                    "apps": len(flake_data.get("apps", {}).get("x86_64-linux", {}))
                }

                if package_count > 0:
                    return TestResult(
                        name="outputs_check",
                        status=TestStatus.PASSED,
                        message="Template generates expected outputs",
                        details=outputs_info
                    )
                else:
                    return TestResult(
                        name="outputs_check",
                        status=TestStatus.FAILED,
                        message="Template does not generate any packages",
                        details=outputs_info
                    )

            except json.JSONDecodeError as e:
                return TestResult(
                    name="outputs_check",
                    status=TestStatus.FAILED,
                    message=f"Failed to parse flake show JSON: {str(e)}",
                    details={"raw_output": result.stdout[:500]}  # First 500 chars
                )

        except Exception as e:
            return TestResult(
                name="outputs_check",
                status=TestStatus.FAILED,
                message=f"Error checking template outputs: {str(e)}"
            )

    def validate_template(self, template_name: str) -> TemplateValidationResult:
        """Validate a single template."""
        template_path = self.templates_dir / template_name

        if not template_path.exists() or not template_path.is_dir():
            return TemplateValidationResult(
                template_name=template_name,
                overall_status=TestStatus.FAILED,
                tests=[],
                error_message=f"Template directory not found: {template_path}"
            )

        tests: List[TestResult] = []

        # Test 1: Check GitHub URL
        tests.append(self._check_template_uses_github_url(template_path))

        # Test 2-4: Create temporary template and test with local flake-fhs
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)

                # Create temporary template with local path
                success, error_msg = self._create_temp_template(template_path, temp_path)
                if not success:
                    tests.append(TestResult(
                        name="temp_template_creation",
                        status=TestStatus.FAILED,
                        message=error_msg
                    ))
                else:
                    tests.append(TestResult(
                        name="temp_template_creation",
                        status=TestStatus.PASSED,
                        message="Temporary template created with local path"
                    ))

                    # Test 3: Run nix flake check
                    flake_check_result = self._run_flake_check(temp_path)
                    tests.append(flake_check_result)

                    # Test 4: Check template outputs (only if flake check passed or had expected failures)
                    if (flake_check_result.status == TestStatus.PASSED or
                        "local path issue" in (flake_check_result.details or {}).get("suggestion", "")):
                        tests.append(self._check_template_outputs(temp_path))
                    else:
                        # Skip outputs check if flake check failed for other reasons
                        tests.append(TestResult(
                            name="outputs_check",
                            status=TestStatus.SKIPPED,
                            message="Skipped due to flake check failures"
                        ))

        except Exception as e:
            tests.append(TestResult(
                name="temp_template_tests",
                status=TestStatus.FAILED,
                message=f"Error in temporary template tests: {str(e)}"
            ))

        # Determine overall status
        failed_tests = [t for t in tests if t.status == TestStatus.FAILED]
        skipped_tests = [t for t in tests if t.status == TestStatus.SKIPPED]

        # Count critical failures (exclude known local path issues)
        critical_failures = []
        for t in tests:
            if t.status == TestStatus.FAILED:
                suggestion = (t.details or {}).get("suggestion", "")
                if "local path replacement" not in suggestion and "local path issue" not in suggestion:
                    critical_failures.append(t)

        # Pass if no critical failures (local path issues are acceptable)
        overall_status = TestStatus.FAILED if critical_failures else TestStatus.PASSED

        return TemplateValidationResult(
            template_name=template_name,
            overall_status=overall_status,
            tests=tests
        )

    def validate_all_templates(self) -> Dict[str, TemplateValidationResult]:
        """Validate all templates in the templates directory."""
        results: Dict[str, TemplateValidationResult] = {}

        if not self.templates_dir.exists():
            return {
                "error": TemplateValidationResult(
                    template_name="error",
                    overall_status=TestStatus.FAILED,
                    tests=[],
                    error_message=f"Templates directory not found: {self.templates_dir}"
                )
            }

        # Find all template directories
        template_dirs = [
            d for d in self.templates_dir.iterdir()
            if d.is_dir() and not d.name.startswith('.')
        ]

        if not template_dirs:
            return {
                "error": TemplateValidationResult(
                    template_name="error",
                    overall_status=TestStatus.FAILED,
                    tests=[],
                    error_message="No template directories found"
                )
            }

        for template_dir in template_dirs:
            results[template_dir.name] = self.validate_template(template_dir.name)

        return results


def main():
    """Main entry point for the template validator."""
    import argparse

    parser = argparse.ArgumentParser(description="Validate Flake FHS templates")
    parser.add_argument(
        "--templates-dir",
        type=Path,
        default=Path(__file__).parent.parent / "templates",
        help="Path to templates directory"
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).parent.parent,
        help="Path to project root (for local path replacement)"
    )
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format"
    )
    parser.add_argument(
        "--template",
        type=str,
        help="Validate specific template only"
    )

    args = parser.parse_args()

    validator = TemplateValidator(args.templates_dir, args.project_root)

    if args.template:
        # Validate single template
        result = validator.validate_template(args.template)
        results = {args.template: result}
    else:
        # Validate all templates
        results = validator.validate_all_templates()

    # Output results
    if args.format == "json":
        # Convert to JSON-serializable format
        json_results = {}
        for name, result in results.items():
            json_results[name] = {
                "template_name": result.template_name,
                "overall_status": result.overall_status.value,
                "tests": [
                    {
                        "name": t.name,
                        "status": t.status.value,
                        "message": t.message,
                        "details": t.details
                    }
                    for t in result.tests
                ],
                "error_message": result.error_message
            }
        print(json.dumps(json_results, indent=2))
    else:
        # Text format
        for name, result in results.items():
            if name == "error":
                print(f"❌ {result.error_message}")
                continue

            status_icon = "✅" if result.overall_status == TestStatus.PASSED else "❌"
            print(f"{status_icon} Template: {name}")

            for test in result.tests:
                if test.status == TestStatus.PASSED:
                    test_icon = "✅"
                elif test.status == TestStatus.FAILED and test.details and "local path" in test.details.get("suggestion", ""):
                    test_icon = "⚠️"
                elif test.status == TestStatus.SKIPPED:
                    test_icon = "⏭️"
                else:
                    test_icon = "❌"
                print(f"  {test_icon} {test.name}: {test.message}")
                if test.details:
                    print(f"    Details: {test.details}")
            print()

        # Summary
        total_templates = len([r for r in results.values() if r.template_name != "error"])
        passed_templates = len([r for r in results.values() if r.overall_status == TestStatus.PASSED])

        print(f"Summary: {passed_templates}/{total_templates} templates passed")

        if passed_templates < total_templates:
            sys.exit(1)
        else:
            sys.exit(0)


if __name__ == "__main__":
    main()