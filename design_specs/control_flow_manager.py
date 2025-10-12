#!/usr/bin/env python3
"""
Design-First Control Flow Manager
Supports iterative development with flow specifications that can be modified before implementation.
"""

import yaml
import re
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum


class ImplementationStatus(Enum):
    IMPLEMENTED = "IMPLEMENTED"
    IN_PROGRESS = "IN_PROGRESS" 
    PLANNED = "PLANNED"
    TODO = "TODO"


@dataclass
class FlowStep:
    step_id: str
    name: str
    status: ImplementationStatus
    description: str
    sub_flows: List[str] = None
    decision_point: Optional[str] = None
    
    def __post_init__(self):
        if self.sub_flows is None:
            self.sub_flows = []


@dataclass 
class FlowInsertion:
    step_id: str
    name: str
    status: ImplementationStatus
    description: str
    insert_before: Optional[str] = None
    insert_after: Optional[str] = None


class ControlFlowManager:
    """Manages design-first control flow specifications."""
    
    def __init__(self, spec_file: Path):
        self.spec_file = spec_file
        self.flows = {}
        self.entry_points = {}
        self.decision_points = {}
        self.external_interfaces = {}
        
    def load_specification(self):
        """Load the YAML-based flow specification."""
        if not self.spec_file.exists():
            raise FileNotFoundError(f"Specification file not found: {self.spec_file}")
            
        with open(self.spec_file, 'r') as f:
            content = f.read()
            
        # Parse YAML sections
        sections = self._parse_yaml_sections(content)
        
        if 'Entry Points' in sections:
            self.entry_points = sections['Entry Points']
        if 'Flow Implementations' in sections:
            self.flows = sections['Flow Implementations']
        if 'Decision Points' in sections:
            self.decision_points = sections['Decision Points']
        if 'External Interfaces' in sections:
            self.external_interfaces = sections['External Interfaces']
            
    def _parse_yaml_sections(self, content: str) -> Dict[str, Any]:
        """Parse YAML sections from markdown content."""
        sections = {}
        
        # Extract YAML blocks
        yaml_blocks = re.findall(r'```yaml\n(.*?)\n```', content, re.DOTALL)
        
        for block in yaml_blocks:
            try:
                data = yaml.safe_load(block)
                if data:
                    # Determine section based on content structure
                    if any(key in data for key in ['cli', 'configure', 'update']):
                        sections['Entry Points'] = data
                    elif any('flow_steps' in str(v) for v in data.values() if isinstance(v, dict)):
                        sections['Flow Implementations'] = data
                    elif any('type' in str(v) for v in data.values() if isinstance(v, dict)):
                        sections['Decision Points'] = data
                    elif 'outbound_calls' in data or 'inbound_calls' in data:
                        sections['External Interfaces'] = data
            except yaml.YAMLError:
                continue
                
        return sections
        
    def insert_flow_step(self, flow_name: str, insertion: FlowInsertion) -> bool:
        """Insert a new step into an existing flow."""
        if flow_name not in self.flows:
            print(f"❌ Flow '{flow_name}' not found")
            return False
            
        flow = self.flows[flow_name]
        if 'flow_steps' not in flow:
            print(f"❌ Flow '{flow_name}' has no flow_steps")
            return False
            
        steps = flow['flow_steps']
        
        # Find insertion point
        insert_index = None
        
        if insertion.insert_after:
            for i, step in enumerate(steps):
                if step.get('step_id') == insertion.insert_after:
                    insert_index = i + 1
                    break
                    
        elif insertion.insert_before:
            for i, step in enumerate(steps):
                if step.get('step_id') == insertion.insert_before:
                    insert_index = i
                    break
        
        if insert_index is None:
            print(f"❌ Insertion point not found for {insertion.insert_before or insertion.insert_after}")
            return False
            
        # Create new step
        new_step = {
            'step_id': insertion.step_id,
            'name': insertion.name,
            'status': insertion.status.value,
            'description': insertion.description
        }
        
        # Insert step
        steps.insert(insert_index, new_step)
        
        print(f"✅ Inserted step '{insertion.step_id}' in flow '{flow_name}' at position {insert_index}")
        return True
        
    def apply_planned_insertions(self, flow_name: str) -> int:
        """Apply all planned insertions for a flow."""
        if flow_name not in self.flows:
            return 0
            
        flow = self.flows[flow_name]
        if 'planned_insertions' not in flow:
            return 0
            
        insertions = flow['planned_insertions']
        applied = 0
        
        for insertion_data in insertions:
            insertion = FlowInsertion(
                step_id=insertion_data['step_id'],
                name=insertion_data['name'],
                status=ImplementationStatus(insertion_data['status']),
                description=insertion_data['description'],
                insert_before=insertion_data.get('insert_before'),
                insert_after=insertion_data.get('insert_after')
            )
            
            if self.insert_flow_step(flow_name, insertion):
                applied += 1
                
        # Remove applied insertions
        if applied > 0:
            flow['planned_insertions'] = []
            
        return applied
        
    def generate_implementation_tasks(self) -> List[Dict[str, str]]:
        """Generate list of implementation tasks from the specification."""
        tasks = []
        
        for flow_name, flow_data in self.flows.items():
            if 'flow_steps' not in flow_data:
                continue
                
            for step in flow_data['flow_steps']:
                status = step.get('status', 'TODO')
                if status in ['PLANNED', 'TODO']:
                    tasks.append({
                        'flow': flow_name,
                        'step_id': step['step_id'],
                        'name': step['name'],
                        'description': step['description'],
                        'status': status,
                        'type': 'implementation'
                    })
                    
        # Add decision points
        for decision_name, decision_data in self.decision_points.items():
            if not decision_data.get('implemented', False):
                tasks.append({
                    'flow': 'decision_points',
                    'step_id': decision_name,
                    'name': decision_name,
                    'description': decision_data.get('prompt', 'Decision point implementation'),
                    'status': 'TODO',
                    'type': 'decision_point'
                })
                
        return tasks
        
    def generate_mock_code(self, flow_name: str, step_id: str) -> str:
        """Generate mock code for a planned step."""
        if flow_name not in self.flows:
            return f"# Flow '{flow_name}' not found"
            
        flow = self.flows[flow_name]
        if 'flow_steps' not in flow:
            return f"# Flow '{flow_name}' has no steps"
            
        step_data = None
        for step in flow['flow_steps']:
            if step.get('step_id') == step_id:
                step_data = step
                break
                
        if not step_data:
            return f"# Step '{step_id}' not found in flow '{flow_name}'"
            
        # Generate mock implementation
        step_name = step_data['name']
        description = step_data['description']
        
        mock_code = f'''def {step_id}(self, context: Dict[str, Any]) -> Dict[str, Any]:
    """
    {step_name}
    
    {description}
    
    Args:
        context: Current execution context
        
    Returns:
        Updated context with step results
    """
    # TODO: Implement {step_name.lower()}
    self.ui.show_step("{step_name}")
    
    # Mock implementation
    result = {{
        "step_id": "{step_id}",
        "status": "completed",
        "data": {{}},
        "messages": []
    }}
    
    context.update(result)
    return context
'''
        
        return mock_code
        
    def generate_unit_test(self, flow_name: str, step_id: str) -> str:
        """Generate unit test for a planned step."""
        if flow_name not in self.flows:
            return f"# Flow '{flow_name}' not found"
            
        flow = self.flows[flow_name]
        if 'flow_steps' not in flow:
            return f"# Flow '{flow_name}' has no steps"
            
        step_data = None
        for step in flow['flow_steps']:
            if step.get('step_id') == step_id:
                step_data = step
                break
                
        if not step_data:
            return f"# Step '{step_id}' not found in flow '{flow_name}'"
            
        step_name = step_data['name']
        description = step_data['description']
        
        test_code = f'''def test_{step_id}(self):
    """Test {step_name}."""
    # Arrange
    manager = ConfigurationManager()
    context = {{
        "test_mode": True,
        "flow": "{flow_name}",
        "previous_steps": []
    }}
    
    # Act
    result = manager.{step_id}(context)
    
    # Assert
    assert result is not None
    assert result.get("step_id") == "{step_id}"
    assert result.get("status") == "completed"
    
    # Verify specific behavior for {description.lower()}
    # TODO: Add specific assertions based on step requirements
    
def test_{step_id}_error_handling(self):
    """Test {step_name} error handling."""
    # Arrange
    manager = ConfigurationManager()
    invalid_context = {{}}  # Invalid context to trigger error
    
    # Act & Assert
    with pytest.raises(ValueError):
        manager.{step_id}(invalid_context)
'''
        
        return test_code
        
    def save_specification(self):
        """Save the current specification back to file."""
        # This would regenerate the markdown with YAML blocks
        # For now, just print what would be saved
        print("📝 Specification would be saved with current changes")
        
    def get_development_prompt_suggestions(self) -> List[str]:
        """Get suggestions for development prompts."""
        suggestions = []
        
        tasks = self.generate_implementation_tasks()
        
        for task in tasks[:5]:  # Top 5 tasks
            if task['type'] == 'implementation':
                suggestions.append(
                    f"Implement {task['name']} step in {task['flow']} flow: {task['description']}"
                )
            elif task['type'] == 'decision_point':
                suggestions.append(
                    f"Add decision point '{task['name']}' with user confirmation"
                )
                
        return suggestions


