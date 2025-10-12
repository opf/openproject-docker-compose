#!/usr/bin/env python3
"""
Development Communication Demo
Shows how to use the design-first control flow system for iterative development.
"""

from control_flow_manager import ControlFlowManager, FlowInsertion, ImplementationStatus
from pathlib import Path


def demo_development_workflow():
    """Demonstrate the development workflow using control flows."""
    print("🚀 Development Communication Demo")
    print("=" * 50)
    
    spec_file = Path("/opt/openproject/external/config-manager/control_flows/CONTROL_FLOWS_SPEC.md")
    manager = ControlFlowManager(spec_file)
    manager.load_specification()
    
    print("\\n1️⃣ Current Flow State:")
    print("   📊 Loaded flows with planned insertions")
    
    # Apply planned insertions to see current design
    for flow_name in manager.flows.keys():
        applied = manager.apply_planned_insertions(flow_name)
        if applied > 0:
            print(f"   ✅ Applied {applied} planned insertions to {flow_name}")
    
    print("\\n2️⃣ Development Communication Examples:")
    
    # Example 1: Insert new step
    print("\\n   💬 'Insert a configuration backup step before validation'")
    backup_step = FlowInsertion(
        step_id="backup_config",
        name="Backup Configuration",
        status=ImplementationStatus.PLANNED,
        description="Create backup of current configuration before changes",
        insert_before="validation"
    )
    
    if manager.insert_flow_step("main_config_flow", backup_step):
        print("   ✅ Flow updated: backup_config step added")
        
    # Example 2: Generate mock code
    print("\\n3️⃣ Generate Mock Implementation:")
    mock_code = manager.generate_mock_code("main_config_flow", "pre_validation_cleanup")
    print("   📝 Mock code for 'pre_validation_cleanup':")
    print("   " + "\\n   ".join(mock_code.split("\\n")[:8]))  # First 8 lines
    print("   ... (truncated)")
    
    # Example 3: Generate unit test
    print("\\n4️⃣ Generate Unit Test:")
    test_code = manager.generate_unit_test("main_config_flow", "final_review")
    print("   🧪 Unit test for 'final_review':")
    print("   " + "\\n   ".join(test_code.split("\\n")[:6]))  # First 6 lines
    print("   ... (truncated)")
    
    # Example 4: Show implementation tasks
    print("\\n5️⃣ Implementation Tasks:")
    tasks = manager.generate_implementation_tasks()
    for i, task in enumerate(tasks[:3], 1):
        print(f"   {i}. {task['name']} ({task['status']})")
        print(f"      {task['description']}")
    
    print("\\n6️⃣ Development Prompt Examples:")
    prompts = [
        "Implement the pre_validation_cleanup step with data cleaning logic",
        "Add error handling to the final_review step",
        "Create a confirmation dialog for the backup_config step",
        "Move the network_discovery step to run in parallel with system_discovery",
        "Add a decision point for skipping discovery in test mode"
    ]
    
    for i, prompt in enumerate(prompts, 1):
        print(f"   {i}. '{prompt}'")
    
    print("\\n✨ Benefits:")
    print("   🎯 Design before implementation")
    print("   📝 Clear communication with AI assistant")
    print("   🔄 Iterative development support")
    print("   📊 Visual flow progression")
    print("   🧪 Auto-generated test scaffolding")


def demo_ai_communication():
    """Show how to communicate with AI assistant using control flows."""
    print("\\n" + "=" * 50)
    print("🤖 AI Communication Examples")
    print("=" * 50)
    
    examples = [
        {
            "user_request": "Insert a security validation step after constraint validation",
            "ai_interpretation": "Insert step 'security_validation' after 'validate_constraints' in validation_flow",
            "result": "New step added to planned_insertions"
        },
        {
            "user_request": "Move final review to be before validation instead of before export", 
            "ai_interpretation": "Update final_review step: change insert_before from 'export' to 'validation'",
            "result": "Step repositioned in main_config_flow"
        },
        {
            "user_request": "Add error handling to the discovery phase",
            "ai_interpretation": "Insert step 'handle_discovery_errors' after 'discovery' with error recovery logic",
            "result": "Error handling step planned"
        },
        {
            "user_request": "Create mock implementation for network discovery",
            "ai_interpretation": "Generate mock code for 'network_discovery' step in discovery_flow",
            "result": "Mock code and unit test generated"
        }
    ]
    
    for i, example in enumerate(examples, 1):
        print(f"\\n{i}️⃣ Communication Example:")
        print(f"   👤 User: '{example['user_request']}'")
        print(f"   🤖 AI: {example['ai_interpretation']}")
        print(f"   ✅ Result: {example['result']}")


if __name__ == "__main__":
    demo_development_workflow()
    demo_ai_communication()
    
    print("\\n" + "=" * 50)
    print("🎉 Ready for design-first iterative development!")
    print("   Use CONTROL_FLOWS_SPEC.md to communicate changes")
    print("   Run control_flow_manager.py to apply and generate code")
    print("=" * 50)