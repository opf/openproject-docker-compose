# OpenProject Docker Compose - Project Overview

## Introduction
This repository provides a Docker Compose-based installation method for OpenProject. It includes container orchestration for the web application, database, caching, proxy, and control utilities for backup and upgrade operations.

---

## Architecture Overview

### Core Components
1. **Web Application** (`web` service): OpenProject Rails application
2. **Database** (`db` service): PostgreSQL 13
3. **Cache** (`cache` service): Memcached
4. **Proxy** (`proxy` service): Caddy v2 reverse proxy
5. **Worker** (`worker` service): Background job processor
6. **Cron** (`cron` service): Scheduled tasks
7. **Seeder** (`seeder` service): Database initialization
8. **Autoheal** (`autoheal` service): Container health monitoring and restart

### Control Plane
- **Backup**: Create backups of PostgreSQL data and OpenProject assets
- **Upgrade**: Perform database upgrades between PostgreSQL versions

### Integration Testing
- **Prober Utility** (submodule): Minimal HTTP/HTTPS backend for proxy configuration validation

---

## Project Structure

```
/opt/openproject/
├── docker-compose.yml              # Main orchestration file
├── docker-compose.control.yml      # Control plane (backup/upgrade)
├── .env.example                    # Environment variable template
├── README.md                       # User-facing documentation
├── PROJECT_OVERVIEW.md             # This file
├── control/                        # Control plane scripts and Dockerfile
│   ├── Dockerfile
│   ├── README.md
│   ├── backup/
│   │   └── entrypoint.sh           # Backup entrypoint
│   └── upgrade/
│       ├── entrypoint.sh           # Upgrade entrypoint
│       └── scripts/
│           └── 00-db-upgrade.sh    # Database upgrade script
├── proxy/                          # Caddy proxy configuration
│   ├── Dockerfile
│   ├── Caddyfile.template          # Caddy config template
│   └── integration_test/           # Integration test utilities
│       ├── README.md
│       └── prober/                 # Submodule: docker_prober_utility
│           ├── Dockerfile
│           ├── app.py
│           └── README.md
└── scripts/                        # Installation and configuration scripts
    └── installation_scripts/
        └── interactive_config.cfg  # User configuration file
```

---

## Control Flow Tree

### 1. Initial Setup and Deployment

```
User starts here
│
├─── Clone repository
│    └─── git clone https://github.com/opf/openproject-docker-compose.git
│
├─── Configure environment
│    ├─── Copy .env.example to .env
│    └─── Edit environment variables
│         ├─── OPENPROJECT_HOST__NAME
│         ├─── OPENPROJECT_HTTPS
│         ├─── OPENPROJECT_RAILS__RELATIVE__URL__ROOT
│         ├─── DATABASE_URL
│         ├─── PORT
│         └─── TAG (OpenProject version)
│
├─── Create required directories
│    └─── mkdir -p /var/openproject/assets
│    └─── chown 1000:1000 -R /var/openproject/assets
│
└─── Launch stack
     └─── docker compose up -d --build --pull always
          │
          ├─── Build proxy container
          │    ├─── FROM caddy:2
          │    ├─── COPY Caddyfile.template
          │    └─── Substitute ${APP_HOST} in template
          │
          ├─── Pull OpenProject image (TAG version)
          │
          ├─── Start PostgreSQL (db)
          │
          ├─── Start Memcached (cache)
          │
          ├─── Start seeder (initialize database)
          │
          ├─── Start web (Rails application)
          │    └─── Health check: /health_checks/default
          │
          ├─── Start worker (background jobs)
          │
          ├─── Start cron (scheduled tasks)
          │
          ├─── Start proxy (Caddy reverse proxy)
          │    └─── Listen on PORT (default: 8080)
          │    └─── Reverse proxy to web:8080
          │
          └─── Start autoheal (monitor and restart unhealthy containers)
```

---

### 2. Backup Workflow

