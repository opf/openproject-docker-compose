# Dependencies - Main Repository

This directory contains dependency tracking for the main OpenProject Docker Compose repository.

## Files

### Documentation
- **`DEPENDENCIES.md`** - System dependencies for the main OpenProject setup

### Tools
- **`check_deps.sh`** - Cross-platform system dependency checker and installer

## Usage

### Check System Dependencies
```bash
# Check what's installed
cd dependencies
./check_deps.sh

# Auto-install missing dependencies
./check_deps.sh --install
```

## Dependency Categories

### System Requirements (Absolute)
- **Docker** - Container runtime for OpenProject services
- **Docker Compose** - Multi-container orchestration
- **Git** - Version control for project updates

### Development Tools (Ad-Hoc)
- **Make** - Build automation (if using Makefiles)
- **curl** - API testing and debugging
- **jq** - JSON processing for configuration

## Repository Role

The main repository serves as the **orchestration layer** for the entire OpenProject system:
- Manages Docker Compose configuration
- Coordinates between all components
- Provides system-level dependency checking
- Handles overall project configuration

## Cross-Platform Support

The `check_deps.sh` script supports:
- **Linux** (Ubuntu, Debian, RHEL, CentOS)
- **macOS** (via Homebrew)
- **Windows** (via package managers when available)

## Integration

This dependency system integrates with all component repositories:
- **config-manager** - Python dependencies
- **deploy-manager** - Deployment tool dependencies  
- **prober** - Service monitoring dependencies
- **control** - Database management dependencies
- **proxy** - Reverse proxy dependencies