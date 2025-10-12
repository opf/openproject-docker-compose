# Control Flows for OpenProject Docker Compose

## Entry Points (How this component gets called)

### Docker Compose Commands (Primary Interface)
- `docker compose up` ← Called from: CLI for main stack startup
- `docker compose -f docker-compose.control.yml up` ← Called from: CLI for control operations  
- `backup` ← Called from: control containers for data backup
- `upgrade` ← Called from: control containers for PostgreSQL upgrades
- `autoheal` ← Called from: Docker daemon for container health monitoring

### Orchestration Entry Points  
- `main_stack()` ← Called from: docker-compose.yml orchestration
- `control_operations()` ← Called from: docker-compose.control.yml
- `proxy_integration()` ← Called from: external systems via Caddy proxy

## Internal Flow (Key decision points in order)

### Main Configuration Process (`run_full_process`)
1. **Initialization**: Create ConfigurationManager with project root
2. **Phase 1 - Discovery**: 
   - Environment discovery (detect Docker, system info)
   - System discovery (ports, services, resources)  
   - Docker discovery (existing containers, networks)
3. **Phase 2 - Interactive Collection**:
   - Present UI for user input collection
   - Collect OpenProject-specific configurations
   - Handle namespace/URI configuration
4. **Phase 3 - Validation**:
   - Validate collected configuration
   - Check for conflicts and requirements
   - Option to continue on validation failures
5. **Phase 4 - Export**:
   - Export configuration to file format
   - Generate deployment-ready configuration

### Update Process (`update`)
1. **Load Existing**: Parse existing configuration file
2. **Merge Discovery**: Combine with current environment discovery
3. **Interactive Updates**: Allow user to modify specific settings
4. **Re-validate**: Ensure updated configuration is valid
5. **Re-export**: Save updated configuration

## Exit Points (What this component returns/calls)

### Returns to Main Repo
- **Configuration file path**: String path to generated `.cfg` file
- **Configuration object**: Complete configuration data structure
- **Exit codes**: 0 (success), 1 (failure), 1 (user cancelled)

### Calls to Other Components
- **External calls**: None to other OpenProject repos
- **System calls**: Docker API, system resource checks
- **File operations**: Read/write configuration files

### Output Formats
- **Primary**: Configuration file (`.cfg` format)
- **Secondary**: JSON export (optional)
- **Logs**: Rich console output with progress indicators

## External Calls (Dependencies on other repos)

### No Direct External Repo Calls
Config Manager is designed to be self-contained:
- **Does NOT call**: deploy-manager (deploy-manager calls this)
- **Does NOT call**: prober (prober may call this for discovery)
- **Does NOT call**: control components

### External System Dependencies
- **Docker API**: Container and network discovery
- **System APIs**: Port scanning, resource detection
- **File System**: Project root analysis, config file I/O

## Component Architecture

```
main.py (CLI) 
    ↓
ConfigurationManager (core/manager.py)
    ↓
┌─── Discovery Phase ────┐    ┌─── Collection Phase ───┐
│ • EnvironmentDiscovery │    │ • InteractiveCollector │
│ • SystemDiscovery      │    │ • ConsoleUI            │  
│ • DockerDiscovery      │    │ • User Input Handling  │
└────────────────────────┘    └────────────────────────┘
    ↓                              ↓
┌─── Validation Phase ───┐    ┌─── Export Phase ───────┐
│ • ConfigurationValidator│    │ • CfgWriter           │
│ • Conflict Detection   │    │ • File Generation     │
│ • Requirement Checking │    │ • Output Formatting   │
└────────────────────────┘    └───────────────────────┘
```

## Key Decision Points

1. **Project Root Detection**: Auto-detect vs explicit path
2. **Discovery Scope**: Full vs minimal discovery based on environment
3. **Validation Strictness**: Fail on warnings vs continue with warnings  
4. **Output Format**: Default `.cfg` vs custom format/location
5. **Update Strategy**: Merge vs replace when updating existing configs

## Notes
- **Self-contained**: Does not depend on other OpenProject repos
- **Called by others**: Main repo and potentially deploy-manager use this
- **Stateless**: Each run is independent (except for update mode)
- **Interactive**: Requires user input during collection phase
- **Graceful degradation**: Can work with partial discovery results