```
User initiates backup
│
├─── Stop running stack
│    └─── docker-compose down
│
├─── Build control plane
│    └─── docker-compose -f docker-compose.yml -f docker-compose.control.yml build
│
├─── Run backup service
│    └─── docker-compose -f docker-compose.yml -f docker-compose.control.yml run backup
│         │
│         ├─── Entrypoint: /control/backup/entrypoint.sh
│         │
│         ├─── Create timestamp
│         │
│         ├─── Backup PostgreSQL data
│         │    └─── tar czf backups/<timestamp>-pgdata.tar.gz -C $PGDATA .
│         │
│         └─── Backup OpenProject assets
│              └─── tar czf backups/<timestamp>-opdata.tar.gz -C $OPDATA .
│
└─── Restart stack
     └─── docker-compose up -d
```

---

### 3. Upgrade Workflow

```
User initiates upgrade
│
├─── Stop running stack
│    └─── docker-compose down
│
├─── Fetch latest changes
│    └─── git pull origin stable/16
│
├─── Build control plane
│    └─── docker-compose -f docker-compose.yml -f docker-compose.control.yml build
│
├─── Run backup (recommended)
│    └─── docker-compose -f docker-compose.yml -f docker-compose.control.yml run backup
│
├─── Run upgrade service
│    └─── docker-compose -f docker-compose.yml -f docker-compose.control.yml run upgrade
│         │
│         ├─── Entrypoint: /control/upgrade/entrypoint.sh
│         │
│         └─── Execute: /control/upgrade/scripts/00-db-upgrade.sh
│              │
│              ├─── Detect current PostgreSQL version
│              │
│              ├─── Check if upgrade needed (CURRENT_PGVERSION < NEW_PGVERSION)
│              │
│              ├─── If upgrade needed:
│              │    ├─── Initialize new PostgreSQL data directory
│              │    ├─── Run pg_upgrade dry-run
│              │    ├─── Perform actual pg_upgrade
│              │    ├─── Move upgraded data to original location
│              │    └─── Update postgresql.conf and pg_hba.conf
│              │
│              └─── If no upgrade needed: exit
│
└─── Restart stack with new version
     └─── docker-compose up -d --build --pull always
```

---

### 4. Proxy Configuration and Integration Testing

```
User validates proxy settings
│
├─── Configure Caddyfile.template
│    ├─── Set reverse_proxy target
│    ├─── Configure X-Forwarded-* headers
│    └─── Enable logging
│
├─── Build proxy container
│    └─── Dockerfile substitutes ${APP_HOST} in template
│
└─── (Optional) Run integration test
     └─── Use prober utility (submodule)
          │
          ├─── Build prober container
          │    └─── FROM python:3-alpine
          │    └─── Install Flask
          │    └─── COPY app.py
          │
          ├─── Launch prober backend
          │    └─── docker run -p 8080:8080 prober
          │
          ├─── Probe HTTP/HTTPS endpoints
          │    └─── curl http://localhost:8080
          │
          ├─── Validate configuration
          │    └─── User confirms settings
          │
          └─── Tear down prober
               └─── docker stop <container>
```

---

## Key Files and Their Roles

### Configuration
- **`.env.example`**: Template for environment variables
- **`docker-compose.yml`**: Main orchestration file
- **`docker-compose.control.yml`**: Control plane for backup/upgrade
- **`scripts/installation_scripts/interactive_config.cfg`**: User configuration storage

### Proxy
- **`proxy/Caddyfile.template`**: Caddy reverse proxy configuration template
- **`proxy/Dockerfile`**: Caddy container build instructions

### Control Utilities
- **`control/backup/entrypoint.sh`**: Backup script for PostgreSQL and assets
- **`control/upgrade/entrypoint.sh`**: Upgrade orchestrator
- **`control/upgrade/scripts/00-db-upgrade.sh`**: PostgreSQL version upgrade script

### Integration Testing
- **`proxy/integration_test/prober/`**: Git submodule for minimal HTTP/HTTPS backend

---

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `TAG` | `16-slim` | OpenProject Docker image tag |
| `OPENPROJECT_HTTPS` | `true` | Enable HTTPS mode |
| `OPENPROJECT_HOST__NAME` | `localhost:8080` | Hostname for OpenProject |
| `OPENPROJECT_RAILS__RELATIVE__URL__ROOT` | _(empty)_ | URL prefix for OpenProject |
| `DATABASE_URL` | `postgres://postgres:p4ssw0rd@db/openproject?pool=20&encoding=unicode&reconnect=true` | PostgreSQL connection string |
| `PORT` | `8080` | Port for Caddy proxy |
| `PGDATA` | `/var/lib/postgresql/data` | PostgreSQL data directory |
| `OPDATA` | `/var/openproject/assets` | OpenProject assets directory |
| `IMAP_ENABLED` | `false` | Enable email receiving |
| `RAILS_MIN_THREADS` | `4` | Minimum Rails threads |
| `RAILS_MAX_THREADS` | `16` | Maximum Rails threads |

