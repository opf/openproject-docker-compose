# Proxy Component Dependencies

This component provides a Caddy-based reverse proxy for OpenProject.

## Production Dependencies

### Absolute (Required for all installations)
- **Docker** - Container runtime for proxy service
  ```bash
  # Ubuntu/Debian
  sudo apt-get update && sudo apt-get install docker.io
  # RHEL/CentOS
  sudo yum install docker
  ```

- **Network Access** - Internet connectivity for Caddy image
  ```bash
  # Verify connectivity
  curl -I https://registry.hub.docker.com
  ```

### Ad-Hoc (Context-dependent)
- **SSL/TLS Certificates** - HTTPS support (if not using Caddy's automatic HTTPS)
  ```bash
  # Manual certificate setup
  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
  ```

- **Custom DNS** - Domain name configuration
  ```bash
  # Update /etc/hosts for local development
  echo "127.0.0.1 your-domain.local" >> /etc/hosts
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

- **Text Editor** - Caddyfile configuration editing
  ```bash
  # Any text editor, e.g., nano, vim, or VS Code
  sudo apt-get install nano
  ```

### Ad-Hoc (Development tools)
- **Caddy CLI** - Local testing and configuration validation
  ```bash
  # Install Caddy locally for testing
  sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
  sudo apt update && sudo apt install caddy
  ```

- **curl/HTTPie** - Proxy testing and debugging
  ```bash
  # Ubuntu/Debian
  sudo apt-get install curl httpie
  # RHEL/CentOS
  sudo yum install curl
  ```

- **OpenSSL** - Certificate generation and testing
  ```bash
  # Ubuntu/Debian
  sudo apt-get install openssl
  # RHEL/CentOS
  sudo yum install openssl
  ```

## Container Dependencies (Dockerfile)
- **Base Image**: `caddy:2`
- **Configuration**: Caddyfile.template with APP_HOST substitution
- **Entry Point**: Caddy server with custom configuration

## Notes
- Proxy configuration depends on APP_HOST environment variable
- Caddy automatically handles HTTPS certificates in production
- Template substitution happens at build time, not runtime
- Consider using Caddy's automatic HTTPS for production deployments