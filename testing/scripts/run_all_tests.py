#!/usr/bin/env python3
"""
Comprehensive test runner for OpenProject Docker Compose.

This script runs all test suites and provides detailed reporting
on orchestration functionality and deployment workflow validation.
"""

import sys
import pytest
import json
import time
from pathlib import Path
from typing import Dict, List, Any
import argparse


class TestRunner:
    """
    Manages test execution and reporting for the configuration manager.
    """
    
    def __init__(self, verbose: bool = False):
        """Initialize test runner."""
        self.verbose = verbose
        self.results = {
            "start_time": None,
            "end_time": None,
            "duration": 0,
            "total_tests": 0,
            "passed": 0,
            "failed": 0,
            "skipped": 0,
            "test_suites": {}
        }
    
    def run_all_tests(self) -> Dict[str, Any]:
        """Run all test suites and return comprehensive results."""
        self.results["start_time"] = time.time()
        
        print("🧪 OpenProject Configuration Manager - Test Suite")
        print("=" * 60)
        
        # Define test suites to run
        test_suites = [
            {
                "name": "UI Console Components",
                "path": "../unit/test_ui_console.py",
                "description": "Basic UI component functionality"
            },
            {
                "name": "E2E Workflow Tests", 
                "path": "../e2e/test_e2e_ui_workflows.py",
                "description": "Complete configuration workflows"
            }
        ]
        
        for suite in test_suites:
            print(f"\\n📋 Running: {suite['name']}")
            print(f"   {suite['description']}")
            print("-" * 40)
            
            suite_results = self._run_test_suite(suite)
            self.results["test_suites"][suite["name"]] = suite_results
            
            self._update_totals(suite_results)
            self._print_suite_summary(suite, suite_results)
        
        self.results["end_time"] = time.time()
        self.results["duration"] = self.results["end_time"] - self.results["start_time"]
        
        self._print_final_summary()
        return self.results
    
    def _run_test_suite(self, suite: Dict[str, str]) -> Dict[str, Any]:
        """Run a specific test suite."""
        suite_results = {
            "passed": 0,
            "failed": 0,
            "skipped": 0,
            "duration": 0,
            "details": []
        }
        
        start_time = time.time()
        
        try:
            # Run pytest for this specific suite
            args = [
                suite["path"],
                "-v" if self.verbose else "-q",
                "--tb=short",
                "-x",  # Stop on first failure
                "--json-report",
                "--json-report-file=test_results.json"
            ]
            
            exit_code = pytest.main(args)
            
            # Parse results from JSON report if available
            try:
                with open("test_results.json", "r") as f:
                    pytest_results = json.load(f)
                    suite_results = self._parse_pytest_results(pytest_results)
            except FileNotFoundError:
                # Fallback if JSON report not available
                if exit_code == 0:
                    suite_results["passed"] = 1
                else:
                    suite_results["failed"] = 1
                    
        except Exception as e:
            suite_results["failed"] = 1
            suite_results["details"].append(f"Suite execution error: {e}")
        
        suite_results["duration"] = time.time() - start_time
        return suite_results
    
    def _parse_pytest_results(self, pytest_results: Dict) -> Dict[str, Any]:
        """Parse pytest JSON results."""
        results = {
            "passed": 0,
            "failed": 0,
            "skipped": 0,
            "duration": pytest_results.get("duration", 0),
            "details": []
        }
        
        # Count test outcomes
        for test in pytest_results.get("tests", []):
            outcome = test.get("outcome", "unknown")
            if outcome == "passed":
                results["passed"] += 1
            elif outcome == "failed":
                results["failed"] += 1
                results["details"].append(f"FAILED: {test.get('nodeid', 'unknown test')}")
            elif outcome == "skipped":
                results["skipped"] += 1
        
        return results
    
    def _update_totals(self, suite_results: Dict[str, Any]) -> None:
        """Update total test counts."""
        self.results["passed"] += suite_results["passed"]
        self.results["failed"] += suite_results["failed"]
        self.results["skipped"] += suite_results["skipped"]
        self.results["total_tests"] += (
            suite_results["passed"] + 
            suite_results["failed"] + 
            suite_results["skipped"]
        )
    
    def _print_suite_summary(self, suite: Dict[str, str], results: Dict[str, Any]) -> None:
        """Print summary for a test suite."""
        total = results["passed"] + results["failed"] + results["skipped"]
        
        status = "✅ PASSED" if results["failed"] == 0 else "❌ FAILED"
        print(f"{status} - {results['passed']}/{total} tests passed ({results['duration']:.2f}s)")
        
        if results["failed"] > 0:
            print(f"   ❌ {results['failed']} failed")
            for detail in results["details"]:
                print(f"      {detail}")
        
        if results["skipped"] > 0:
            print(f"   ⏭️  {results['skipped']} skipped")
    
    def _print_final_summary(self) -> None:
        """Print final test summary."""
        print("\\n" + "=" * 60)
        print("📊 FINAL TEST SUMMARY")
        print("=" * 60)
        
        total = self.results["total_tests"]
        passed = self.results["passed"]
        failed = self.results["failed"]
        skipped = self.results["skipped"]
        
        success_rate = (passed / total * 100) if total > 0 else 0
        
        print(f"Total Tests:    {total}")
        print(f"✅ Passed:      {passed}")
        print(f"❌ Failed:      {failed}")
        print(f"⏭️  Skipped:     {skipped}")
        print(f"⏱️  Duration:    {self.results['duration']:.2f} seconds")
        print(f"📈 Success Rate: {success_rate:.1f}%")
        
        if failed == 0:
            print("\\n🎉 ALL TESTS PASSED! UI components are ready for production.")
        else:
            print(f"\\n⚠️  {failed} test(s) failed. Review issues before deployment.")
        
        print("\\n📋 Test Suite Breakdown:")
        for suite_name, suite_results in self.results["test_suites"].items():
            total_suite = suite_results["passed"] + suite_results["failed"] + suite_results["skipped"]
            suite_rate = (suite_results["passed"] / total_suite * 100) if total_suite > 0 else 0
            status_icon = "✅" if suite_results["failed"] == 0 else "❌"
            print(f"   {status_icon} {suite_name}: {suite_results['passed']}/{total_suite} ({suite_rate:.1f}%)")