def main():
    """Demo the design-first control flow manager."""
    print("🎯 Design-First Control Flow Manager")
    print("=" * 40)
    
    spec_file = Path("/opt/openproject/control_flows/CONTROL_FLOWS_SPEC.md")
    manager = ControlFlowManager(spec_file)
    
    try:
        manager.load_specification()
        print("✅ Loaded flow specification")
        
        # Show current flows
        print(f"\\n📊 Found {len(manager.flows)} flows:")
        for flow_name in manager.flows.keys():
            print(f"  - {flow_name}")
            
        # Apply planned insertions
        print("\\n🔄 Applying planned insertions...")
        for flow_name in manager.flows.keys():
            applied = manager.apply_planned_insertions(flow_name)
            if applied > 0:
                print(f"  ✅ Applied {applied} insertions to {flow_name}")
                
        # Show implementation tasks
        tasks = manager.generate_implementation_tasks()
        if tasks:
            print(f"\\n📋 Implementation Tasks ({len(tasks)}):")
            for task in tasks[:3]:  # Show first 3
                print(f"  - {task['name']} ({task['status']})")
                
        # Show development suggestions
        suggestions = manager.get_development_prompt_suggestions()
        if suggestions:
            print("\\n💡 Development Prompt Suggestions:")
            for suggestion in suggestions[:2]:  # Show first 2
                print(f"  • {suggestion}")
                
    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    main()