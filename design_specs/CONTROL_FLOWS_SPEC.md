# Control Flow Specification - OpenProject Docker Compose

> **Design-first specification for iterative development**  
> Use this to communicate orchestration flow changes before implementation exists

## Entry Points
```yaml
main_stack:
  status: IMPLEMENTED
  description: "Main OpenProject stack orchestration"
  calls: [web, db, cache, proxy, worker, cron, seeder, autoheal]
  
control_operations:
  status: IMPLEMENTED  
  description: "Control plane operations (backup/upgrade)"
  flow_id: "control_operations_flow"

proxy_integration:
  status: IMPLEMENTED
  description: "Caddy proxy integration and routing"
  flow_id: "proxy_flow"
```

## Flow Implementations
```yaml
main_orchestration_flow:
  description: "Primary OpenProject Stack Orchestration"
  flow_steps:
    - step_id: "init"
      name: "Initialize Stack"
      status: IMPLEMENTED
      description: "Start core services (db, cache)"
      
    - step_id: "application"
      name: "Application Services"
      status: IMPLEMENTED
      description: "Run environment, system, and Docker discovery"
      sub_flows: ["discovery_flow"]
      
    - step_id: "collection"
      name: "Interactive Collection"
      status: IMPLEMENTED
      description: "Collect user configuration via UI"
      
    - step_id: "validation"
      name: "Validation Phase"
      status: IMPLEMENTED
      description: "Validate collected configuration"
      sub_flows: ["validation_flow"]
      decision_point: "continue_on_validation_failure"
      
    - step_id: "export"
      name: "Export Phase"
      status: IMPLEMENTED
      description: "Export configuration to file"
      sub_flows: ["export_flow"]
      
  planned_insertions:
    - insert_after: "collection"
      step_id: "pre_validation_cleanup"
      name: "Pre-validation Cleanup"
      status: PLANNED
      description: "Clean up configuration before validation"
      
    - insert_before: "export"
      step_id: "final_review"
      name: "Final Review"
      status: PLANNED
      description: "Show summary for user approval before export"

discovery_flow:
  description: "Environment Discovery"
  flow_steps:
    - step_id: "env_discovery"
      name: "Environment Variables"
      status: IMPLEMENTED
      description: "Discover relevant environment variables"
      
    - step_id: "system_discovery"
      name: "System Information"
      status: IMPLEMENTED
      description: "Detect system resources and platform"
      
    - step_id: "docker_discovery"
      name: "Docker Environment"
      status: IMPLEMENTED
      description: "Discover Docker containers and networks"
      
  planned_insertions:
    - insert_after: "docker_discovery"
      step_id: "network_discovery"
      name: "Network Discovery"
      status: TODO
      description: "Discover network topology and conflicts"
```

## Decision Points
```yaml
continue_on_validation_failure:
  type: "user_confirmation"
  prompt: "Validation failed. Continue anyway?"
  default: false
  implemented: true
  
use_custom_output_path:
  type: "parameter_check"
  condition: "output parameter provided"
  implemented: true

confirm_destructive_changes:
  type: "user_confirmation"
  prompt: "This will overwrite existing configuration. Continue?"
  default: false
  implemented: false
  insert_before_step: "export.write_file"
```