class UITestValidator:
    """
    Validates UI component test coverage and quality.
    """
    
    def __init__(self):
        """Initialize validator."""
        self.coverage_report = {
            "components_tested": [],
            "missing_coverage": [],
            "test_quality_score": 0
        }
    
    def validate_test_coverage(self) -> Dict[str, Any]:
        """Validate that all UI components have adequate test coverage."""
        print("\\n🔍 Validating Test Coverage")
        print("-" * 40)
        
        # Expected UI components that should be tested
        expected_components = [
            "show_title",
            "show_phase_header", 
            "show_section_header",
            "show_step",
            "show_success",
            "show_error",
            "show_warning",
            "show_info",
            "prompt",
            "prompt_int",
            "prompt_password",
            "confirm",
            "select",
            "show_table",
            "show_code",
            "show_json",
            "show_columns",
            "clear_screen",
            "pause",
            "show_progress",
            "show_spinner"
        ]
        
        # Check if test files exist and contain tests for each component
        test_files = [
            Path("tests/test_ui_console.py"),
            Path("tests/test_e2e_ui_workflows.py")
        ]
        
        tested_components = set()
        
        for test_file in test_files:
            if test_file.exists():
                content = test_file.read_text()
                for component in expected_components:
                    if f"test_{component}" in content or component in content:
                        tested_components.add(component)
        
        self.coverage_report["components_tested"] = list(tested_components)
        self.coverage_report["missing_coverage"] = [
            comp for comp in expected_components 
            if comp not in tested_components
        ]
        
        coverage_percentage = len(tested_components) / len(expected_components) * 100
        self.coverage_report["test_quality_score"] = coverage_percentage
        
        print(f"Component Coverage: {len(tested_components)}/{len(expected_components)} ({coverage_percentage:.1f}%)")
        
        if self.coverage_report["missing_coverage"]:
            print("\\n⚠️  Components missing test coverage:")
            for component in self.coverage_report["missing_coverage"]:
                print(f"   - {component}")
        else:
            print("\\n✅ All UI components have test coverage!")
        
        return self.coverage_report


def main():
    """Main entry point for test runner."""
    parser = argparse.ArgumentParser(description="OpenProject Configuration Manager Test Runner")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument("--coverage", action="store_true", help="Run coverage analysis")
    parser.add_argument("--suite", choices=["ui", "e2e", "all"], default="all", 
                       help="Test suite to run")
    
    args = parser.parse_args()
    
    # Initialize test runner
    runner = TestRunner(verbose=args.verbose)
    
    # Run coverage validation if requested
    if args.coverage:
        validator = UITestValidator()
        coverage_results = validator.validate_test_coverage()
        
        if coverage_results["test_quality_score"] < 80:
            print(f"\\n⚠️  Test coverage is below 80% ({coverage_results['test_quality_score']:.1f}%)")
            print("Consider adding tests for missing components before running full test suite.")
    
    # Run tests
    if args.suite in ["ui", "all"]:
        print("\\nRunning UI component tests...")
    
    if args.suite in ["e2e", "all"]:
        print("\\nRunning E2E workflow tests...")
    
    results = runner.run_all_tests()
    
    # Exit with appropriate code
    exit_code = 0 if results["failed"] == 0 else 1
    sys.exit(exit_code)


if __name__ == "__main__":
    main()