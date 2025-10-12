#!/usr/bin/env python3
"""
Integration test runner for OpenProject Configuration Manager.
Runs tests that involve multiple components working together.
"""

import subprocess
import sys
from pathlib import Path

def main():
    """Run integration tests only."""
    print("🔧 Running Integration Tests")
    print("=" * 40)
    
    # Change to project root
    project_root = Path(__file__).parent.parent.parent
    
    # Run integration tests
    cmd = [
        sys.executable, "-m", "pytest",
        "testing/integration/",
        "-v",
        "--tb=short"
    ]
    
    result = subprocess.run(cmd, cwd=project_root)
    
    if result.returncode == 0:
        print("✅ All integration tests passed!")
    else:
        print("❌ Some integration tests failed!")
        
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())