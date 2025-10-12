# Management Manager

**Repository**: `openproject-docker-compose` (this repo)  
**Location**: `src/openproject/maintenance/` and `Management/`  
**Purpose**: OpenProject-specific maintenance operations (backup, upgrade, migrations)

## Overview

The Management Manager is the **only manager that stays in the main repository** because it contains OpenProject-specific functionality that is tightly coupled to the application and database schema.

## Repository Structure

```
Management/                       # This folder (implementation & documentation)
├── README.md                     # This file
├── backup/                       # Backup operations
├── upgrade/                      # PostgreSQL upgrades
├── migration/                    # Database migrations
└── monitoring/                   # Health monitoring

src/openproject/maintenance/      # Python implementation
├── __init__.py
├── backup_manager.py            # Backup operations
├── upgrade_manager.py           # PostgreSQL upgrades
├── migration_manager.py         # Database migrations
└── monitoring.py                # Health monitoring
```

## Why Management Manager Stays in Main Repo

1. **OpenProject-Specific**: Tightly coupled to OpenProject's database schema
2. **Version Dependencies**: PostgreSQL upgrade paths specific to OpenProject versions
3. **Data Structure Knowledge**: Requires deep understanding of OpenProject's data model
4. **Migration Scripts**: OpenProject-specific database migration procedures
5. **Lower Reusability**: Other projects have different maintenance requirements

## Core Components

### 1. Backup Manager (`backup_manager.py`)

**Purpose**: Create, verify, and restore backups of OpenProject data

```python
class BackupManager:
    def __init__(config: dict)
    def create_backup(backup_type: BackupType) -> BackupResult
    def restore_backup(backup_path: Path) -> RestoreResult
    def verify_backup(backup_path: Path) -> VerificationResult
    def list_backups() -> List[BackupInfo]
    def cleanup_old_backups(retention_days: int) -> CleanupResult
```

**Backup Types**:
- **Full Backup**: PostgreSQL database + OpenProject assets
- **Database Only**: PostgreSQL dump without files
- **Assets Only**: File system assets without database
- **Configuration**: Environment and configuration files

**Backup Strategy**:
```
Backup Creation Process
├── Pre-backup Validation
│   ├── Check disk space availability
│   ├── Verify database accessibility
│   └── Ensure backup directory exists
├── Database Backup
│   ├── pg_dump with custom format
│   ├── Include all schemas and data
│   └── Verify dump integrity
├── Asset Backup
│   ├── Tar/gzip OpenProject assets
│   ├── Include user uploads and attachments
│   └── Preserve file permissions
├── Configuration Backup
│   ├── Copy .env and configuration files
│   ├── Export Docker Compose configuration
│   └── Include custom templates
└── Backup Verification
    ├── Test database restore (dry-run)
    ├── Verify archive integrity
    └── Generate backup manifest
```

### 2. Upgrade Manager (`upgrade_manager.py`)

**Purpose**: Handle PostgreSQL version upgrades safely

```python
class UpgradeManager:
    def __init__(config: dict)
    def check_upgrade_path(target_version: str) -> UpgradePathInfo
    def execute_upgrade(target_version: str, dry_run: bool = False) -> UpgradeResult
    def rollback_upgrade() -> RollbackResult
```

**Supported Upgrade Paths**:
- PostgreSQL 13 → 14
- PostgreSQL 13 → 15
- PostgreSQL 13 → 16
- PostgreSQL 14 → 15
- PostgreSQL 14 → 16
- PostgreSQL 15 → 16

**Upgrade Process**:
```
PostgreSQL Upgrade Process
├── Pre-upgrade Validation
│   ├── Check current PostgreSQL version
│   ├── Validate upgrade path compatibility
│   ├── Verify OpenProject version compatibility
│   └── Check disk space for upgrade
├── Automatic Backup
│   ├── Create full backup (database + assets)
│   ├── Verify backup integrity
│   └── Store backup metadata
├── Upgrade Execution
│   ├── Stop OpenProject services
│   ├── Start upgrade container with pg_upgrade
│   ├── Migrate data to new PostgreSQL version
│   └── Verify upgraded database
├── Service Restart
│   ├── Update docker-compose configuration
│   ├── Start services with new PostgreSQL
│   └── Run post-upgrade validations
└── Cleanup
    ├── Remove old PostgreSQL data (if successful)
    ├── Update system documentation
    └── Log upgrade completion
```

### 3. Migration Manager (`migration_manager.py`)

**Purpose**: Handle OpenProject version migrations and schema updates

```python
class MigrationManager:
    def __init__(config: dict)
    def check_pending_migrations() -> MigrationStatus
    def execute_migrations(target_version: str) -> MigrationResult
    def rollback_migration(steps: int = 1) -> RollbackResult
```

**Migration Types**:
- **Schema Migrations**: Database structure changes
- **Data Migrations**: Data format or content updates
- **Configuration Migrations**: Settings and preference updates
- **Plugin Migrations**: Custom plugin schema changes

### 4. Monitoring (`monitoring.py`)

**Purpose**: Ongoing health monitoring and diagnostics

