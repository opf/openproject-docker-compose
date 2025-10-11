# Multi-Repository Migration Plan

## Overview

This document outlines the step-by-step migration plan to extract **Configuration Manager** and **Deploy Manager** into standalone repositories while keeping **Maintenance Manager** in the main `openproject-docker-compose` repository.

---

## Repository Structure (Target State)

```
External Standalone Repositories (Reusable):
├── docker-prober-utility              ✅ EXISTS
│   └── HTTP/HTTPS validation utility
├── openproject-config-manager         🆕 NEW REPO (created)
│   └── Interactive configuration tool
└── openproject-deploy-manager         🆕 NEW REPO (created)
    └── Deployment orchestration tool

Main Repository (OpenProject-Specific):
└── openproject-docker-compose         ✅ EXISTS
    ├── Maintenance Manager (backup, upgrade, migrations)
    ├── CLI (orchestrates external managers)
    ├── Templates (OpenProject-specific Jinja2 templates)
    └── Uses: config-manager, deploy-manager, prober (as dependencies)
```

---

## Migration Phases

### **Phase 0: Preparation** ✅ COMPLETE
**Status**: Done

**Completed**:
- ✅ Created `openproject-config-manager` repository
- ✅ Created `openproject-deploy-manager` repository
- ✅ Updated `ARCHITECTURE.md` to reflect multi-repo structure
- ✅ Documented repository roles and responsibilities

**Next**: Initialize the new repositories with basic project structure

---

### **Phase 1: Initialize openproject-config-manager**
**Goal**: Set up the config-manager repository with basic project structure

**Tasks**:

1. **Initialize Repository Structure**
   ```bash
   cd /tmp
   git clone https://github.com/JustinCBates/openproject-config-manager.git
   cd openproject-config-manager
   ```

2. **Create Python Project Structure**
   ```
   openproject-config-manager/
   ├── README.md
   ├── LICENSE
   ├── .gitignore
   ├── pyproject.toml
   ├── requirements.txt
   ├── requirements-dev.txt
   │
   ├── src/
   │   └── openproject_config_manager/
   │       ├── __init__.py
   │       ├── core.py                  # ConfigManager (from existing code)
   │       └── interactive/
   │           ├── __init__.py
   │           ├── orchestrator.py
   │           ├── discovery.py
   │           ├── collector.py
   │           ├── validation.py
   │           └── finalizer.py
   │
   ├── tests/
   │   ├── __init__.py
   │   ├── test_core.py                # Migrate existing config tests
   │   └── interactive/
   │       ├── test_discovery.py
   │       ├── test_collector.py
   │       ├── test_validation.py
   │       └── test_finalizer.py
   │
   └── .github/
       └── workflows/
           └── ci.yml                   # Python linting and testing
   ```

3. **Create `pyproject.toml`**
   ```toml
   [project]
   name = "openproject-config-manager"
   version = "0.1.0"
   description = "Interactive configuration management for Docker Compose projects"
   authors = [{name = "Justin Bates", email = "your.email@example.com"}]
   readme = "README.md"
   requires-python = ">=3.8"
   license = {text = "MIT"}
   
   dependencies = [
       "python-dotenv>=1.0.0",
       "pyyaml>=6.0",
       "rich>=13.0.0",
       "docker>=7.0.0",
       "docker-prober-utility @ git+https://github.com/JustinCBates/docker_prober_utility.git@main"
   ]
   
   [project.optional-dependencies]
   dev = [
       "pytest>=7.0.0",
       "pytest-cov>=4.0.0",
       "black>=23.0.0",
       "flake8>=6.0.0",
       "mypy>=1.0.0"
   ]
   
   [build-system]
   requires = ["setuptools>=68.0.0", "wheel"]
   build-backend = "setuptools.build_meta"
   
   [tool.black]
   line-length = 100
   target-version = ["py38"]
   
   [tool.pytest.ini_options]
   testpaths = ["tests"]
   python_files = "test_*.py"
   addopts = "--cov=openproject_config_manager --cov-report=term-missing"
   ```

