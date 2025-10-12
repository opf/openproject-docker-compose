#!/usr/bin/env python3
"""
Unit test runner for OpenProject Configuration Manager.
Runs only fast unit tests for core functionality.
"""

import subprocess
import sys
from pathlib import Path

def main():
    """Run unit tests only."""
    print("🧪 Running Unit Tests")
    print("=" * 40)
    
    # Change to project root
    project_root = Path(__file__).parent.parent.parent
    
    # Run unit tests
    cmd = [
        sys.executable, "-m", "pytest",
        "testing/unit/",
        "-v",
        "--tb=short",
        "-m", "not slow"
    ]
    
    result = subprocess.run(cmd, cwd=project_root)
    
    if result.returncode == 0:
        print("✅ All unit tests passed!")
    else:
        print("❌ Some unit tests failed!")
        
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())