```python
class MonitoringManager:
    def __init__(config: dict)
    def check_system_health() -> HealthReport
    def monitor_resources() -> ResourceReport
    def check_database_health() -> DatabaseReport
    def generate_diagnostics() -> DiagnosticReport
```

**Monitoring Areas**:
- **System Resources**: CPU, memory, disk usage
- **Database Performance**: Connection pool, query performance
- **Service Health**: Container status, endpoint availability
- **Security**: SSL certificate expiry, security updates

## Integration with Other Managers

### With Configuration Manager
```python
# Management operations use validated configuration
config = config_manager.get_maintenance_config()
backup_manager = BackupManager(config)
```

### With Deployment Manager
```python
# Coordinate with deployment for maintenance windows
deployment_manager.create_maintenance_snapshot()
upgrade_result = upgrade_manager.execute_upgrade("16")
if upgrade_result.success:
    deployment_manager.update_configuration()
else:
    deployment_manager.restore_snapshot()
```

### With Prober Utility
```python
# Use prober for health monitoring
health_result = prober_client.monitor_endpoints([
    "https://openproject.example.com/health",
    "https://openproject.example.com/api/v3/status"
])
```

## CLI Integration

```bash
# Backup operations
openproject backup create           # Create full backup
openproject backup create --db-only # Database only
openproject backup list            # List available backups
openproject backup restore <path>  # Restore from backup
openproject backup verify <path>   # Verify backup integrity

# Upgrade operations
openproject upgrade check          # Check upgrade availability
openproject upgrade to 16          # Upgrade PostgreSQL to version 16
openproject upgrade status         # Check upgrade status

# Monitoring operations
openproject status                 # System health check
openproject monitor               # Start monitoring mode
openproject diagnostics           # Generate diagnostic report
```

## File System Layout

### Backup Storage
```
/var/openproject/backups/
├── 2025-10-12_14-30-00_full/
│   ├── database.dump
│   ├── assets.tar.gz
│   ├── config.tar.gz
│   └── manifest.json
├── 2025-10-11_14-30-00_full/
└── 2025-10-10_14-30-00_db/
```

### Upgrade Logs
```
/var/openproject/upgrades/
├── upgrade_13_to_16_2025-10-12.log
├── pre_upgrade_backup_manifest.json
└── rollback_instructions.md
```

### Monitoring Data
```
/var/openproject/monitoring/
├── health_checks.log
├── performance_metrics.json
└── diagnostics/
    ├── system_info.json
    └── database_stats.json
```

## Error Handling & Recovery

### Backup Failures
1. **Disk Space Issues**: Check available space, suggest cleanup
2. **Database Lock**: Wait for operations to complete, retry
3. **Permission Errors**: Validate file system permissions
4. **Corruption Detection**: Verify backup integrity, recreate if needed

### Upgrade Failures
1. **Pre-upgrade Validation**: Stop before making changes
2. **Upgrade Process Errors**: Automatic rollback to previous state
3. **Post-upgrade Validation**: Verify database consistency
4. **Service Startup Issues**: Restore from automatic backup

### Recovery Procedures
```python
# Automatic recovery on failure
try:
    upgrade_result = upgrade_manager.execute_upgrade("16")
    if not upgrade_result.success:
        # Automatic rollback
        rollback_result = upgrade_manager.rollback_upgrade()
        logger.error(f"Upgrade failed, rolled back: {rollback_result.message}")
except Exception as e:
    # Emergency recovery
    emergency_restore(latest_backup_path)
```

## Development Status

- ⏳ **Planning**: Component architecture designed
- ⏳ **Implementation**: Core backup and upgrade logic
- ⏳ **Testing**: Integration testing with Docker environments
- ⏳ **Documentation**: Operational procedures and troubleshooting
- ⏳ **Monitoring**: Real-time health checking and alerting

## Dependencies

- `docker>=7.0.0` - Container management for PostgreSQL operations
- `psycopg2>=2.9.0` - PostgreSQL database connectivity
- `click>=8.1.0` - CLI framework integration
- Configuration Manager for validated settings
- Deployment Manager for coordination
- Prober utility for health monitoring

## Security Considerations

1. **Backup Encryption**: Encrypt sensitive backup data
2. **Access Control**: Limit backup and upgrade operations to authorized users
3. **Audit Logging**: Log all maintenance operations for compliance
4. **Secure Storage**: Store backups in secure, versioned storage
5. **Rollback Security**: Ensure rollback procedures don't compromise security

## Next Steps

1. **Implement Backup Manager**: Core backup and restore functionality
2. **Build Upgrade Manager**: PostgreSQL version upgrade automation
3. **Add Monitoring**: Real-time health checking and diagnostics
4. **Create Migration System**: OpenProject version migration support
5. **Integration Testing**: End-to-end testing with other managers
6. **Operational Documentation**: Procedures and troubleshooting guides

---

**Note**: Unlike the other managers, this component is **implemented directly in the main repository** due to its tight coupling with OpenProject-specific functionality.

For development, work in: `src/openproject/maintenance/`  
For documentation, reference: `Management/`