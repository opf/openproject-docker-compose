# Proxy Component

A Caddy-based reverse proxy for OpenProject installations.

## Overview

This component provides a lightweight, secure reverse proxy using Caddy server. It handles HTTPS termination, request routing, and can automatically manage SSL certificates.

## Features

- **Automatic HTTPS**: Caddy can automatically obtain and renew SSL certificates
- **Flexible Configuration**: Template-based Caddyfile with environment variable substitution
- **Lightweight**: Based on the official Caddy Docker image
- **Production Ready**: Suitable for production deployments

## Usage

The proxy is configured via Docker Compose with the `APP_HOST` environment variable:

```bash
docker-compose up proxy
```

## Configuration

The proxy uses a template-based configuration system:
- `Caddyfile.template` - Configuration template
- `APP_HOST` environment variable - Target application host

## Dependencies

