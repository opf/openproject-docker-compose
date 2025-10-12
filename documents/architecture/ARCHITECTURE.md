# OpenProject Python Rebuild - Global Architecture

## Executive Summary

This document defines the global architecture for the Python-based rebuild of the OpenProject Docker Compose deployment system. The goal is to replace Bash scripts with a maintainable, testable Python codebase while maintaining backward compatibility.

### Multi-Repository Architecture

This project uses a **modular multi-repository architecture** for maximum reusability and separation of concerns:

- **[openproject-config-manager](https://github.com/JustinCBates/openproject-config-manager)** - Standalone configuration tool (reusable)
- **[openproject-deploy-manager](https://github.com/JustinCBates/openproject-deploy-manager)** - Standalone deployment orchestrator (reusable)
- **[docker-prober-utility](https://github.com/JustinCBates/docker_prober_utility)** - Validation and testing utility (reusable)
- **openproject-docker-compose** (this repo) - OpenProject-specific orchestration and maintenance

This repository serves as the **integration point** that orchestrates the standalone managers and provides OpenProject-specific functionality (backup, upgrade, migrations).

---

## Design Principles

1. **Separation of Concerns**: Each component has a single, well-defined responsibility
2. **Testability**: All components are unit-testable and integration-testable
3. **Backward Compatibility**: Works with existing `.env` and configuration files
4. **Fail-Safe**: Robust error handling, validation, and rollback capabilities
5. **Progressive Enhancement**: Can coexist with existing Bash scripts during migration
6. **Observable**: Comprehensive logging and status reporting
7. **Idempotent**: Operations can be safely retried without side effects
8. **Modularity**: Core managers are standalone, reusable components

---

## Multi-Repository Strategy

### **Repository Roles**

#### **1. openproject-config-manager** (External Dependency)
**Repository**: https://github.com/JustinCBates/openproject-config-manager  
**Purpose**: Generic, reusable configuration management for Docker Compose projects

**Responsibilities**:
- Environment discovery (OS, network, Docker, ports, certificates)
- Interactive configuration collection (Rich-based terminal UI)
- Configuration validation (completeness, consistency, live testing)
- Integration with docker-prober-utility for real-time validation
- Generate `.env` and `.cfg` files

**Reusability**: Can be used for any Docker Compose project requiring interactive configuration

**Dependencies**: 
- `rich` - Terminal UI
- `docker` - Docker SDK
- `pyyaml` - Config parsing
- `docker-prober-utility` - Live validation

---

#### **2. openproject-deploy-manager** (External Dependency)
**Repository**: https://github.com/JustinCBates/openproject-deploy-manager  
**Purpose**: Generic, reusable deployment orchestration for Docker Compose stacks

**Responsibilities**:
- Load configuration from multiple sources
- Render Jinja2 templates (Caddyfile, nginx.conf, etc.)
- Orchestrate docker-compose lifecycle (up, down, restart)
- Health checking and service validation
- Integration with docker-prober-utility for pre-deployment testing
- Automatic rollback on failure

**Reusability**: Can orchestrate deployment of any Docker Compose stack

**Dependencies**:
- `docker` - Docker SDK
- `jinja2` - Template rendering
- `pyyaml` - Config parsing
- `docker-prober-utility` - Pre-deployment validation

---

#### **3. docker-prober-utility** (External Dependency)
**Repository**: https://github.com/JustinCBates/docker_prober_utility  
**Purpose**: HTTP/HTTPS endpoint validation and testing utility

**Responsibilities**:
- Test HTTP/HTTPS endpoints
- Validate TLS configuration
- Test reverse proxy URL rewriting
- Test response headers and status codes
- Generate validation reports and recommendations

**Reusability**: Used by both config-manager and deploy-manager for validation

**Dependencies**:
- `docker` - Docker SDK
- `requests` - HTTP testing

---

#### **4. openproject-docker-compose** (This Repository)
**Repository**: https://github.com/JustinCBates/openproject-docker-compose  
**Purpose**: OpenProject-specific deployment integration and maintenance

**Responsibilities**:
- Orchestrate config-manager and deploy-manager
- OpenProject-specific templates (Caddyfile, docker-compose overrides)
- Maintenance operations (backup, upgrade, migrations)
- CLI interface wrapping all managers
- OpenProject deployment documentation

**OpenProject-Specific Components**:
- Maintenance Manager (backup, upgrade, migrations)
- OpenProject templates
- CLI orchestration layer

**Dependencies**:
- `openproject-config-manager` (external repo)
- `openproject-deploy-manager` (external repo)
- `docker-prober-utility` (external repo)

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│         openproject-docker-compose (Main Repo)              │
│                                                             │
│  ├─ CLI (orchestrates external managers)                   │
│  ├─ Maintenance Manager (OpenProject-specific)             │
│  └─ Templates (OpenProject-specific Jinja2 templates)      │
│                                                             │
│  External Dependencies:                                     │
│  ├─ openproject-config-manager  ────────────┐              │
│  ├─ openproject-deploy-manager  ──────────┐ │              │
│  └─ docker-prober-utility  ──────────┐    │ │              │
└──────────────────────────────────────┼────┼─┼──────────────┘
                                       │    │ │
                                       ▼    ▼ ▼
┌──────────────────────────────────────────────────────────────┐
│              Standalone Repositories                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │ docker-prober-utility│  │ config-manager       │        │
│  │  (validation tool)   │  │  (interactive setup) │        │
│  │                      │  │                      │        │
│  │ - HTTP/HTTPS testing │  │ - Discovery Engine   │        │
│  │ - TLS validation     │  │ - Interactive UI     │        │
│  │ - Endpoint probing   │  │ - Validation Engine  │        │
│  │ - Recommendations    │  │ - Uses Prober ───────┼────────┤
│  └──────────────────────┘  └──────────────────────┘        │
│                                                              │
│  ┌──────────────────────┐                                   │
│  │ deploy-manager       │                                   │
│  │  (orchestration)     │                                   │
│  │                      │                                   │
│  │ - Template Rendering │                                   │
│  │ - Docker Compose Ops │                                   │
│  │ - Health Checks      │                                   │
│  │ - Rollback Logic     │                                   │
│  │ - Uses Prober ───────┼───────────────────────────────────┤
│  └──────────────────────┘                                   │
└──────────────────────────────────────────────────────────────┘
```

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLI Interface Layer                          │
│                    (openproject_deploy.cli)                         │
│  Commands: config, validate, deploy, backup, upgrade, test          │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Core Business Logic Layer                       │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   Config     │  │  Deployment  │  │   Control    │             │
│  │   Manager    │  │ Orchestrator │  │   Plane      │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  Template    │  │    Health    │  │  Integration │             │
│  │   Renderer   │  │   Checker    │  │    Tester    │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Infrastructure Layer                             │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   Docker     │  │  File System │  │   Process    │             │
│  │   Client     │  │   Manager    │  │   Manager    │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

This section defines the **three main manager** components and how they interact. Note that **Configuration Manager** and **Deploy Manager** are developed in **external repositories** and consumed as dependencies, while **Maintenance Manager** remains in this repository.

---

## 1. Configuration Manager 
**Repository**: [openproject-config-manager](https://github.com/JustinCBates/openproject-config-manager)  
**Status**: 🔜 To be implemented (Phase 1.5 - HIGH PRIORITY)  
**Consumed by**: openproject-docker-compose (this repo) as external dependency

**Purpose**: Provide generic, reusable configuration management for Docker Compose projects with intelligent discovery, interactive UI, and live validation

### 1.1 Core Configuration (`config_manager.py`)
### 1.1 Core Configuration (`config_manager.py`)
**Status**: ✅ Implemented (Phase 1 - in this repo, will migrate to config-manager repo)

**Responsibilities**:
- Load configuration from multiple sources (.env, .cfg, environment variables)
- Validate required keys and values
- Apply defaults with override chain
- Save configuration to disk
- Mask sensitive values in output

**Interface**:
```python
class ConfigManager:
    def __init__(env_file: Path, cfg_file: Path)
    def get(key: str, default: str) -> str
    def set(key: str, value: str) -> None
    def validate() -> tuple[bool, List[str]]
    def save_env(path: Path) -> None
    def save_cfg(path: Path) -> None
    def get_summary() -> str
```

**Dependencies**: python-dotenv

---

### 1.2 Interactive Configuration System (`interactive/`)
**Status**: 🔜 To be implemented in openproject-config-manager repo

**Note**: See detailed architecture in `INTERACTIVE_CONFIG_ARCHITECTURE.md`

**Responsibilities**:
- Guide users through configuration setup with intelligent, interactive UI
- Auto-discover environment defaults (OS, network, Docker, ports, certificates)
- Collect user preferences with smart defaults and validation
- **Integrate with Prober for live configuration validation**
- Generate final configuration files (.env, .cfg)

**Sub-Components**:

**1a.1 Discovery Engine** (`interactive/discovery.py`)
- Detect OS, network, Docker installation, available ports
- Scan for existing installations and certificates
- Suggest intelligent defaults based on environment

**1a.2 Interactive Collector** (`interactive/collector.py`)
- Beautiful Rich-based terminal UI
- Progressive question flow (7 sections)
- Real-time input validation
- Smart defaults from discovery
- Support for resume/back/skip

**1a.3 Validation Engine** (`interactive/validation.py`)
- Validate configuration completeness and consistency
- Check network reachability and port availability
- **Invoke Prober for live endpoint testing**
- Generate actionable recommendations

**1a.4 Prober Client** (`interactive/prober_client.py`)
- Interface to external docker_prober_utility
- Launch minimal test environment with user's config
- Test HTTP/HTTPS, TLS, URL rewriting, headers
- Return detailed test results and recommendations

**1a.5 Configuration Finalizer** (`interactive/finalizer.py`)
- Merge discovery + user input + validation fixes
- Generate .env and .cfg files
- Create backups of existing configs
- Provide next-step instructions

**1a.6 Interactive Orchestrator** (`interactive/orchestrator.py`)
- Coordinate 4-phase flow: Discovery → Collection → Validation → Finalization
- Handle interruptions and resume capability
- Manage state between phases

**Interface**:
```python
class InteractiveConfigOrchestrator:
    def __init__(config_manager: ConfigManager, prober_client: ProberClient)
    def run_interactive_config(resume: bool = False) -> ConfigurationResult
    
class DiscoveryEngine:
    def discover_all() -> DiscoveryResults
    def discover_system() -> SystemInfo
    def discover_network() -> NetworkInfo
    def discover_docker() -> DockerInfo
    
class InteractiveCollector:
    def collect_configuration() -> CollectedConfig
    def collect_section(section: ConfigSection) -> SectionResult
    
class ValidationEngine:
    def validate_all() -> ValidationReport
    def validate_live_with_prober() -> ProberValidation
    
class ProberClient:
    def test_configuration(config: Dict[str, str]) -> ProberTestResult
    def cleanup() -> None
    
class ConfigurationFinalizer:
    def finalize() -> FinalizationResult
    def write_env_file(path: Path) -> None
    def write_cfg_file(path: Path) -> None
```

**Configuration Flow**:
```
1. Discovery Engine
   ├─ Detect OS family and version
   ├─ Discover network (hostname, IP, DNS)
   ├─ Check Docker installation and status
   ├─ Scan available ports
   └─ Check for certificates

2. Interactive Collector (7 Sections)
   ├─ Environment Type (prod/dev/staging)
   ├─ Repository & Version
   ├─ Network Configuration (domain, ports)
   ├─ URL Configuration (prefix, namespace)
   ├─ Proxy Configuration (TLS, redirects)
   ├─ Database Configuration
   └─ Application Storage

3. Validation Engine
   ├─ Validate completeness
   ├─ Check port availability
   ├─ Test network reachability
   └─ **Live validation with Prober**
       ├─ Launch minimal test environment
       ├─ Test HTTP endpoint
       ├─ Test HTTPS endpoint (if enabled)
       ├─ Test URL rewriting (if namespace)
       ├─ Verify TLS configuration
       └─ Return recommendations

4. Configuration Finalizer
   ├─ Backup existing configs
   ├─ Merge all config sources
   ├─ Write .env file
   ├─ Write interactive_config.cfg
   └─ Display next steps
```

**Dependencies**: rich, docker, docker_prober_utility (external), ConfigManager

**CLI Integration** (from openproject-docker-compose):
```bash
openproject configure --interactive     # Run interactive config
openproject configure --resume          # Resume interrupted config
openproject configure --template=prod   # Use predefined template (future)
openproject config show                 # Display current config
openproject config set KEY=VALUE        # Set individual config value
```

---

## 2. Deploy Manager
**Repository**: [openproject-deploy-manager](https://github.com/JustinCBates/openproject-deploy-manager)  
**Status**: 🔜 To be implemented (Phase 2)  
**Consumed by**: openproject-docker-compose (this repo) as external dependency

**Purpose**: Provide generic, reusable deployment orchestration for Docker Compose stacks with health checking, rollback, and live validation

### 2.1 Deployment Orchestrator (`orchestrator.py`)
### 2.1 Deployment Orchestrator (`orchestrator.py`)
**Status**: 🔄 To be implemented in openproject-deploy-manager repo

**Responsibilities**:
- Orchestrate the full deployment lifecycle
- Validate configuration before deployment
- Coordinate template rendering, docker-compose execution, and health checks
- **Integrate with Prober for pre-deployment validation**
- Handle rollback on failure
- Report deployment status

**Interface**:
```python
class DeploymentOrchestrator:
    def __init__(config: dict, docker_client: DockerClient)
    def validate_deployment() -> ValidationResult
    def deploy(dry_run: bool = False, prober_enabled: bool = True) -> DeploymentResult
    def rollback() -> RollbackResult
    def get_status() -> DeploymentStatus
    
class ValidationResult:
    is_valid: bool
    errors: List[ValidationError]
    warnings: List[str]
    prober_results: ProberTestResult  # From docker-prober-utility
    
class DeploymentResult:
    success: bool
    services_started: List[str]
    services_failed: List[str]
    duration: float
    logs: str
```

**Dependencies**: docker, jinja2, docker-prober-utility (external)

**Workflow**:
```
1. Pre-deployment validation
   ├─ Validate configuration completeness
   ├─ Check Docker daemon
   ├─ Verify images available
   ├─ Check port availability
   └─ **Run prober preflight check** (if enabled)

2. Template rendering
   ├─ Render templates (Caddyfile, overrides) via TemplateRenderer
   └─ Validate rendered output

3. Deployment execution
   ├─ Pull latest images (if requested)
   ├─ Create deployment snapshot (for rollback)
   ├─ docker-compose up -d
   └─ Monitor service startup

4. Health checks
   ├─ Wait for services to be healthy via HealthChecker
   ├─ Run smoke tests
   └─ Validate endpoints

5. Post-deployment
   ├─ Report success/failure
   ├─ Clean up temporary files
   └─ Log deployment metadata
```

---

### 2.2 Template Renderer (`template_renderer.py`)
### 2.2 Template Renderer (`template_renderer.py`)
**Status**: 🔜 To be implemented in openproject-deploy-manager repo

**Responsibilities**:
- Render Jinja2 templates with configuration values
- Validate rendered output (syntax, required fields)
- Support custom filters and functions
- Handle template errors gracefully

**Interface**:
```python
class TemplateRenderer:
    def __init__(template_dir: Path)
    def render(template_name: str, context: dict) -> str
    def render_to_file(template_name: str, output_path: Path, context: dict) -> None
    def validate_rendered(content: str, validator: Callable) -> ValidationResult
```

**Templates** (provided by consuming project):
- `Caddyfile.template.j2`: Caddy reverse proxy configuration
- `nginx.conf.j2`: Nginx configuration (alternative)
- `docker-compose.override.yml.j2`: Optional compose overrides

**Dependencies**: jinja2

---

### 2.3 Health Checker (`health_checker.py`)
### 2.3 Health Checker (`health_checker.py`)
**Status**: 🔜 To be implemented in openproject-deploy-manager repo

**Responsibilities**:
- Check service health via Docker API
- Probe HTTP/HTTPS endpoints
- Verify database connectivity (optional)
- Wait for services to become healthy with timeout
- Report detailed health status

**Interface**:
```python
class HealthChecker:
    def __init__(docker_client: DockerClient)
    def check_service(service_name: str) -> HealthStatus
    def check_endpoint(url: str, timeout: int) -> EndpointStatus
    def wait_for_healthy(services: List[str], timeout: int) -> HealthCheckResult
    
class HealthStatus:
    service: str
    is_healthy: bool
    status_message: str
    container_state: str
    
class EndpointStatus:
    url: str
    is_reachable: bool
    status_code: int
    response_time: float
```

**Health Check Strategy**:
1. Docker container health (via healthcheck)
2. HTTP endpoint probes (GET /health or similar)
3. Database connection test (via pg_isready or similar, if applicable)
4. Service-specific checks

**Dependencies**: docker, requests

**CLI Integration** (from openproject-docker-compose):
```bash
openproject deploy                      # Full deployment with health checks
openproject deploy --dry-run            # Validate without deploying
openproject deploy --no-prober          # Skip prober preflight check
openproject status                      # Check current deployment status
```

---

## 3. Maintenance Manager
**Repository**: openproject-docker-compose (this repo)  
**Status**: 🔜 To be implemented (Phase 3)  
**Location**: `src/openproject/maintenance/`

**Purpose**: Provide OpenProject-specific maintenance operations (backup, upgrade, migrations)

**Why in main repo?**
- Highly coupled to OpenProject's database schema and data structure
- PostgreSQL upgrade paths specific to OpenProject versions
- Migration scripts specific to OpenProject version transitions
- Lower reusability (other projects have different maintenance needs)

### 3.1 Backup Manager (`backup.py`)
### 3.1 Backup Manager (`backup.py`)
**Status**: 🔜 To be implemented in openproject-docker-compose (Phase 3)

**Responsibilities**:
- Execute backup operations (PostgreSQL database, OpenProject assets)
- Verify backup integrity
- Manage backup retention policy
- Restore from backups

**Interface**:
```python
class BackupManager:
    def __init__(config: dict)
    def create_backup(backup_type: BackupType) -> BackupResult
    def restore_backup(backup_path: Path) -> RestoreResult
    def verify_backup(backup_path: Path) -> VerificationResult
    def list_backups() -> List[BackupInfo]
    def cleanup_old_backups(retention_days: int) -> CleanupResult
```

**Backup Strategy**:
- Create timestamped backups
- Store in configurable backup directory
- Compress with tar/gzip
- Verify backup integrity after creation
- Maintain backup retention policy

**Dependencies**: docker (uses openproject-deploy-manager's DockerClient)

---

### 3.2 Upgrade Manager (`upgrade.py`)
**Status**: 🔜 To be implemented in openproject-docker-compose (Phase 3)

**Responsibilities**:
- Handle PostgreSQL version upgrades
- Validate upgrade paths
- Execute pg_upgrade safely
- Handle rollback on failure

**Interface**:
```python
class UpgradeManager:
    def __init__(config: dict)
    def check_upgrade_path(target_version: str) -> UpgradePathInfo
    def execute_upgrade(target_version: str, dry_run: bool = False) -> UpgradeResult
    def rollback_upgrade() -> RollbackResult
```

**Upgrade Strategy**:
- Detect current PostgreSQL version
- Validate upgrade path (e.g., PG 13 → 16)
- **Create automatic backup before upgrade** (via BackupManager)
- Run pg_upgrade in controlled container
- Verify upgraded database
- Clean up old data on success

**Dependencies**: docker, BackupManager

---

### 3.3 Migration Manager (`migration.py`)
**Status**: 🔜 To be implemented in openproject-docker-compose (Phase 3 or later)

**Responsibilities**:
- Handle data migrations between OpenProject versions
- Execute schema changes
- Validate migration success

**Interface**:
```python
class MigrationManager:
    def __init__(config: dict)
    def check_pending_migrations() -> List[Migration]
    def execute_migration(migration_id: str, dry_run: bool = False) -> MigrationResult
    def rollback_migration(migration_id: str) -> RollbackResult
```

**CLI Integration** (from openproject-docker-compose):
```bash
openproject backup create               # Create full backup
openproject backup list                 # List available backups
openproject backup restore PATH         # Restore from backup
openproject upgrade --to=16             # Upgrade PostgreSQL to version 16
openproject migrate                     # Run pending migrations
```

---

## 4. Shared Utilities

These utilities are used by all managers and reside in the main openproject-docker-compose repository.

### 4.1 Prober Client Wrapper (`utils/prober_client.py`)
**Status**: 🔜 To be implemented (Phase 1.5)  
**Location**: openproject-docker-compose (main repo)

**Purpose**: Provide a unified interface to docker-prober-utility for all managers

**Interface**:
```python
from docker_prober_utility import ProberClient as ExternalProber

class OpenProjectProberClient:
    """
    Thin wrapper around docker-prober-utility for OpenProject-specific usage.
    Used by both config-manager (quick validation) and deploy-manager (preflight).
    """
    
    def __init__(self, config: dict):
        self.config = config
    
    def validate_for_config(self) -> ValidationResult:
        """Used by config-manager for quick validation during interactive setup"""
        prober = ExternalProber(mode='quick')
        return prober.test_configuration(self.config)
    
    def validate_for_deployment(self) -> ValidationResult:
        """Used by deploy-manager for thorough preflight before deployment"""
        prober = ExternalProber(mode='thorough')
        return prober.pre_deployment_check(self.config)
```

**Why in main repo?**
- Acts as integration glue between external prober and managers
- OpenProject-specific configuration mapping
- Allows versioning of prober integration separately from managers

---

### 4.2 Docker Client (`utils/docker_client.py`)
**Status**: 🔜 To be implemented (Phase 2)  
**Can be moved to deploy-manager repo**

**Purpose**: Simplified Docker SDK wrapper

**Interface**:
```python
class DockerClient:
    def __init__()
    def compose_up(compose_file: Path, services: List[str] = None) -> ComposeResult
    def compose_down(remove_volumes: bool = False) -> ComposeResult
    def get_service_status(service_name: str) -> ServiceStatus
    def get_container_logs(container_id: str, tail: int = 100) -> str
    def pull_image(image_name: str) -> PullResult
    def is_daemon_running() -> bool
```

**Dependencies**: docker

---

### 4.3 Logging, Errors, Validation
**Status**: 🔜 To be implemented (Phase 1 or 2)

**Purpose**: Shared utilities for logging, custom exceptions, and validation helpers

Files:
- `utils/logging.py` - Centralized logging configuration
- `utils/errors.py` - Custom exception classes (ConfigurationError, DeploymentError, etc.)
- `utils/validation.py` - Common validation helpers

---

## Data Flow

### Interactive Configuration Flow (NEW - Phase 1.5)
```
User: openproject configure --interactive
    ↓
InteractiveOrchestrator.run_interactive_config()
    ↓
┌─────────────────────────────────────────────┐
│ Phase 1: Discovery                          │
├─────────────────────────────────────────────┤
│ DiscoveryEngine.discover_all()              │
│  ├─ Detect OS (family, version)             │
│  ├─ Discover Network (hostname, IP, DNS)    │
│  ├─ Check Docker (installed, running)       │
│  ├─ Scan Ports (available, conflicts)       │
│  └─ Find Certificates (existing certs)      │
└─────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────┐
│ Phase 2: Collection                         │
├─────────────────────────────────────────────┤
│ InteractiveCollector.collect_configuration()│
│  ├─ Section 1: Environment Type             │
│  ├─ Section 2: Repository & Version         │
│  ├─ Section 3: Network Configuration        │
│  ├─ Section 4: URL Configuration            │
│  ├─ Section 5: Proxy Configuration          │
│  ├─ Section 6: Database Configuration       │
│  └─ Section 7: Application Storage          │
│  (each with smart defaults from Discovery)  │
└─────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────┐
│ Phase 3: Validation                         │
├─────────────────────────────────────────────┤
│ ValidationEngine.validate_all()             │
│  ├─ Check completeness (all required keys)  │
│  ├─ Check consistency (no conflicts)        │
│  ├─ Test port availability                  │
│  ├─ Test network reachability               │
│  └─ ProberClient.test_configuration()       │
│      ├─ Launch minimal test environment     │
│      ├─ Test HTTP endpoint                  │
│      ├─ Test HTTPS (if TLS enabled)         │
│      ├─ Test URL rewriting (if namespace)   │
│      ├─ Verify TLS configuration            │
│      └─ Return recommendations              │
└─────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────┐
│ Phase 4: Finalization                       │
├─────────────────────────────────────────────┤
│ ConfigurationFinalizer.finalize()           │
│  ├─ Backup existing configs                 │
│  ├─ Merge discovery + user input + fixes    │
│  ├─ Write .env file                         │
│  ├─ Write interactive_config.cfg            │
│  └─ Display next steps                      │
└─────────────────────────────────────────────┘
    ↓
ConfigManager (ready for deployment)
```

### Standard Configuration Flow (Existing)
```
.env.example → .env → ConfigManager → Validation → Deployment
     ↓
interactive_config.cfg → ConfigManager → Validation
     ↓
Environment Variables → ConfigManager (override)
```

### Deployment Flow
```
User CLI Command
    ↓
CLI Parser (click)
    ↓
ConfigManager (load + validate)
    ↓
DeploymentOrchestrator
    ├─ TemplateRenderer (Caddyfile)
    ├─ DockerClient (compose up)
    ├─ HealthChecker (wait for healthy)
    └─ Integration Tester (optional)
    ↓
Deployment Result → User
```

### Backup Flow
```
User CLI Command
    ↓
BackupManager
    ├─ Stop services (via DockerClient)
    ├─ Create snapshots (PostgreSQL + assets)
    ├─ Verify backup integrity
    └─ Restart services
    ↓
Backup Result → User
```

---

## File Structure (Revised)

```
/opt/openproject/
├── pyproject.toml
├── .env.example
├── PROJECT_OVERVIEW.md
├── ARCHITECTURE.md (this file)
├── PYTHON_REBUILD.md
│
├── src/openproject_deploy/
│   ├── __init__.py
│   ├── cli.py                      # CLI interface (Phase 1 ✅)
│   ├── config_manager.py           # Configuration management (Phase 1 ✅)
│   │
│   ├── interactive/                # Interactive Configuration System (Phase 1.5 🔜)
│   │   ├── __init__.py
│   │   ├── orchestrator.py         # Coordinate 4-phase flow
│   │   ├── discovery.py            # Auto-discover environment
│   │   ├── collector.py            # Rich UI for user input
│   │   ├── validation.py           # Validate completeness + consistency
│   │   ├── prober_client.py        # Interface to external prober
│   │   └── finalizer.py            # Generate .env and .cfg files
│   │
│   ├── orchestrator.py             # Deployment orchestration (Phase 2)
│   ├── template_renderer.py        # Jinja2 template rendering (Phase 2)
│   ├── health_checker.py           # Service health validation (Phase 2)
│   ├── docker_client.py            # Docker SDK wrapper (Phase 2)
│   │
│   ├── backup_manager.py           # Backup operations (Phase 3)
│   ├── upgrade_manager.py          # Upgrade operations (Phase 3)
│   │
│   ├── integration_tester.py       # Integration testing (Phase 4)
│   │
│   └── utils/
│       ├── __init__.py
│       ├── logging.py              # Logging configuration
│       ├── validation.py           # Validation utilities
│       ├── file_ops.py             # File operations
│       └── errors.py               # Custom exceptions
│
├── tests/
│   ├── test_config.py              # Config manager tests (Phase 1 ✅)
│   ├── interactive/                # Interactive config tests (Phase 1.5 🔜)
│   │   ├── test_discovery.py       # Discovery engine tests
│   │   ├── test_collector.py       # Interactive collector tests
│   │   ├── test_validation.py      # Validation engine tests
│   │   ├── test_prober_client.py   # Prober client tests
│   │   ├── test_finalizer.py       # Finalizer tests
│   │   └── test_orchestrator.py    # Orchestrator tests
│   ├── test_orchestrator.py        # Orchestrator tests (Phase 2)
│   ├── test_template_renderer.py   # Template tests (Phase 2)
│   ├── test_health_checker.py      # Health checker tests (Phase 2)
│   ├── test_backup.py              # Backup tests (Phase 3)
│   ├── test_upgrade.py             # Upgrade tests (Phase 3)
│   ├── test_integration.py         # Integration tests (Phase 4)
│   └── fixtures/
│       ├── test.env
│       ├── test.cfg
│       └── templates/
│
├── templates/
│   ├── Caddyfile.template.j2
│   ├── docker-compose.override.yml.j2
│   └── README.md
│
└── .github/workflows/
    ├── python-ci.yml               # Python CI (Phase 1 ✅)
    └── docker-build.yml            # Docker CI (Phase 1 ✅)
```

---

## Implementation Phases

### Phase 1: Core Utilities ✅ COMPLETE
- ✅ Python project structure
- ✅ ConfigManager
- ✅ CLI skeleton
- ✅ Unit tests
- ✅ CI/CD setup

### Phase 1.5: Interactive Configuration System 🔜 HIGH PRIORITY
**Goal**: Replace `interactive_config.sh` with intelligent Python-based interactive configuration

**Architecture Document**: See `INTERACTIVE_CONFIG_ARCHITECTURE.md` for detailed design

**Components**:
- Discovery Engine (auto-detect environment)
- Interactive Collector (Rich UI for user input)
- Validation Engine (completeness + live testing)
- Prober Client (integration with external docker_prober_utility)
- Configuration Finalizer (generate final configs)
- Interactive Orchestrator (coordinate 4-phase flow)

**Deliverables**:
- `interactive/discovery.py` - Auto-discover OS, network, Docker, ports, certs
- `interactive/collector.py` - Rich-based UI for collecting user preferences (7 sections)
- `interactive/validation.py` - Validate config completeness and consistency
- `interactive/prober_client.py` - Interface to external prober for live endpoint testing
- `interactive/finalizer.py` - Generate .env and .cfg files with backups
- `interactive/orchestrator.py` - Coordinate Discovery → Collection → Validation → Finalization
- CLI command: `openproject configure --interactive [--resume] [--template=NAME]`
- Unit tests for each component
- Integration tests with prober

**User Flow**:
```
1. Discovery: Auto-detect environment and suggest defaults
2. Collection: Beautiful interactive walkthrough (7 sections)
3. Validation: Check completeness + live test with Prober
4. Finalization: Generate .env and .cfg files
```

**Dependencies**: 
- Phase 1 (ConfigManager)
- docker_prober_utility (external repo at /opt/prober)
- rich library for terminal UI

**Open Questions** (to be resolved):
1. Prober deployment: Docker container with API vs Python script?
2. Discovery caching: Cache results to speed up resume?
3. Config templates: Support for predefined configurations (prod/dev/staging)?
4. Validation optionality: Allow users to skip live validation?
5. Non-interactive mode: Support JSON/YAML input for automation?

### Phase 2: Deployment Orchestration
- DeploymentOrchestrator
- TemplateRenderer (Jinja2)
- HealthChecker
- DockerClient wrapper
- Unit tests for each
- Integration test framework

### Phase 3: Control Plane
- BackupManager
- UpgradeManager
- Backup verification
- Upgrade safety checks
- Unit tests for each

### Phase 4: Integration Testing
- IntegrationTester
- Prober integration
- Interactive test mode
- Test report generation

### Phase 5: Migration & Cleanup
- Deprecate Bash scripts
- Update documentation
- Migration guide
- Final integration tests

---

## Error Handling Strategy

### Error Categories

1. **Configuration Errors** (ConfigurationError)
   - Missing required keys
   - Invalid values
   - File not found
   - **Recovery**: Prompt user to fix, provide defaults

2. **Validation Errors** (ValidationError)
   - Template syntax errors
   - Docker daemon not running
   - Port conflicts
   - **Recovery**: Fail fast, report specific error

3. **Deployment Errors** (DeploymentError)
   - Container failed to start
   - Health check timeout
   - Volume mount errors
   - **Recovery**: Automatic rollback, report logs

4. **Infrastructure Errors** (InfrastructureError)
   - Docker API errors
   - Disk space issues
   - Network errors
   - **Recovery**: Graceful degradation, manual intervention

### Error Handling Pattern
```python
try:
    result = operation()
    if not result.success:
        logger.warning(f"Operation completed with warnings: {result.warnings}")
    return result
except ConfigurationError as e:
    logger.error(f"Configuration error: {e}")
    # Prompt user for fix
    raise
except DeploymentError as e:
    logger.error(f"Deployment failed: {e}")
    # Trigger automatic rollback
    rollback()
    raise
except Exception as e:
    logger.critical(f"Unexpected error: {e}")
    # Report to user with stack trace
    raise
```

---

## Logging Strategy

### Log Levels
- **DEBUG**: Verbose output for troubleshooting (function calls, variable values)
- **INFO**: Normal operation status (service started, configuration loaded)
- **WARNING**: Non-critical issues (optional config missing, deprecated usage)
- **ERROR**: Operation failed but recoverable (service failed to start, rollback triggered)
- **CRITICAL**: System failure (Docker daemon down, unrecoverable error)

### Log Destinations
- Console: INFO and above (with rich formatting)
- File: DEBUG and above (`logs/openproject-deploy.log`)
- Syslog: ERROR and above (optional, for production)

### Log Format
```
2025-10-11 21:00:00,123 - openproject_deploy.orchestrator - INFO - Starting deployment
2025-10-11 21:00:01,456 - openproject_deploy.health_checker - DEBUG - Checking service: web
2025-10-11 21:00:02,789 - openproject_deploy.health_checker - INFO - Service 'web' is healthy
```

---

## Configuration Schema

### Required Keys
- `OPENPROJECT_HOST__NAME`: Hostname for OpenProject
- `DOMAIN_NAME`: Domain name for proxy
- `OPENPROJECT_HTTPS`: Enable HTTPS (true/false)
- `OPENPROJECT_TAG`: Docker image tag

### Optional Keys (with defaults)
- `TAG`: Docker image tag (default: 16-slim)
- `PORT`: Proxy port (default: 8080)
- `OPENPROJECT_RAILS__RELATIVE__URL__ROOT`: URL prefix (default: "")
- `DATABASE_URL`: PostgreSQL connection string
- `PGDATA`: PostgreSQL data directory
- `OPDATA`: OpenProject assets directory

### Validation Rules
- `OPENPROJECT_HTTPS`: Must be "true" or "false"
- `PORT`: Must be integer 1-65535
- `OPENPROJECT_HOST__NAME`: Must be valid hostname or IP
- `DATABASE_URL`: Must be valid PostgreSQL connection string

---

## Security Considerations

1. **Secrets Management**
   - Never log sensitive values (passwords, tokens)
   - Mask secrets in output (`***REDACTED***`)
   - Support external secret providers (future: Vault, AWS Secrets Manager)

2. **File Permissions**
   - Restrict `.env` to owner read/write only (0600)
   - Validate file ownership before reading secrets

3. **Docker Security**
   - Run containers as non-root user when possible
   - Validate image signatures (future enhancement)
   - Limit container capabilities

4. **Network Security**
   - Support TLS certificate validation
   - Enforce HTTPS in production deployments
   - Validate proxy headers to prevent header injection

---

## Testing Strategy

### Unit Tests
- Test each component in isolation
- Mock external dependencies (Docker, filesystem)
- Aim for >90% code coverage
- Fast execution (<1s per test)

### Integration Tests
- Test component interactions
- Use real Docker containers (test environment)
- Test backup/restore flows
- Test upgrade paths

### End-to-End Tests
- Full deployment workflow
- Prober integration tests
- Performance benchmarks
- Compatibility tests with upstream OpenProject

### CI/CD Tests
- Automated on every push/PR
- Linting (black, flake8, mypy)
- Unit tests on Python 3.8-3.12
- Docker build validation
- Integration tests (on PR to develop)

---

## Migration Strategy

### Coexistence Phase (Current)
- Python tools coexist with Bash scripts
- Users can choose which to use
- Both read/write same configuration files

### Deprecation Phase (Future)
- Mark Bash scripts as deprecated
- Provide migration guide
- Python becomes recommended method

### Sunset Phase (Future)
- Remove Bash scripts
- Python is only method
- Complete documentation update

---

## Future Enhancements

1. **Plugin System**: Allow custom deployment hooks and validators
2. **Multi-Environment Support**: Dev, staging, production configs
3. **Secrets Management**: Integration with Vault, AWS Secrets Manager
4. **Monitoring Integration**: Export metrics to Prometheus, Grafana
5. **Auto-Scaling**: Dynamic resource allocation based on load
6. **Blue-Green Deployment**: Zero-downtime deployments
7. **Disaster Recovery**: Automated backup scheduling and rotation
8. **Web UI**: Optional web interface for deployment management

---

## Questions for Approval

1. Does this architecture align with your vision for the rebuild?
2. Are there any components missing or unnecessary?
3. Should we prioritize any specific phase over others?
4. Any concerns about the migration strategy?
5. Additional security requirements?

---

## Next Steps

Once approved, we will:
1. Create detailed design documents for Phase 2 components
2. Write tests first (TDD approach)
3. Implement DeploymentOrchestrator
4. Implement TemplateRenderer
5. Implement HealthChecker
6. Implement DockerClient
7. Update CI/CD workflows
8. Document usage and examples

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-11  
**Status**: Draft - Pending Approval
