# Control Flow Management System

This directory contains all control flow related files for the **openproject-docker-compose** main orchestration system.

## Files

### Documentation
- **`CONTROL_FLOWS.md`** - Current orchestration flow documentation (generated/maintained)
- **`CONTROL_FLOWS_SPEC.md`** - Design-first specification (YAML-based, AI-friendly)

### Tools
- **`analyze_control_flows.py`** - Analyzer and validator for orchestration flows
- **`control_flow_manager.py`** - Design-first flow manager with AI communication
- **`smart_flow_updater.py`** - Smart updater that preserves manual changes
- **`demo_development_communication.py`** - Demo of orchestration workflow

## Usage

### For Orchestration Development
```bash
# Analyze current orchestration flows
cd control_flows
python analyze_control_flows.py

# Apply planned orchestration changes
python control_flow_manager.py

# Smart update with preservation
python smart_flow_updater.py

# See development workflow demo
python demo_development_communication.py
```

### For AI Communication
Edit `CONTROL_FLOWS_SPEC.md` and use natural language like:
- "Insert security validation after input validation"
- "Add error recovery before export"
- "Move final review to be after validation"

## Design-First Workflow
1. Update `CONTROL_FLOWS_SPEC.md` with planned changes
2. Run `control_flow_manager.py` to apply changes
3. Generate mock implementations and tests
4. Implement actual functionality
5. Update status to IMPLEMENTED

## System Benefits
- 🎯 **Design-first**: Spec flows before implementing
- 📝 **AI Communication**: Natural language → precise changes
- 🔄 **Iterative**: Easy flow modification and insertion
- 📊 **Status Tracking**: Visual progress of implementation
- 🧪 **Test Generation**: Auto-generated unit tests
- 🛡️ **Preservation**: Manual changes never overwritten

## Architecture
This system is unique in combining:
- Design-first control flow specifications
- AI-friendly natural language communication
- Automatic mock code and test generation
- Smart updates that preserve manual modifications