---

## Dependencies

### Runtime
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

### Build-time
- Caddy 2.x (proxy container)
- PostgreSQL 13 (database)
- Python 3 + Flask (prober utility)

---

## Python Rebuild Strategy

### Goals
- Replace Bash scripts with Python for better maintainability, testing, and cross-platform support
- Maintain backward compatibility with existing `.env` and configuration files
- Implement robust error handling and validation
- Add comprehensive logging and diagnostics
- Integrate with CI/CD for automated testing

### Proposed Python Components

1. **Configuration Manager** (`config_manager.py`)
   - Load and validate `.env` files
   - Manage `interactive_config.cfg`
   - Apply defaults and validate required keys

2. **Deployment Orchestrator** (`deploy.py`)
   - Render Caddyfile from template
   - Validate Docker Compose configuration
   - Launch services with health checks
   - Handle rollback on failure

3. **Backup Utility** (`backup.py`)
   - Replace `control/backup/entrypoint.sh`
   - Create timestamped backups of PostgreSQL and assets
   - Support incremental backups
   - Verify backup integrity

4. **Upgrade Utility** (`upgrade.py`)
   - Replace `control/upgrade/entrypoint.sh` and `00-db-upgrade.sh`
   - Detect PostgreSQL version
   - Perform `pg_upgrade` with safety checks
   - Rollback on failure

5. **Integration Test Runner** (`integration_test.py`)
   - Launch prober container
   - Probe HTTP/HTTPS endpoints
   - Validate proxy configuration
   - Provide user feedback and recommendations
   - Teardown on completion

6. **CLI Interface** (`cli.py`)
   - Unified command-line interface for all operations
   - Interactive prompts for configuration
   - Dry-run mode for validation
   - Verbose logging

### Directory Structure (Proposed)

```
/opt/openproject/
├── pyproject.toml              # Python project metadata
├── requirements.txt            # Python dependencies
├── src/
│   ├── __init__.py
│   ├── cli.py                  # Main CLI entry point
│   ├── config_manager.py       # Configuration management
│   ├── deploy.py               # Deployment orchestration
│   ├── backup.py               # Backup utility
│   ├── upgrade.py              # Upgrade utility
│   ├── integration_test.py     # Integration test runner
│   └── utils/
│       ├── docker.py           # Docker/Compose helpers
│       ├── logging.py          # Logging configuration
│       └── validation.py       # Configuration validation
└── tests/
    ├── test_config.py
    ├── test_deploy.py
    ├── test_backup.py
    └── test_upgrade.py
```

### Migration Plan

1. **Phase 1: Core Utilities**
   - Implement configuration manager
   - Add validation and defaults handling
   - Create CLI skeleton

2. **Phase 2: Deployment**
   - Port deployment logic to Python
   - Add template rendering (Caddyfile)
   - Implement health checks and rollback

3. **Phase 3: Control Plane**
   - Port backup script to Python
   - Port upgrade script to Python
   - Add safety checks and validation

4. **Phase 4: Integration Testing**
   - Implement integration test runner
   - Add prober orchestration
   - Provide user feedback and recommendations

5. **Phase 5: Documentation and CI/CD**
   - Update all documentation
   - Add GitHub Actions workflows
   - Implement automated tests

---

## Next Steps

1. Create Python project structure (`pyproject.toml`, `requirements.txt`)
2. Implement `config_manager.py` with validation
3. Port `interactive_config.sh` logic to Python CLI
4. Add unit tests for configuration management
5. Implement deployment orchestrator
6. Update documentation and CI/CD workflows

---

## Contributing

- All Python code should follow PEP 8 style guidelines
- Use type hints for function signatures
- Add docstrings for all public functions and classes
- Write unit tests for all new functionality
- Update this document as the architecture evolves

---

## License

This project follows the same license as the upstream OpenProject repository.
