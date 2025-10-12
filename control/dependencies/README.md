# Dependencies - Control Component

This directory contains dependency tracking for the Control component.

## Files

### Documentation
- **`DEPENDENCIES.md`** - Database control and backup dependencies

## Purpose

The Control component handles OpenProject database operations:
- PostgreSQL backup and restore
- Database upgrades between versions
- Data migration and maintenance
- Database health monitoring

## Dependency Categories

### Production Dependencies
- **Absolute**: Required for database operations
  - PostgreSQL client tools (multiple versions)
  - Database backup utilities
  - Container runtime (Docker)
  
- **Ad-Hoc**: Context-dependent
  - Encryption tools (for backup security)
  - Cloud storage tools (for remote backups)
  - Network utilities (for remote database access)

### Developer Dependencies
- **Absolute**: Required for development
  - Database development tools
  - SQL testing utilities
  - Version control (Git)
  
- **Ad-Hoc**: Optional development tools
  - Database GUI tools
  - Performance analysis tools
  - Schema comparison utilities

## Database Operations

### Backup Operations
- **Full backups**: Complete database snapshots
- **Incremental backups**: Change-based backups
- **Point-in-time recovery**: Transaction log backups
- **Verification**: Backup integrity checking

### Upgrade Operations
- **Version compatibility**: Multi-version PostgreSQL support
- **Migration scripts**: Database schema updates
- **Rollback procedures**: Downgrade capabilities
- **Testing**: Upgrade validation and testing

## Container Architecture

The Control component runs in isolated containers:
- **Multiple PostgreSQL versions** for upgrade compatibility
- **Backup storage** with configurable retention
- **Network isolation** for security
- **Volume management** for persistent data

## Integration

- **Database**: Direct PostgreSQL operations
- **Storage**: Backup and restore operations
- **Monitoring**: Integration with prober for database health
- **Orchestration**: Called by main repository for maintenance