4. **Create `README.md`**
   ```markdown
   # OpenProject Configuration Manager
   
   Interactive configuration management for Docker Compose projects with intelligent discovery and live validation.
   
   ## Features
   
   - **Auto-Discovery**: Detects OS, network, Docker, ports, and certificates
   - **Interactive UI**: Beautiful Rich-based terminal interface
   - **Live Validation**: Integrates with docker-prober-utility for real-time config testing
   - **Smart Defaults**: Suggests intelligent defaults based on environment
   - **Resumable**: Can resume interrupted configuration sessions
   
   ## Installation
   
   ```bash
   pip install openproject-config-manager
   ```
   
   Or install from source:
   ```bash
   git clone https://github.com/JustinCBates/openproject-config-manager.git
   cd openproject-config-manager
   pip install -e .
   ```
   
   ## Usage
   
   ```python
   from openproject_config_manager import ConfigurationManager
   
   # Interactive configuration
   config = ConfigurationManager()
   result = config.run_interactive(
       template="docker-compose",
       prober_enabled=True
   )
   # Outputs: .env and .cfg files
   ```
   
   ## Development
   
   ```bash
   # Install dev dependencies
   pip install -e ".[dev]"
   
   # Run tests
   pytest
   
   # Format code
   black src tests
   
   # Lint
   flake8 src tests
   ```
   
   ## License
   
   MIT
   ```

5. **Create GitHub Actions CI** (`.github/workflows/ci.yml`)
   ```yaml
   name: CI
   
   on:
     push:
       branches: [main, develop]
     pull_request:
       branches: [main, develop]
   
   jobs:
     lint:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-python@v5
           with:
             python-version: '3.11'
         - name: Install dependencies
           run: |
             pip install black flake8
         - name: Check formatting
           run: black --check src tests
         - name: Lint
           run: flake8 src tests
   
     test:
       runs-on: ubuntu-latest
       strategy:
         matrix:
           python-version: ['3.8', '3.9', '3.10', '3.11', '3.12']
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-python@v5
           with:
             python-version: ${{ matrix.python-version }}
         - name: Install dependencies
           run: |
             pip install -e ".[dev]"
         - name: Run tests
           run: pytest
   ```

6. **Migrate Existing Code**
   - Copy `src/openproject_deploy/config_manager.py` → `src/openproject_config_manager/core.py`
   - Copy `tests/test_config.py` → `tests/test_core.py`
   - Update imports to use new package name

7. **Commit and Push**
   ```bash
   git add .
   git commit -m "feat: initialize config-manager repository structure
   
   - Add Python project structure (src/, tests/)
   - Add pyproject.toml with dependencies
   - Add GitHub Actions CI workflow
   - Add README with usage examples
   - Migrate existing ConfigManager from main repo
   - Migrate existing tests"
   
   git push origin main
   ```

**Deliverables**:
- ✅ openproject-config-manager repo initialized
- ✅ CI/CD set up
- ✅ Existing ConfigManager code migrated
- ✅ Tests migrated and passing

---

### **Phase 2: Initialize openproject-deploy-manager**
**Goal**: Set up the deploy-manager repository with basic project structure

**Tasks**:

1. **Initialize Repository Structure**
   ```bash
   cd /tmp
   git clone https://github.com/JustinCBates/openproject-deploy-manager.git
   cd openproject-deploy-manager
   ```

2. **Create Python Project Structure**
   ```
   openproject-deploy-manager/
   ├── README.md
   ├── LICENSE
   ├── .gitignore
   ├── pyproject.toml
   ├── requirements.txt
   ├── requirements-dev.txt
   │
   ├── src/
   │   └── openproject_deploy_manager/
   │       ├── __init__.py
   │       ├── orchestrator.py
   │       ├── template_renderer.py
   │       ├── health_checker.py
   │       └── docker_client.py
   │
   ├── tests/
   │   ├── __init__.py
   │   ├── test_orchestrator.py
   │   ├── test_template_renderer.py
   │   ├── test_health_checker.py
   │   └── test_docker_client.py
   │
   └── .github/
       └── workflows/
           └── ci.yml
   ```

