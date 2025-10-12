#!/usr/bin/env python3
"""
Simple Control Flow Tracker for Config Manager
Demonstrates the control flow tracking system before system-wide implementation.
"""

import os
import re
from pathlib import Path
from typing import Dict, List, Set, Optional


class ControlFlowAnalyzer:
    """Analyze and validate control flows for a single component."""
    
    def __init__(self, component_path: str):
        self.component_path = Path(component_path)
        self.control_flows_file = self.component_path / "control_flows" / "CONTROL_FLOWS.md"
        
    def parse_control_flows(self) -> Dict[str, List[str]]:
        """Parse the CONTROL_FLOWS.md file and extract structured data."""
        if not self.control_flows_file.exists():
            print(f"❌ No CONTROL_FLOWS.md found at {self.control_flows_file}")
            return {}
            
        flows = {
            'entry_points': [],
            'internal_flow': [],
            'exit_points': [],
            'external_calls': []
        }
        
        with open(self.control_flows_file, 'r') as f:
            content = f.read()
            
        # Extract entry points
        entry_section = re.search(r'## Entry Points.*?\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
        if entry_section:
            entries = re.findall(r'- `([^`]+)`.*?← Called from: ([^\n]+)', entry_section.group(1))
            flows['entry_points'] = [f"{func} ← {caller}" for func, caller in entries]
            
        # Extract internal flow steps
        flow_section = re.search(r'## Internal Flow.*?\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
        if flow_section:
            steps = re.findall(r'\d+\.\s*\*\*([^*]+)\*\*:([^\n]+)', flow_section.group(1))
            flows['internal_flow'] = [f"{step}: {desc.strip()}" for step, desc in steps]
            
        # Extract exit points
        exit_section = re.search(r'## Exit Points.*?\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
        if exit_section:
            exits = re.findall(r'- \*\*([^*]+)\*\*:([^\n]+)', exit_section.group(1))
            flows['exit_points'] = [f"{point}: {desc.strip()}" for point, desc in exits]
            
        # Extract external calls
        external_section = re.search(r'## External Calls.*?\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
        if external_section:
            calls = re.findall(r'- \*\*([^*]+)\*\*:([^\n]+)', external_section.group(1))
            flows['external_calls'] = [f"{call}: {desc.strip()}" for call, desc in calls]
            
        return flows
        
    def validate_flows(self) -> bool:
        """Validate that control flows make sense."""
        flows = self.parse_control_flows()
        
        if not flows:
            return False
            
        valid = True
        
        # Check that we have at least one entry point
        if not flows['entry_points']:
            print("⚠️  No entry points defined")
            valid = False
            
        # Check that we have some internal flow
        if not flows['internal_flow']:
            print("⚠️  No internal flow steps defined")  
            valid = False
            
        # Check that we have exit points
        if not flows['exit_points']:
            print("⚠️  No exit points defined")
            valid = False
            
        return valid
        
    def generate_summary(self) -> str:
        """Generate a summary of the control flows."""
        flows = self.parse_control_flows()
        
        if not flows:
            return "❌ No control flows found"
            
        summary = f"# Control Flow Summary: {self.component_path.name}\n\n"
        
        summary += f"## Entry Points ({len(flows['entry_points'])})\n"
        for entry in flows['entry_points']:
            summary += f"- {entry}\n"
        summary += "\n"
        
        summary += f"## Internal Flow ({len(flows['internal_flow'])} steps)\n"
        for i, step in enumerate(flows['internal_flow'], 1):
            summary += f"{i}. {step}\n"
        summary += "\n"
        
        summary += f"## Exit Points ({len(flows['exit_points'])})\n" 
        for exit_point in flows['exit_points']:
            summary += f"- {exit_point}\n"
        summary += "\n"
        
        if flows['external_calls']:
            summary += f"## External Calls ({len(flows['external_calls'])})\n"
            for call in flows['external_calls']:
                summary += f"- {call}\n"
        else:
            summary += "## External Calls\n- None (self-contained component)\n"
            
        return summary
        
    def check_code_alignment(self) -> List[str]:
        """Check if control flows align with actual code structure."""
        issues = []
        flows = self.parse_control_flows()
        
        # Look for main.py and check CLI commands
        main_py = self.component_path / "src" / "openproject_config_manager" / "main.py"
        if main_py.exists():
            with open(main_py, 'r') as f:
                main_content = f.read()
                
            # Check for CLI commands
            cli_commands = re.findall(r'@cli\.command\(\)\s*[^def]*def\s+(\w+)', main_content)
            
            documented_entries = [entry.split('`')[1].split('(')[0] for entry in flows['entry_points'] if '`' in entry]
            
            for cmd in cli_commands:
                if cmd not in documented_entries:
                    issues.append(f"CLI command '{cmd}' not documented in control flows")
                    
            for entry in documented_entries:
                if entry not in cli_commands and entry not in ['cli', 'ConfigurationManager', 'run_full_process']:
                    issues.append(f"Documented entry point '{entry}' not found in code")
        
        return issues


def main():
    """Demo the control flow analyzer for openproject-docker-compose."""
    print("🔍 Control Flow Analyzer - OpenProject Docker Compose Demo")
    print("=" * 60)
    
    openproject_path = "/opt/openproject"
    analyzer = ControlFlowAnalyzer(openproject_path)
    
    # Check if control flows file exists
    if not analyzer.control_flows_file.exists():
        print(f"❌ CONTROL_FLOWS.md not found at {analyzer.control_flows_file}")
        return
        
    print(f"✅ Found CONTROL_FLOWS.md")
    
    # Validate flows
    print("\n📋 Validating Control Flows...")
    is_valid = analyzer.validate_flows()
    if is_valid:
        print("✅ Control flows validation passed")
    else:
        print("❌ Control flows validation failed")
        
    # Check code alignment
    print("\n🔍 Checking Code Alignment...")
    issues = analyzer.check_code_alignment()
    if not issues:
        print("✅ Control flows align with code structure")
    else:
        print("⚠️  Found alignment issues:")
        for issue in issues:
            print(f"   - {issue}")
            
    # Generate summary
    print("\n📊 Control Flow Summary:")
    print("-" * 30)
    summary = analyzer.generate_summary()
    print(summary)


if __name__ == "__main__":
    main()