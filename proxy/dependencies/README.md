# Dependencies - Proxy Component

This directory contains dependency tracking for the Proxy component.

## Files

### Documentation
- **`DEPENDENCIES.md`** - Reverse proxy and networking dependencies

## Purpose

The Proxy component provides web traffic routing and management:
- Reverse proxy for OpenProject web interface
- SSL/TLS termination and certificate management
- Load balancing and traffic distribution
- Security filtering and access control

## Dependency Categories

### Production Dependencies
- **Absolute**: Required for proxy operations
  - Caddy web server
  - Container runtime (Docker)
  - Network utilities for connectivity testing
  
- **Ad-Hoc**: Context-dependent
  - SSL certificate tools (for manual certificates)
  - DNS tools (for domain configuration)
  - Load testing tools (for performance validation)

### Developer Dependencies
- **Absolute**: Required for development
  - Configuration file editors
  - Network debugging tools (curl, httpie)
  - Version control (Git)
  
- **Ad-Hoc**: Optional development tools
  - Certificate generation tools (OpenSSL)
  - Traffic analysis tools
  - Performance monitoring utilities

## Proxy Features

### Traffic Management
- **Reverse proxy**: Routes requests to OpenProject backend
- **Load balancing**: Distributes traffic across multiple instances
- **Health checks**: Monitors backend service availability
- **Failover**: Automatic routing around failed services

### Security Features
- **SSL/TLS termination**: Handles HTTPS encryption
- **Certificate management**: Automatic certificate renewal
- **Access control**: IP filtering and rate limiting
- **Security headers**: HSTS, CSP, and other security policies

## Configuration

The proxy uses template-based configuration:
- **Caddyfile templates** with environment substitution
- **Runtime configuration** via environment variables
- **Automatic HTTPS** with Let's Encrypt integration
- **Custom domains** and multi-site support

## Integration

- **Frontend**: Receives all web traffic for OpenProject
- **Backend**: Routes to OpenProject application containers
- **Certificates**: Automatic HTTPS with minimal configuration
- **Monitoring**: Health endpoints for service monitoring