3. **Create `pyproject.toml`**
   ```toml
   [project]
   name = "openproject-deploy-manager"
   version = "0.1.0"
   description = "Deployment orchestration for Docker Compose stacks with health checking and rollback"
   authors = [{name = "Justin Bates", email = "your.email@example.com"}]
   readme = "README.md"
   requires-python = ">=3.8"
   license = {text = "MIT"}
   
   dependencies = [
       "docker>=7.0.0",
       "jinja2>=3.1.0",
       "pyyaml>=6.0",
       "docker-prober-utility @ git+https://github.com/JustinCBates/docker_prober_utility.git@main"
   ]
   
   [project.optional-dependencies]
   dev = [
       "pytest>=7.0.0",
       "pytest-cov>=4.0.0",
       "black>=23.0.0",
       "flake8>=6.0.0",
       "mypy>=1.0.0"
   ]
   
   [build-system]
   requires = ["setuptools>=68.0.0", "wheel"]
   build-backend = "setuptools.build_meta"
   
   [tool.black]
   line-length = 100
   target-version = ["py38"]
   
   [tool.pytest.ini_options]
   testpaths = ["tests"]
   python_files = "test_*.py"
   addopts = "--cov=openproject_deploy_manager --cov-report=term-missing"
   ```

4. **Create `README.md`**
   ```markdown
   # OpenProject Deploy Manager
   
   Deployment orchestration for Docker Compose stacks with health checking, rollback, and live validation.
   
   ## Features
   
   - **Deployment Orchestration**: Coordinate docker-compose lifecycle
   - **Template Rendering**: Jinja2 template support for dynamic configs
   - **Health Checking**: Verify services are healthy after deployment
   - **Preflight Validation**: Integrate with docker-prober-utility for pre-deployment checks
   - **Automatic Rollback**: Rollback on deployment failure
   
   ## Installation
   
   ```bash
   pip install openproject-deploy-manager
   ```
   
   Or install from source:
   ```bash
   git clone https://github.com/JustinCBates/openproject-deploy-manager.git
   cd openproject-deploy-manager
   pip install -e .
   ```
   
   ## Usage
   
   ```python
   from openproject_deploy_manager import DeploymentOrchestrator
   
   # Deploy Docker Compose stack
   orchestrator = DeploymentOrchestrator(
       config={"key": "value"},
       compose_file="docker-compose.yml",
       prober_enabled=True
   )
   result = orchestrator.deploy(dry_run=False)
   ```
   
   ## Development
   
   ```bash
   # Install dev dependencies
   pip install -e ".[dev]"
   
   # Run tests
   pytest
   
   # Format code
   black src tests
   
   # Lint
   flake8 src tests
   ```
   
   ## License
   
   MIT
   ```

5. **Create GitHub Actions CI** (same as config-manager)

6. **Commit and Push**
   ```bash
   git add .
   git commit -m "feat: initialize deploy-manager repository structure
   
   - Add Python project structure (src/, tests/)
   - Add pyproject.toml with dependencies
   - Add GitHub Actions CI workflow
   - Add README with usage examples
   - Add stubs for orchestrator, template renderer, health checker, docker client"
   
   git push origin main
   ```

**Deliverables**:
- ✅ openproject-deploy-manager repo initialized
- ✅ CI/CD set up
- ✅ Project structure in place (stubs for Phase 2 implementation)

---

### **Phase 3: Update Main Repository Dependencies**
**Goal**: Update openproject-docker-compose to use config-manager as external dependency

**Tasks**:

1. **Update `pyproject.toml` in main repo**
   ```toml
   [project]
   dependencies = [
       "click>=8.1.0",
       # External managers
       "openproject-config-manager @ git+https://github.com/JustinCBates/openproject-config-manager.git@main",
       "openproject-deploy-manager @ git+https://github.com/JustinCBates/openproject-deploy-manager.git@main",
       "docker-prober-utility @ git+https://github.com/JustinCBates/docker_prober_utility.git@main"
   ]
   ```

