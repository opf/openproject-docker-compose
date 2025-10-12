#!/usr/bin/env python3
"""
End-to-end test runner for OpenProject Configuration Manager.
Runs complete workflow tests that simulate real user scenarios.
"""

import subprocess
import sys
from pathlib import Path

def main():
    """Run E2E tests only."""
    print("🎯 Running End-to-End Tests")
    print("=" * 40)
    
    # Change to project root
    project_root = Path(__file__).parent.parent.parent
    
    # Run E2E tests
    cmd = [
        sys.executable, "-m", "pytest",
        "testing/e2e/",
        "-v",
        "--tb=short",
        "-s"  # Don't capture output for E2E tests
    ]
    
    result = subprocess.run(cmd, cwd=project_root)
    
    if result.returncode == 0:
        print("✅ All E2E tests passed!")
    else:
        print("❌ Some E2E tests failed!")
        
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())