# Configuration Variable Flow Summary

## Overview

This document summarizes the **configuration variable flow** from the Configuration Manager to the Deployment Manager in the OpenProject Python rebuild architecture.

## Primary Configuration Flow

```
Configuration Manager → .cfg file → Deployment Manager
```

### **1. Configuration Manager Output**

**Primary File**: `interactive_config.cfg`  
**Format**: Bash-style key="value" pairs  
**Purpose**: Complete deployment configuration for consumption by Deployment Manager

**Generation Process**:
1. **Discovery Phase**: Auto-detect environment variables
2. **Interactive Phase**: Collect user preferences via Rich UI
3. **Validation Phase**: Validate with Prober utility integration
4. **Export Phase**: Generate `interactive_config.cfg` file

### **2. Deployment Manager Input**

**Primary Input**: `interactive_config.cfg`  
**Usage**: Load configuration → Template rendering → Docker deployment  
**Process**: Parse .cfg → Convert to formats → Deploy services

## Configuration Variables Specification

### **Core OpenProject Configuration**
```bash
# Application settings
TAG="16-slim"
OPENPROJECT_HOST__NAME="myproject.example.com"
DOMAIN_NAME="myproject.example.com"
OPENPROJECT_RAILS__RELATIVE__URL__ROOT="/openproject"

# Network settings
OPENPROJECT_HTTPS="true"
PORT="8080"
HTTPS_PORT="8443"
```

### **Database Configuration**
```bash
DATABASE_URL="postgres://postgres:secure_password@db/openproject?pool=20&encoding=unicode&reconnect=true"
POSTGRES_PASSWORD="secure_password"
RAILS_MIN_THREADS="4"
RAILS_MAX_THREADS="16"
```

### **Proxy and Security Settings**
```bash
PROXY_TYPE="caddy"
SSL_EMAIL="admin@example.com"
SECURITY_HEADERS_ENABLED="true"
RATE_LIMITING_ENABLED="true"
REDIRECT_HTTP_TO_HTTPS="true"
```

### **Storage Configuration**
```bash
OPDATA="/var/openproject/assets"
PGDATA="/var/lib/postgresql/data"
BACKUP_PATH="/var/openproject/backups"
```

### **Auto-Discovery Variables**
```bash
# Environment information discovered by Configuration Manager
DISCOVERED_OS="ubuntu"
DISCOVERED_DOCKER_VERSION="24.0.5"
DISCOVERED_EXTERNAL_IP="203.0.113.42"
AVAILABLE_PORTS="80,443,8080,8443"
```

### **Deployment Settings**
```bash
# Deployment behavior controls
PROBER_ENABLED="true"
PULL_IMAGES="true"
HEALTH_CHECK_TIMEOUT="300"
DRY_RUN="false"
```

### **Optional Features**
```bash
# Email configuration
IMAP_ENABLED="false"
SMTP_HOST="smtp.example.com"

# Advanced settings
MONITORING_ENABLED="true"
LOG_LEVEL="info"
```

## Configuration Processing in Deployment Manager

### **1. Configuration Loading**
```python
# Load .cfg file
config = ConfigurationLoader.load_cfg_file("interactive_config.cfg")

# Validate required keys
validation = ConfigurationLoader.validate_required_keys(config)
```

### **2. Format Conversion**
```python
# Convert to Docker Compose .env format
env_vars = ConfigurationLoader.convert_to_env_format(config)

# Extract Jinja2 template variables
template_vars = ConfigurationLoader.extract_template_variables(config)
```

### **3. Template Rendering**
```python
# Render Caddyfile with configuration
renderer = TemplateRenderer("templates/")
caddyfile = renderer.render("Caddyfile.j2", template_vars)
```

### **4. Deployment Execution**
```python
# Deploy with configuration
orchestrator = DeploymentOrchestrator(config)
result = orchestrator.deploy(dry_run=False)
```

## Integration Examples

### **Configuration Manager Side**
```python
# Generate configuration file
from openproject_config_manager import ConfigurationOrchestrator

orchestrator = ConfigurationOrchestrator()
result = orchestrator.run_interactive()

# Output: interactive_config.cfg
print(f"Configuration saved to: {result.cfg_path}")
```

### **Deployment Manager Side**
```python
# Consume configuration file
from openproject_deploy_manager import DeploymentOrchestrator

orchestrator = DeploymentOrchestrator(
    config_file="interactive_config.cfg",
    template_dir="templates/"
)

result = orchestrator.deploy()
```

### **Main CLI Integration**
```bash
# Full workflow
openproject configure                # → interactive_config.cfg
openproject deploy                   # → reads interactive_config.cfg
```

## File Relationships

```
Configuration Manager Output:
├── interactive_config.cfg          # Primary configuration (→ Deploy Manager)
├── .env                            # Docker Compose environment (optional)
└── config_backup.cfg              # Backup of previous configuration

Deployment Manager Processing:
├── interactive_config.cfg          # Input configuration
├── templates/
│   ├── Caddyfile.j2                # → rendered Caddyfile
│   └── docker-compose.override.j2  # → rendered overrides
└── deployment_state.json          # Deployment metadata
```

## Benefits of .cfg Format

1. **Human Readable**: Standard bash key="value" format
2. **Version Control Friendly**: Text-based, easy to diff
3. **Extensible**: New variables can be added without breaking existing code
4. **Compatible**: Works with existing bash scripts during migration
5. **Comprehensive**: Single source of truth for all deployment variables

## Future Extensions

The configuration variable set can be extended as needed:

- **New OpenProject features**: Additional environment variables
- **Enhanced security**: Additional SSL/TLS options
- **Monitoring integration**: Metrics and alerting configuration
- **Cloud providers**: Provider-specific deployment settings
- **Multi-instance**: Support for multiple OpenProject instances

---

**Note**: This variable specification will evolve as the implementation progresses, but the core .cfg file format and flow remain stable.