2. **Restructure Main Repo**
   ```
   openproject-docker-compose/
   ├── src/openproject/
   │   ├── __init__.py
   │   ├── cli.py                      # CLI orchestrator
   │   │
   │   ├── maintenance/                # Maintenance Manager (stays here)
   │   │   ├── __init__.py
   │   │   ├── backup.py
   │   │   ├── upgrade.py
   │   │   └── migration.py
   │   │
   │   ├── templates/                  # OpenProject-specific templates
   │   │   ├── Caddyfile.j2
   │   │   └── docker-compose.override.yml.j2
   │   │
   │   └── utils/                      # Shared utilities
   │       ├── __init__.py
   │       ├── prober_client.py        # Wrapper for prober
   │       ├── logging.py
   │       └── errors.py
   │
   ├── tests/
   │   ├── maintenance/
   │   │   ├── test_backup.py
   │   │   ├── test_upgrade.py
   │   │   └── test_migration.py
   │   └── integration/
   │       └── test_full_workflow.py
   ```

3. **Remove Migrated Code**
   - Delete `src/openproject_deploy/config_manager.py` (now in config-manager repo)
   - Delete `tests/test_config.py` (now in config-manager repo)
   - Keep stubs for Phase 2 components (orchestrator, etc.) until deploy-manager is ready

4. **Update CLI to Use External Config Manager**
   ```python
   # src/openproject/cli.py
   import click
   from openproject_config_manager import ConfigurationManager
   # from openproject_deploy_manager import DeploymentOrchestrator  # Phase 2
   
   @click.group()
   def cli():
       """OpenProject deployment management CLI"""
       pass
   
   @cli.command()
   @click.option('--interactive', is_flag=True, help='Run interactive configuration')
   @click.option('--resume', is_flag=True, help='Resume interrupted configuration')
   def configure(interactive, resume):
       """Configure OpenProject deployment"""
       if interactive:
           config_mgr = ConfigurationManager()
           result = config_mgr.run_interactive(
               template="openproject",
               resume=resume,
               prober_enabled=True
           )
           click.echo(f"Configuration saved to {result.env_path}")
       else:
           # Load and display existing config
           click.echo("Current configuration:")
           # ... show config ...
   
   @cli.command()
   @click.option('--dry-run', is_flag=True, help='Validate without deploying')
   def deploy(dry_run):
       """Deploy OpenProject stack"""
       # Will use openproject-deploy-manager in Phase 2
       click.echo("Deploy command (coming in Phase 2)")
   
   @cli.group()
   def backup():
       """Backup operations"""
       pass
   
   @backup.command('create')
   def backup_create():
       """Create a backup"""
       # Will use MaintenanceManager.BackupManager in Phase 3
       click.echo("Backup create (coming in Phase 3)")
   ```

5. **Update Tests**
   - Update integration tests to use external config-manager
   - Remove unit tests for ConfigManager (now in config-manager repo)

6. **Commit and Push**
   ```bash
   git add .
   git commit -m "refactor: migrate to external config-manager dependency
   
   - Update pyproject.toml to use openproject-config-manager as dependency
   - Remove config_manager.py (now in external repo)
   - Update CLI to import from external config-manager
   - Restructure main repo: maintenance/, templates/, utils/
   - Remove migrated tests
   - Update integration tests to use external manager"
   
   git push origin feature/python-rebuild
   ```

**Deliverables**:
- ✅ Main repo uses config-manager as external dependency
- ✅ Code migrated and removed from main repo
- ✅ CLI updated to use external manager
- ✅ Tests updated

---

### **Phase 4: Implement Configuration Manager** (Phase 1.5)
**Goal**: Implement the interactive configuration system in openproject-config-manager repo

