# Multi-Repository Architecture Summary

## What We Just Accomplished

✅ **Created comprehensive multi-repository architecture**  
✅ **Updated ARCHITECTURE.md to reflect 3-manager design**  
✅ **Created detailed MIGRATION_PLAN.md with step-by-step instructions**  
✅ **Committed and pushed all documentation to feature/python-rebuild**

---

## Repository Status

### **Created Repositories** (Empty, Ready for Initialization)

1. **openproject-config-manager**
   - URL: https://github.com/JustinCBates/openproject-config-manager
   - Status: 🆕 Created, awaiting initialization
   - Purpose: Interactive configuration tool with discovery and live validation

2. **openproject-deploy-manager**
   - URL: https://github.com/JustinCBates/openproject-deploy-manager
   - Status: 🆕 Created, awaiting initialization
   - Purpose: Deployment orchestration with health checks and rollback

### **Existing Repositories**

3. **docker-prober-utility**
   - URL: https://github.com/JustinCBates/docker_prober_utility
   - Status: ✅ Exists, already functional
   - Purpose: HTTP/HTTPS endpoint validation utility

4. **openproject-docker-compose**
   - URL: https://github.com/JustinCBates/openproject-docker-compose
   - Branch: `feature/python-rebuild`
   - Status: ✅ Updated with multi-repo architecture docs
   - Purpose: Main integration repo + Maintenance Manager

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│         openproject-docker-compose (Main Repo)              │
│                                                             │
│  ├─ CLI (orchestrates external managers)                   │
│  ├─ Maintenance Manager (backup, upgrade, migrations)      │
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

## Component Breakdown

### **1. Configuration Manager** (External Repo)
**Repository**: openproject-config-manager  
**Components**:
- Core Configuration (load/save .env, .cfg)
- Discovery Engine (auto-detect environment)
- Interactive Collector (Rich UI with 7 sections)
- Validation Engine (completeness + prober integration)
- Configuration Finalizer (generate final configs)

**User Flow**:
```
Discovery → Collection → Validation → Finalization
```

---

### **2. Deploy Manager** (External Repo)
**Repository**: openproject-deploy-manager  
**Components**:
- Deployment Orchestrator (coordinate lifecycle)
- Template Renderer (Jinja2 for Caddyfile, etc.)
- Health Checker (verify services are healthy)
- Docker Client Wrapper (simplified Docker SDK interface)

**User Flow**:
```
Validate → Render → Deploy → Health Check → Report
```

---

### **3. Maintenance Manager** (Main Repo)
**Repository**: openproject-docker-compose  
**Location**: `src/openproject/maintenance/`  
**Components**:
- Backup Manager (create, verify, restore backups)
- Upgrade Manager (PostgreSQL version upgrades)
- Migration Manager (data/schema migrations)

**Why in main repo?**
- OpenProject-specific backup/restore logic
- PostgreSQL upgrade paths specific to OpenProject
- Lower reusability for other projects

---

## Key Design Decisions

### **Why Multi-Repo?**

1. ✅ **Reusability**
   - Config-manager can configure any Docker Compose project
   - Deploy-manager can deploy any Docker Compose stack
   - Prober can validate any HTTP/HTTPS endpoint

2. ✅ **Separation of Concerns**
   - Configuration is distinct from deployment
   - Deployment is distinct from maintenance
   - Each repo has clear, single responsibility

3. ✅ **Independent Development**
   - Config improvements don't require deploy changes
   - Deploy improvements don't require config changes
   - Each repo has its own release cycle

4. ✅ **Clear Boundaries**
   - Config generates artifacts (.env, .cfg)
   - Deploy consumes artifacts and orchestrates containers
   - Maintenance operates on deployed systems

### **Why Prober in Both?**

- **Config Manager**: Uses prober for **quick validation** during interactive config (fast iteration loop)
- **Deploy Manager**: Uses prober for **thorough preflight checks** before full deployment (comprehensive validation)
- **Shared Dependency**: Both repos depend on `docker-prober-utility` as external package

### **Why Maintenance in Main Repo?**

- OpenProject-specific backup/restore logic (tightly coupled to data structure)
- PostgreSQL upgrade paths specific to OpenProject versions
- Migration scripts specific to OpenProject schema
- Lower reusability (other projects have different needs)

---

## Next Steps

### **Immediate (Phase 1)**

