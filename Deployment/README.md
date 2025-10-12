# Deployment Manager

**External Repository**: [`openproject-deploy-manager`](https://github.com/JustinCBates/openproject-deploy-manager)  
**Submodule Location**: `external/deploy-manager/`  
**Purpose**: Deployment orchestration with health checking and rollback capabilities

## Overview

The Deployment Manager is developed as a **standalone, reusable component** in its own repository. This folder serves as a **placeholder and documentation** for the deployment orchestration functionality.

## Repository Structure

```
external/deploy-manager/          # Git submodule (actual implementation)
Deployment/                       # This folder (documentation & integration)
├── README.md                     # This file
├── INTEGRATION.md               # How to integrate with main project
├── templates/                   # OpenProject-specific templates
│   ├── Caddyfile.template.j2
│   └── docker-compose.override.yml.j2
└── examples/                    # Usage examples
```

## Key Features

- **Deployment Orchestration**: Complete Docker Compose lifecycle management
- **Template Rendering**: Jinja2 templates for dynamic configuration
- **Health Checking**: Comprehensive service health validation
- **Preflight Validation**: Pre-deployment checks with prober integration
- **Automatic Rollback**: State snapshots and failure recovery
- **Progress Monitoring**: Real-time deployment status and logging

## Control Flow

### Phase 1: Pre-deployment Validation
```
DeploymentOrchestrator.deploy()
├── Configuration Validation
├── Environment Validation (Docker, ports, permissions)
└── Prober Preflight Check (DNS, SSL, connectivity)
```

### Phase 2: Template Rendering
```
TemplateRenderer.render_all()
├── Load Jinja2 templates
├── Render with configuration context
├── Validate rendered output syntax
└── Write files to deployment directory
```

### Phase 3: Deployment Execution
```
Docker Deployment Pipeline
├── Create Deployment Snapshot (for rollback)
├── Image Management (pull, verify)
├── Service Orchestration (down → up)
└── Monitor startup progress
```

### Phase 4: Health Checking
```
HealthChecker.validate_deployment()
├── Container Health Checks
├── Service Endpoint Testing
├── Integration Testing
└── Performance Validation
```

### Phase 5: Post-deployment & Monitoring
```
Deployment Finalization
├── Success Path (logging, cleanup, notifications)
├── Failure Path (rollback, alerts)
└── Monitoring Setup
```

## Core Components

### 1. Deployment Orchestrator (`orchestrator.py`)
**Main entry point for deployment operations**

```python
class DeploymentOrchestrator:
    def __init__(config: dict, docker_client: DockerClient)
    def validate_deployment() -> ValidationResult
    def deploy(dry_run: bool = False, prober_enabled: bool = True) -> DeploymentResult
    def rollback() -> RollbackResult
    def get_status() -> DeploymentStatus
```

### 2. Template Renderer (`template_renderer.py`)
**Jinja2 template processing for dynamic configuration**

```python
class TemplateRenderer:
    def __init__(template_dir: Path)
    def render(template_name: str, context: dict) -> str
    def render_to_file(template_name: str, output_path: Path, context: dict) -> None
    def validate_rendered(content: str, validator: Callable) -> ValidationResult
```

### 3. Health Checker (`health_checker.py`)
**Comprehensive service health validation**

```python
class HealthChecker:
    def __init__(docker_client: DockerClient)
    def check_service(service_name: str) -> HealthStatus
    def check_endpoint(url: str, timeout: int) -> EndpointStatus
    def wait_for_healthy(services: List[str], timeout: int) -> HealthCheckResult
```

## Integration with Main Project

The Deployment Manager receives configuration from the Configuration Manager and orchestrates deployment:

```python
from openproject_deploy_manager import DeploymentOrchestrator

# Receive config from Configuration Manager
config = config_manager.get_deployment_config()

# Execute deployment
orchestrator = DeploymentOrchestrator(
    config=config,
    compose_file="docker-compose.yml",
    template_dir="Deployment/templates/",
    prober_enabled=True
)

result = orchestrator.deploy(dry_run=False)
```

## OpenProject-Specific Templates

### Caddyfile Template (`templates/Caddyfile.template.j2`)
```jinja2
{{ domain_name }}{% if url_prefix %}{{ url_prefix }}{% endif %} {
    {% if https_enabled %}
    tls {{ ssl_email }}
    {% endif %}
    
    reverse_proxy web:3000 {
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

### Docker Compose Override (`templates/docker-compose.override.yml.j2`)
```yaml
version: '3.8'
services:
  proxy:
    ports:
      - "{{ http_port }}:80"
      {% if https_enabled %}
      - "{{ https_port }}:443"
      {% endif %}
    environment:
      DOMAIN_NAME: "{{ domain_name }}"
      
  web:
    environment:
      OPENPROJECT_HOST__NAME: "{{ domain_name }}"
      OPENPROJECT_HTTPS: "{{ https_enabled }}"
```

## CLI Integration

```bash
# Main project CLI delegates to deploy manager
openproject deploy                 # Full deployment
openproject deploy --dry-run       # Validate without deploying
openproject deploy --no-prober     # Skip prober preflight
openproject status                 # Check deployment status
openproject rollback               # Rollback to previous state
```

## Error Handling & Recovery

1. **Validation Failures**: Stop before deployment, detailed error reporting
2. **Template Errors**: Syntax validation with clear error messages
3. **Docker Failures**: Automatic rollback to previous container state
4. **Health Check Failures**: Detailed health status with recovery suggestions
5. **Network Issues**: Retry mechanisms with exponential backoff

## Development Status

- ✅ **Repository Created**: External repo ready for development
- ✅ **Architecture Designed**: 5-phase deployment orchestration
- ✅ **Integration Points**: Defined interfaces with other managers
- 🔄 **Template Structure**: OpenProject-specific templates designed
- ⏳ **Implementation**: Core orchestration logic planned
- ⏳ **Testing**: Integration testing with Docker environments

## Dependencies

**External Dependencies** (in external repo):
- `docker>=7.0.0` - Docker SDK for container management
- `jinja2>=3.0` - Template rendering
- `click>=8.1.0` - CLI framework
- `pyyaml>=6.0` - Configuration file handling

**Integration Dependencies** (this project):
- Configuration Manager for validated config
- Prober utility for preflight validation
- Management Manager for post-deployment operations

## Next Steps

1. **Initialize External Repo**: Set up project structure in `openproject-deploy-manager`
2. **Implement Orchestrator**: Core deployment logic with Docker integration
3. **Build Template Engine**: Jinja2 rendering with validation
4. **Add Health Checking**: Service health monitoring and validation
5. **Implement Rollback**: State management and recovery mechanisms
6. **Test Integration**: End-to-end deployment testing

---

**Note**: This folder is for **documentation and integration** only. The actual implementation lives in the external `openproject-deploy-manager` repository and is consumed as a git submodule.

For development, work in: `external/deploy-manager/`  
For integration, reference: `Deployment/`  
For templates, edit: `Deployment/templates/`