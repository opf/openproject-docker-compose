# Dependencies for OpenProject Docker Compose (Main Repo)

## Production Dependencies (Required for all users)

### Absolute (Always needed)
- docker-compose                # Container orchestration
- docker                       # Container runtime

### Ad Hoc (Needed for optional features)  
- git                          # Version control (if using git submodules)
- curl                         # HTTP requests (if downloading resources)
- openssl                      # SSL certificates (if generating certs)

## Developer Dependencies (Only needed for development)

### Absolute (Core development tools)
- git                          # Version control
- make                         # Build automation (if using Makefile)

### Ad Hoc (Optional development tools)
- jq                           # JSON processing (if parsing JSON configs)
- yamllint                     # YAML validation (if validating compose files)
- shellcheck                   # Shell script linting (if using shell scripts)

## Installation Commands

### Production Only (Minimal)
```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com | sh
sudo apt-get install docker-compose-plugin
```

### Development Environment
```bash
# Install development tools
sudo apt-get install git make jq yamllint shellcheck
```

## System Requirements
- Linux or macOS
- 4GB+ RAM
- 10GB+ disk space

## Notes
- Docker is the primary dependency
- Git submodules require git to be installed
- This file tracks what we discover during development
- Update when adding new dependencies or features