**Tasks**:
- See `INTERACTIVE_CONFIG_ARCHITECTURE.md` for detailed implementation plan
- Implement Discovery Engine
- Implement Interactive Collector (Rich UI)
- Implement Validation Engine (with prober integration)
- Implement Configuration Finalizer
- Implement Interactive Orchestrator
- Add comprehensive tests
- Update documentation

**Deliverables**:
- ✅ Full interactive configuration system working
- ✅ Tests passing
- ✅ Can be consumed by main repo

---

### **Phase 5: Implement Deploy Manager** (Phase 2)
**Goal**: Implement deployment orchestration in openproject-deploy-manager repo

**Tasks**:
- Implement DeploymentOrchestrator
- Implement TemplateRenderer
- Implement HealthChecker
- Implement DockerClient wrapper
- Add prober preflight integration
- Add comprehensive tests
- Update main repo to use deploy-manager

**Deliverables**:
- ✅ Full deployment orchestration working
- ✅ Tests passing
- ✅ Main repo can deploy using external manager

---

### **Phase 6: Implement Maintenance Manager** (Phase 3)
**Goal**: Implement maintenance operations in main openproject-docker-compose repo

**Tasks**:
- Implement BackupManager
- Implement UpgradeManager
- Implement MigrationManager (optional, later)
- Add comprehensive tests
- Update CLI to expose maintenance commands

**Deliverables**:
- ✅ Backup/restore working
- ✅ PostgreSQL upgrades working
- ✅ Tests passing

---

## Testing Strategy

### **Unit Tests**
- Each repository has its own unit tests
- CI runs on every push/PR
- Code coverage ≥ 80%

### **Integration Tests**
- Main repo has integration tests that use all managers together
- Test full workflow: configure → deploy → backup → upgrade

### **End-to-End Tests**
- Test complete OpenProject deployment
- Test with different configurations (HTTP, HTTPS, namespace, etc.)

---

## Rollout Strategy

### **Development Branch Strategy**
```
openproject-docker-compose:
├── stable/16 (pristine, never modify)
├── develop (integration branch)
└── feature/python-rebuild (current work)

openproject-config-manager:
├── main (stable releases)
└── develop (active development)

openproject-deploy-manager:
├── main (stable releases)
└── develop (active development)
```

### **Version Pinning**
- Main repo pins specific versions/commits of external managers
- Use semantic versioning for releases
- Document version compatibility matrix

### **Release Process**
1. Tag releases in config-manager and deploy-manager
2. Update main repo to use tagged versions
3. Test integration
4. Tag release in main repo
5. Update documentation

---

## Success Criteria

✅ **Phase 1 Complete When**:
- config-manager repo initialized and CI passing
- Existing ConfigManager code migrated
- Main repo uses config-manager as dependency

✅ **Phase 2 Complete When**:
- deploy-manager repo initialized and CI passing
- Main repo uses deploy-manager as dependency

✅ **Phase 3 Complete When**:
- Maintenance manager implemented in main repo
- All three managers work together
- Full deployment workflow functional

✅ **Phase 4 Complete When**:
- Interactive configuration system fully implemented
- User can run `openproject configure --interactive`
- Config validated with prober

✅ **Phase 5 Complete When**:
- Deployment orchestration fully implemented
- User can run `openproject deploy`
- Preflight checks with prober working

✅ **Phase 6 Complete When**:
- Backup/restore working
- PostgreSQL upgrades working
- User can run `openproject backup create`, `openproject upgrade`

---

## Next Immediate Steps

1. **Initialize config-manager repo** (Phase 1)
   - Create project structure
   - Add pyproject.toml
   - Set up CI/CD
   - Migrate existing ConfigManager code

2. **Initialize deploy-manager repo** (Phase 2)
   - Create project structure
   - Add pyproject.toml
   - Set up CI/CD
   - Add component stubs

3. **Update main repo** (Phase 3)
   - Add external dependencies
   - Restructure code
   - Update CLI

**Ready to start Phase 1?** Let me know if you'd like me to help with any of these steps!
