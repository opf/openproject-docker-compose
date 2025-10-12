# Configuration Manager

**External Repository**: [`openproject-config-manager`](https://github.com/JustinCBates/openproject-config-manager)  
**Submodule Location**: `external/config-manager/`  
**Purpose**: Interactive configuration discovery and management  

## Overview

The Configuration Manager is developed as a **standalone, reusable component** in its own repository. This folder serves as a **placeholder and documentation** for the configuration management functionality.

## Repository Structure

```
external/config-manager/          # Git submodule (actual implementation)
Configuration/                    # This folder (documentation & integration)
├── README.md                     # This file
├── INTEGRATION.md               # How to integrate with main project
└── examples/                    # Usage examples
```

## Key Features

- **Environment Discovery**: Automatically probe OS, Docker, network, certificates
- **Interactive UI**: Rich-based terminal interface with smart defaults  
- **Live Validation**: Real-time configuration testing with prober integration
- **Multi-format Output**: Generates `.env`, `.cfg`, and template variables
- **Resumable Sessions**: Continue interrupted configuration sessions

## Control Flow

### Phase 1: Environment Discovery & Probing
```
OS Probe → Generate .cfg.defaults
├── Detect OS (Linux distro, version, architecture)
├── Scan network interfaces & available IPs  
├── Check Docker installation & version
├── Scan available ports (80, 443, 8080, etc.)
├── Detect existing SSL certificates
├── Check system resources (RAM, disk space)
└── Write .cfg.defaults with intelligent defaults
```

### Phase 2: Interactive Configuration Collection
```
Rich Interactive UI → Generate .cfg
├── Load .cfg.defaults as starting point
├── Present Rich-based prompts with smart defaults
├── Collect user preferences (domain, ports, database, etc.)
├── Real-time validation during input
└── Save final .cfg file
```

### Phase 3: Pre-Deploy Validation
```
Validation Pass → Prober Integration
├── Load .cfg file
├── Validate configuration completeness
├── Use Prober utility for live testing
├── Present validation results
└── Option to loop back to Phase 2 if issues found
```

### Phase 4: Final Configuration Export
```
Export for Deployment
├── Convert .cfg to .env format
├── Generate Docker Compose overrides
├── Prepare Jinja2 template variables
└── Hand off to Deploy Manager
```

## Integration with Main Project

The Configuration Manager is consumed by the main OpenProject deployment system:

```python
from openproject_config_manager import ConfigurationOrchestrator

# Run interactive configuration
orchestrator = ConfigurationOrchestrator()
config_result = orchestrator.run_interactive(
    template="openproject",
    prober_enabled=True
)

# Use result in deployment
deploy_config = config_result.deployment_config
```

## CLI Integration

```bash
# Main project CLI delegates to config manager
openproject configure              # Interactive configuration
openproject config show           # Display current config
openproject config validate       # Validate configuration
```

## Development Status

- ✅ **Repository Created**: External repo exists with CI/CD pipeline
- ✅ **Architecture Designed**: 4-phase control flow documented
- ✅ **Integration Points**: Defined interfaces with other managers
- 🔄 **Implementation**: Core functionality being developed
- ⏳ **Testing**: Comprehensive test suite planned

## Dependencies

**External Dependencies** (in external repo):
- `rich>=13.0.0` - Terminal UI
- `click>=8.1.0` - CLI framework
- `docker>=7.0.0` - Docker SDK for discovery
- `python-dotenv>=1.0.0` - Configuration file handling

**Integration Dependencies** (this project):
- Prober utility for validation
- Deploy Manager for handoff
- Main CLI for orchestration

## Next Steps

1. **Initialize External Repo**: Set up project structure in `openproject-config-manager`
2. **Implement Discovery Engine**: OS and environment probing
3. **Build Interactive UI**: Rich-based configuration collection
4. **Integrate Prober**: Live validation capabilities
5. **Test Integration**: End-to-end testing with main project

---

**Note**: This folder is for **documentation and integration** only. The actual implementation lives in the external `openproject-config-manager` repository and is consumed as a git submodule.

For development, work in: `external/config-manager/`  
For integration, reference: `Configuration/`