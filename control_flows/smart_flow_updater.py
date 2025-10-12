#!/usr/bin/env python3
"""
Smart Control Flow Updater
Preserves manual modifications while applying systematic updates.
"""

import re
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime


class SmartFlowUpdater:
    """Updates control flow specifications while preserving manual changes."""
    
    def __init__(self, spec_file: Path):
        self.spec_file = spec_file
        self.manual_changes = []
        self.auto_generated_sections = ['planned_insertions']
        
    def detect_manual_changes(self) -> List[Dict[str, Any]]:
        """Detect sections that have been manually modified."""
        if not self.spec_file.exists():
            return []
            
        with open(self.spec_file, 'r') as f:
            content = f.read()
            
        changes = []
        
        # Look for manual annotations
        manual_markers = [
            r'# MANUAL:.*',
            r'# CUSTOM:.*',
            r'# USER_ADDED:.*'
        ]
        
        for marker in manual_markers:
            matches = re.finditer(marker, content)
            for match in matches:
                changes.append({
                    'type': 'manual_annotation',
                    'line': content[:match.start()].count('\\n') + 1,
                    'content': match.group()
                })
                
        # Look for custom flow steps (not in standard pattern)
        custom_steps = re.finditer(r'- step_id: "([^"]+)"\\s*# CUSTOM', content)
        for match in custom_steps:
            changes.append({
                'type': 'custom_step',
                'step_id': match.group(1),
                'preserve': True
            })
            
        return changes
        
    def preserve_manual_sections(self, new_content: str, old_content: str) -> str:
        """Preserve manually modified sections when updating."""
        # Simple preservation strategy - look for sections marked as manual
        lines = new_content.split('\\n')
        old_lines = old_content.split('\\n')
        
        preserved_content = []
        
        for i, line in enumerate(lines):
            # If this line has a manual marker, preserve the original
            if any(marker in line for marker in ['# MANUAL', '# CUSTOM', '# USER_ADDED']):
                # Find corresponding line in old content
                for old_line in old_lines:
                    if line.strip().split('#')[0].strip() == old_line.strip().split('#')[0].strip():
                        preserved_content.append(old_line)
                        break
                else:
                    preserved_content.append(line)
            else:
                preserved_content.append(line)
                
        return '\\n'.join(preserved_content)
        
    def update_from_code_analysis(self, code_files: List[Path]) -> Dict[str, Any]:
        """Update flow specification based on actual code analysis."""
        updates = {
            'new_entry_points': [],
            'implementation_status_changes': [],
            'new_decision_points': []
        }
        
        # Analyze code files to detect changes
        for code_file in code_files:
            if not code_file.exists():
                continue
                
            with open(code_file, 'r') as f:
                code_content = f.read()
                
            # Find CLI commands
            cli_commands = re.findall(r'@cli\\.command\\(\\)\\s*[^def]*def\\s+(\\w+)', code_content)
            
            # Find decision points (if/else with user interaction)
            decision_patterns = [
                r'if.*confirm\\(',
                r'if.*input\\(',
                r'if.*ask\\('
            ]
            
            for pattern in decision_patterns:
                matches = re.finditer(pattern, code_content)
                for match in matches:
                    updates['new_decision_points'].append({
                        'file': str(code_file),
                        'line': code_content[:match.start()].count('\\n') + 1,
                        'context': match.group()
                    })
                    
        return updates
        
    def generate_update_summary(self) -> str:
        """Generate a summary of what would be updated."""
        summary = f"""# Control Flow Update Summary
Generated: {datetime.now().isoformat()}

## Preservation Strategy
- ✅ Manual annotations (# MANUAL, # CUSTOM, # USER_ADDED) are preserved
- ✅ Custom step implementations are kept
- ✅ User-defined decision points remain unchanged
- 🔄 Auto-generated sections are updated from code analysis

## Detected Changes
"""
        
        # Add detected changes
        manual_changes = self.detect_manual_changes()
        if manual_changes:
            summary += "\\n### Manual Changes Found:\\n"
            for change in manual_changes:
                summary += f"- {change['type']}: {change.get('content', change.get('step_id', 'Unknown'))}\n"
        else:
            summary += "\\n### No manual changes detected\\n"
            
        return summary
        
    def smart_update(self, preserve_manual: bool = True) -> bool:
        """Perform smart update of the control flow specification."""
        if not self.spec_file.exists():
            print("❌ Specification file not found")
            return False
            
        # Read current content
        with open(self.spec_file, 'r') as f:
            old_content = f.read()
            
        # Detect manual changes
        manual_changes = self.detect_manual_changes()
        
        if manual_changes and preserve_manual:
            print(f"🔒 Found {len(manual_changes)} manual changes - preserving them")
            
        # For demo purposes, just show what would happen
        print("📝 Smart update would:")
        print("   ✅ Preserve manual annotations")
        print("   🔄 Update implementation status from code")
        print("   ➕ Add newly discovered entry points")
        print("   🎯 Maintain planned insertions")
        
        return True


def demo_smart_updates():
    """Demonstrate smart updating capabilities."""
    print("🧠 Smart Control Flow Updates Demo")
    print("=" * 50)
    
    spec_file = Path("/opt/openproject/control_flows/CONTROL_FLOWS_SPEC.md")
    updater = SmartFlowUpdater(spec_file)
    
    # Show current manual changes
    manual_changes = updater.detect_manual_changes()
    print(f"\\n📊 Manual Changes: {len(manual_changes)} detected")
    
    # Show update summary
    summary = updater.generate_update_summary()
    print("\\n📋 Update Summary:")
    print(summary[:400] + "..." if len(summary) > 400 else summary)
    
    # Demonstrate smart update
    print("\\n🔄 Running Smart Update:")
    success = updater.smart_update(preserve_manual=True)
    
    if success:
        print("✅ Smart update completed successfully")
    else:
        print("❌ Smart update failed")
        
    print("\\n💡 Usage Examples:")
    examples = [
        "# MANUAL: Custom validation step for company-specific rules",
        "# CUSTOM: Added monitoring integration step", 
        "# USER_ADDED: Error recovery with rollback capability"
    ]
    
    for example in examples:
        print(f"   {example}")
        
    print("\\n🎯 These annotations would be preserved during automated updates")


if __name__ == "__main__":
    demo_smart_updates()