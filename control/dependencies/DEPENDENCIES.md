# Control Component Dependencies

This component handles OpenProject backup and upgrade operations using PostgreSQL tools.

## Production Dependencies

### Absolute (Required for all installations)
- **Docker** - Container runtime for control operations
  ```bash
  # Ubuntu/Debian
  sudo apt-get update && sudo apt-get install docker.io
  # RHEL/CentOS
  sudo yum install docker
  ```

- **PostgreSQL Client Tools** - Database backup/restore operations
  ```bash
  # Ubuntu/Debian
  sudo apt-get install postgresql-client
  # RHEL/CentOS
  sudo yum install postgresql
  ```

### Ad-Hoc (Context-dependent)
- **GNU GPG** - Package verification (when installing PostgreSQL from official repos)
  ```bash
  # Ubuntu/Debian
  sudo apt-get install gnupg2
  # RHEL/CentOS
  sudo yum install gnupg2
  ```

- **wget** - Download PostgreSQL signing keys
  ```bash
  # Ubuntu/Debian
  sudo apt-get install wget
  # RHEL/CentOS
  sudo yum install wget
  ```

## Developer Dependencies

### Absolute (Required for development)
- **Docker Compose** - Multi-container development
  ```bash
  # Install via pip
  pip install docker-compose
  # Or via package manager
  sudo apt-get install docker-compose
  ```

- **Git** - Version control for backup scripts
  ```bash
  # Ubuntu/Debian
  sudo apt-get install git
  # RHEL/CentOS
  sudo yum install git
  ```

### Ad-Hoc (Development tools)
- **Make** - Build automation (if Makefile added)
  ```bash
  # Ubuntu/Debian
  sudo apt-get install make
  # RHEL/CentOS
  sudo yum install make
  ```

- **Bash/Shell Linting** - Script quality checking
  ```bash
  # Ubuntu/Debian
  sudo apt-get install shellcheck
  # RHEL/CentOS
  sudo yum install ShellCheck
  ```

## Container Dependencies (Dockerfile)
- **Base Image**: `debian:12`
- **PostgreSQL Versions**: 9.6, 10, 13 (for upgrade compatibility)
- **Locale Support**: `en_US.UTF-8`

## Notes
- This component requires specific PostgreSQL versions for database upgrades
- Backup operations depend on PostgreSQL client tools matching server versions
- Control scripts are designed for Debian-based containers