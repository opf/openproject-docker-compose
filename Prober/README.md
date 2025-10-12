# Prober Utility

**External Repository**: [`docker-prober-utility`](https://github.com/JustinCBates/docker_prober_utility)  
**Submodule Location**: `external/prober/`  
**Purpose**: HTTP/HTTPS endpoint validation and network testing utility

## Overview

The Prober Utility is a **standalone, lightweight validation tool** developed in its own repository. This folder serves as a **placeholder and documentation** for the validation functionality used by both Configuration and Deployment Managers.

## Repository Structure

```
external/prober/                  # Git submodule (actual implementation)
Prober/                          # This folder (documentation & integration)
├── README.md                    # This file
├── INTEGRATION.md              # How to integrate with main project
└── examples/                   # Usage examples
```

## Key Features

- **HTTP/HTTPS Testing**: Validate endpoint accessibility and response codes
- **DNS Resolution**: Test domain name resolution and routing
- **SSL Certificate Validation**: Verify certificate validity and chain
- **Port Testing**: Check port availability and connectivity
- **Network Diagnostics**: Comprehensive network stack testing
- **Docker Integration**: Lightweight container for isolated testing

## Purpose in OpenProject Architecture

The Prober serves as a **shared validation utility** used by multiple managers:

1. **Configuration Manager**: Real-time validation during interactive configuration
2. **Deployment Manager**: Preflight checks before deployment
3. **Management Manager**: Health monitoring and diagnostics

## Validation Capabilities

### HTTP/HTTPS Endpoint Testing
```python
prober_client = ProberClient()

# Test HTTP endpoint
http_result = prober_client.test_http(
    url="http://example.com:8080",
    expected_status=200,
    timeout=10
)

# Test HTTPS with SSL validation
https_result = prober_client.test_https(
    url="https://example.com",
    verify_ssl=True,
    check_certificate=True
)
```

### DNS Resolution Testing
```python
# Test DNS resolution
dns_result = prober_client.test_dns(
    domain="example.com",
    expected_ip="203.0.113.42",
    dns_servers=["8.8.8.8", "1.1.1.1"]
)
```

### Port Connectivity Testing
```python
# Test port accessibility
port_result = prober_client.test_port(
    host="example.com",
    port=443,
    protocol="tcp",
    timeout=5
)
```

### SSL Certificate Validation
```python
# Validate SSL certificate
ssl_result = prober_client.test_ssl(
    domain="example.com",
    port=443,
    check_expiry=True,
    check_chain=True
)
```

## Integration Modes

### Quick Mode (Configuration Manager)
**Purpose**: Fast validation during interactive configuration
```python
# Lightweight validation for immediate feedback
quick_result = prober_client.validate_quick({
    'domain': 'example.com',
    'port': 8080,
    'ssl_enabled': True
})
```

### Thorough Mode (Deployment Manager)
**Purpose**: Comprehensive pre-deployment validation
```python
# Complete validation before deployment
thorough_result = prober_client.validate_thorough({
    'domain': 'example.com',
    'ports': [80, 443, 8080],
    'ssl_config': {...},
    'proxy_config': {...}
})
```

### Monitoring Mode (Management Manager)
**Purpose**: Ongoing health checks and diagnostics
```python
# Continuous monitoring
monitoring_result = prober_client.monitor_endpoints([
    'https://example.com/health',
    'https://example.com/api/status'
], interval=60)
```

## Docker Container Usage

The prober runs as a lightweight Docker container for isolated testing:

```bash
# Run prober container
docker run --rm \
  -e TARGET_URL=https://example.com \
  -e TEST_TYPE=comprehensive \
  prober-utility:latest
```

### Container Environment Variables
- `TARGET_URL`: URL to test
- `TEST_TYPE`: `quick`, `thorough`, or `monitoring`
- `TIMEOUT`: Request timeout in seconds
- `VERIFY_SSL`: Enable SSL certificate validation
- `DNS_SERVERS`: Custom DNS servers (comma-separated)

## CLI Integration

```bash
# Main project CLI uses prober for validation
openproject validate                # Quick validation
openproject validate --thorough     # Comprehensive validation
openproject monitor                 # Start monitoring mode
openproject diagnose               # Network diagnostics
```

## Test Results Format

```python
class ProberTestResult:
    success: bool
    test_type: str  # 'quick', 'thorough', 'monitoring'
    timestamp: datetime
    duration: float
    
    # Individual test results
    dns_resolution: TestResult
    port_connectivity: TestResult
    http_response: TestResult
    ssl_validation: TestResult
    
    # Summary
    errors: List[str]
    warnings: List[str]
    recommendations: List[str]

class TestResult:
    test_name: str
    passed: bool
    message: str
    details: dict
    duration: float
```

## Error Handling

### Common Test Scenarios
1. **DNS Resolution Failure**: Domain doesn't resolve
2. **Port Unreachable**: Firewall or service not running
3. **SSL Certificate Invalid**: Expired, self-signed, or wrong domain
4. **HTTP Error Codes**: 404, 500, timeout responses
5. **Network Connectivity**: Routing or connectivity issues

### Error Response Format
```python
{
    "error_type": "dns_resolution_failed",
    "message": "Domain 'example.com' could not be resolved",
    "details": {
        "domain": "example.com",
        "dns_servers_tried": ["8.8.8.8", "1.1.1.1"],
        "error_code": "NXDOMAIN"
    },
    "recommendations": [
        "Check domain spelling",
        "Verify DNS configuration",
        "Try alternative DNS servers"
    ]
}
```

## Development Status

- ✅ **Repository Exists**: Standalone prober utility already functional
- ✅ **Docker Container**: Containerized testing environment
- ✅ **Basic Testing**: HTTP/HTTPS endpoint validation
- 🔄 **Integration API**: Client interfaces for manager integration
- ⏳ **Advanced Features**: SSL validation, DNS testing, monitoring mode
- ⏳ **Documentation**: Usage examples and troubleshooting

## Dependencies

**Container Dependencies**:
- `python:3.11-alpine` - Lightweight Python runtime
- `curl` - HTTP testing
- `dig` - DNS resolution testing
- `openssl` - SSL certificate validation

**Client Dependencies** (for integration):
- `requests>=2.31.0` - HTTP client for prober API
- `docker>=7.0.0` - Container management

## Integration Examples

### Configuration Manager Integration
```python
# Real-time validation during configuration
def validate_domain_input(domain: str) -> bool:
    result = prober_client.test_dns(domain)
    if not result.passed:
        console.print(f"⚠️ {result.message}")
        return False
    return True
```

### Deployment Manager Integration
```python
# Preflight check before deployment
def preflight_validation(config: dict) -> bool:
    result = prober_client.validate_thorough(config)
    if not result.success:
        logger.error("Preflight validation failed")
        for error in result.errors:
            logger.error(f"  - {error}")
        return False
    return True
```

## Next Steps

1. **Enhance Prober API**: Add client interfaces for manager integration
2. **Expand Test Coverage**: SSL, DNS, and advanced network testing
3. **Add Monitoring Mode**: Continuous health checking capabilities
4. **Improve Error Reporting**: Detailed diagnostics and recommendations
5. **Performance Optimization**: Faster testing with parallel execution

---

**Note**: This folder is for **documentation and integration** only. The actual implementation lives in the external `docker-prober-utility` repository and is consumed as a git submodule.

For development, work in: `external/prober/`  
For integration, reference: `Prober/`