1. **Initialize openproject-config-manager**
   ```bash
   # See MIGRATION_PLAN.md Phase 1 for detailed steps
   cd /tmp
   git clone https://github.com/JustinCBates/openproject-config-manager.git
   cd openproject-config-manager
   
   # Create project structure
   # Add pyproject.toml
   # Set up CI/CD
   # Migrate existing ConfigManager code
   # Commit and push
   ```

2. **Initialize openproject-deploy-manager**
   ```bash
   # See MIGRATION_PLAN.md Phase 2 for detailed steps
   cd /tmp
   git clone https://github.com/JustinCBates/openproject-deploy-manager.git
   cd openproject-deploy-manager
   
   # Create project structure
   # Add pyproject.toml
   # Set up CI/CD
   # Add component stubs
   # Commit and push
   ```

3. **Update openproject-docker-compose**
   ```bash
   # See MIGRATION_PLAN.md Phase 3 for detailed steps
   cd /opt/openproject
   
   # Update pyproject.toml to depend on external repos
   # Restructure: maintenance/, templates/, utils/
   # Remove migrated code
   # Update CLI to use external managers
   # Commit and push
   ```

### **Implementation (Phases 4-6)**

4. **Implement Interactive Configuration System** (Phase 4)
   - Work in openproject-config-manager repo
   - See INTERACTIVE_CONFIG_ARCHITECTURE.md for detailed design
   - Implement discovery, collection, validation, finalization

5. **Implement Deployment Orchestration** (Phase 5)
   - Work in openproject-deploy-manager repo
   - Implement orchestrator, template renderer, health checker
   - Add prober preflight integration

6. **Implement Maintenance Manager** (Phase 6)
   - Work in openproject-docker-compose repo
   - Implement backup, upgrade, migration managers
   - Add CLI commands for maintenance operations

---

## Documentation

### **Created Documents**

1. **ARCHITECTURE.md** (Updated)
   - Location: `/opt/openproject/ARCHITECTURE.md`
   - Contents: Multi-repo architecture, 3-manager design, component interfaces, data flows
   - Commit: `aa53d01`

2. **MIGRATION_PLAN.md** (New)
   - Location: `/opt/openproject/MIGRATION_PLAN.md`
   - Contents: Step-by-step migration guide, project structure templates, CI/CD setup
   - Commit: `44ad89b`

3. **INTERACTIVE_CONFIG_ARCHITECTURE.md** (Existing)
   - Location: `/opt/openproject/INTERACTIVE_CONFIG_ARCHITECTURE.md`
   - Contents: Detailed design for interactive configuration system
   - Commit: `d51d46c`

### **All Commits**

```
44ad89b - docs: add multi-repository migration plan
aa53d01 - docs: restructure architecture for multi-repo strategy
d51d46c - docs: integrate interactive configuration system into global architecture
2cf8d52 - test: fix linting issues (black, flake8)
... (earlier commits)
```

---

## Testing Strategy

### **Per-Repo Testing**
- Each repo has its own unit tests
- CI runs on every push/PR
- Target coverage: ≥80%

### **Integration Testing**
- Main repo has integration tests
- Test full workflow: configure → deploy → backup → upgrade
- Test different scenarios (HTTP, HTTPS, namespace, etc.)

### **Version Compatibility**
- Pin dependency versions in main repo
- Document version compatibility matrix
- Automated compatibility tests in CI

---

## Success Criteria

✅ **Phase 1 Complete**: config-manager and deploy-manager repos initialized with CI  
✅ **Phase 2 Complete**: Main repo uses external managers as dependencies  
✅ **Phase 3 Complete**: Interactive configuration system fully functional  
✅ **Phase 4 Complete**: Deployment orchestration fully functional  
✅ **Phase 5 Complete**: Maintenance operations fully functional  
✅ **Phase 6 Complete**: All three managers work together seamlessly

---

## Questions?

If you have any questions about:
- Repository structure
- Migration steps
- Architecture decisions
- Implementation priorities

Refer to:
- [`ARCHITECTURE.md`](ARCHITECTURE.md) for architectural overview
- [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md) for step-by-step migration
- [`INTERACTIVE_CONFIG_ARCHITECTURE.md`](INTERACTIVE_CONFIG_ARCHITECTURE.md) for config system details

---

**Ready to start Phase 1?** 🚀

Let me know if you'd like help with:
1. Initializing config-manager repo
2. Initializing deploy-manager repo
3. Migrating existing code
4. Setting up CI/CD
5. Any other aspect of the migration
