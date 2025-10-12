# Interactive Configuration System - Architecture

## Overview

The Interactive Configuration System guides users through OpenProject deployment setup with an intelligent, interactive experience. It discovers environment defaults, collects user preferences, validates choices, and produces a configuration file ready for deployment.

---

## Core Philosophy

1. **Discovery-First**: Auto-detect sensible defaults from the environment
2. **Progressive Disclosure**: Only ask what's necessary based on user's environment
3. **Validation-in-Loop**: Test configuration as it's built, not after
4. **Beautiful UX**: Use Rich library for modern terminal UI
5. **Prober-Integrated**: Leverage the prober utility for live validation

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Interactive Configuration CLI                     │
│                  (openproject configure --interactive)               │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Configuration Orchestrator                      │
│                  (interactive_config_orchestrator.py)                │
│  Coordinates: Discovery → Collection → Validation → Finalization    │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ├──────────────┬──────────────┬──────────────┐
                   ▼              ▼              ▼              ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │   Discovery  │ │  Interactive │ │  Validation  │ │Configuration │
        │    Engine    │ │  Collector   │ │   Engine     │ │  Finalizer   │
        └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
               │                │                │                │
               ▼                ▼                ▼                ▼
        ┌──────────────────────────────────────────────────────────┐
        │              Prober Utility (External Repo)              │
        │         Tests real-world proxy/network scenarios         │
        └──────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Configuration Orchestrator
**File**: `src/openproject_deploy/interactive/orchestrator.py`

**Responsibilities**:
- Coordinate the 4-phase configuration flow
- Manage state between phases
- Handle user interruptions (Ctrl+C)
- Resume from partial configurations
- Generate final configuration file

**Interface**:
```python
class InteractiveConfigOrchestrator:
    def __init__(self, config_manager: ConfigManager, prober_client: ProberClient)
    
    def run_interactive_config(
        resume: bool = False,
        skip_discovery: bool = False
    ) -> ConfigurationResult
    
    def save_partial_state(state: ConfigState) -> None
    def load_partial_state() -> Optional[ConfigState]
    
class ConfigurationResult:
    success: bool
    config_file_path: Path
    validation_results: List[ValidationResult]
    recommendations: List[str]
```

**Flow**:
```
1. Check for partial state (resume)
2. Run Discovery Engine
3. Run Interactive Collector
4. Run Validation Engine
5. Finalize Configuration
```

---

### 2. Discovery Engine
**File**: `src/openproject_deploy/interactive/discovery.py`

**Responsibilities**:
- Detect operating system and distribution
- Discover network configuration (hostname, IP, interfaces)
- Check for existing Docker installation
- Detect available ports
- Scan for existing OpenProject installations
- Check SSL certificate availability
- Suggest intelligent defaults

**Interface**:
```python
class DiscoveryEngine:
    def __init__(self)
    
    def discover_all() -> DiscoveryResults
    def discover_system() -> SystemInfo
    def discover_network() -> NetworkInfo
    def discover_docker() -> DockerInfo
    def discover_ports() -> PortInfo
    def discover_certificates() -> CertificateInfo
    
class DiscoveryResults:
    system: SystemInfo
    network: NetworkInfo
    docker: DockerInfo
    ports: PortInfo
    certificates: CertificateInfo
    suggested_defaults: Dict[str, str]
    
class SystemInfo:
    os_family: str  # debian, redhat, arch, etc.
    os_distribution: str  # ubuntu, debian, centos, etc.
    os_version: str
    architecture: str  # x86_64, arm64, etc.
    available_memory_gb: float
    available_disk_gb: float
    
class NetworkInfo:
    hostname: str
    fqdn: str
    primary_ip: str
    interfaces: List[NetworkInterface]
    has_public_ip: bool
    reverse_dns: Optional[str]
    
class DockerInfo:
    is_installed: bool
    version: str
    docker_compose_version: str
    is_running: bool
    available_images: List[str]
    
class PortInfo:
    available_ports: List[int]
    recommended_http_port: int
    recommended_https_port: int
    conflicts: List[PortConflict]
    
class CertificateInfo:
    has_letsencrypt: bool
    has_custom_cert: bool
    cert_path: Optional[Path]
    key_path: Optional[Path]
    cert_domains: List[str]
```

**Discovery Process**:
```python
# System Discovery
- Run: uname -a, lsb_release, /etc/os-release
- Memory: free -h, /proc/meminfo
- Disk: df -h

# Network Discovery
- Hostname: hostname, hostname -f
- IP: ip addr, ifconfig
- Reverse DNS: dig -x <ip>
- Public IP check: curl ifconfig.me

# Docker Discovery
- Check: docker --version, docker compose version
- Status: docker info
- Images: docker images

# Port Discovery
- Scan: netstat, ss -tuln
- Check common ports: 80, 443, 8080, 8443

# Certificate Discovery
- Check: /etc/letsencrypt/live/*
- Check: ~/.ssl/, /etc/ssl/certs/
```

---

### 3. Interactive Collector
**File**: `src/openproject_deploy/interactive/collector.py`

**Responsibilities**:
- Present beautiful, branded UI (Rich library)
- Ask questions based on discovery results
- Provide smart defaults from discovery
- Validate input in real-time
- Show helpful hints and examples
- Support navigation (back, skip, quit)
- Group questions into logical sections

**Interface**:
```python
class InteractiveCollector:
    def __init__(
        self,
        discovery_results: DiscoveryResults,
        existing_config: Optional[ConfigManager]
    )
    
    def collect_configuration() -> CollectedConfig
    def collect_section(section: ConfigSection) -> SectionResult
    def ask_question(question: Question) -> Answer
    
class Question:
    key: str
    prompt: str
    description: str
    default: Optional[str]
    validator: Callable[[str], ValidationResult]
    choices: Optional[List[str]]  # For select questions
    required: bool
    depends_on: Optional[str]  # Conditional questions
    
class CollectedConfig:
    sections: Dict[str, SectionResult]
    skipped: List[str]
    needs_validation: List[str]
```

**Configuration Sections**:

```python
# Section 1: Environment Type
- Question: Environment purpose? (production, development, staging)
- Affects: Suggestions for ports, HTTPS, resource allocation

# Section 2: Repository & Version
- Question: OpenProject version/tag?
- Default: Latest stable (from discovery or 16-slim)
- Question: Git username/email? (for tracking changes)

# Section 3: Network Configuration
- Question: Domain name or IP?
- Default: From discovery (FQDN or primary IP)
- Question: Enable HTTPS?
- Default: Yes if public IP, No if localhost/private
- Question: HTTP port?
- Default: 80 or first available from discovery
- Question: HTTPS port? (if HTTPS enabled)
- Default: 443 or first available from discovery

# Section 4: URL Configuration
- Question: URL prefix/namespace?
- Default: None (root path)
- Example: /projects, /openproject
- Question: Enable URL namespacing?
- Default: No

# Section 5: Proxy Configuration
- Question: TLS mode? (letsencrypt, letsencrypt_staging, custom, none)
- Default: letsencrypt_staging if HTTPS + public, none otherwise
- Question: Bind address?
- Default: 0.0.0.0 (all interfaces)
- Question: Force HTTPS redirect?
- Default: Yes if HTTPS enabled

# Section 6: Database Configuration
- Question: Database admin password?
- Generate: Strong random password if not provided
- Question: Database storage type?
- Choices: docker-volumes (default), host-directory
- Question: Database data directory? (if host-directory)

# Section 7: Application Storage
- Question: OpenProject assets storage type?
- Choices: docker-volumes (default), host-directory
- Question: Assets directory? (if host-directory)
- Default: /var/openproject/assets
```

**Rich UI Components**:
```python
from rich.console import Console
from rich.prompt import Prompt, Confirm, IntPrompt
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress
from rich.tree import Tree

# Example UI:
console = Console()

# Section header
console.print(Panel.fit(
    "[bold cyan]Network Configuration[/bold cyan]\n"
    "Configure how OpenProject will be accessed",
    border_style="cyan"
))

# Question with hint
answer = Prompt.ask(
    "[bold]Domain name or IP address[/bold]",
    default=discovery.network.fqdn,
    console=console
)

# Progress through sections
with Progress() as progress:
    task = progress.add_task("[cyan]Configuring...", total=7)
    # Update as sections complete
    progress.update(task, advance=1)

# Summary table
table = Table(title="Configuration Summary")
table.add_column("Setting", style="cyan")
table.add_column("Value", style="green")
table.add_row("Domain", config.domain_name)
table.add_row("HTTPS", "Enabled" if config.https else "Disabled")
console.print(table)
```

---

### 4. Validation Engine
**File**: `src/openproject_deploy/interactive/validation.py`

**Responsibilities**:
- Validate configuration completeness
- Check logical consistency (e.g., HTTPS requires cert)
- Test network reachability
- Verify port availability
- **Invoke Prober for live validation**
- Provide actionable error messages

**Interface**:
```python
class ValidationEngine:
    def __init__(
        self,
        config: CollectedConfig,
        prober_client: ProberClient
    )
    
    def validate_all() -> ValidationReport
    def validate_network() -> NetworkValidation
    def validate_ports() -> PortValidation
    def validate_certificates() -> CertificateValidation
    def validate_live_with_prober() -> ProberValidation
    
class ValidationReport:
    is_valid: bool
    errors: List[ValidationError]
    warnings: List[ValidationWarning]
    recommendations: List[str]
    prober_results: Optional[ProberValidation]
    
class ValidationError:
    field: str
    message: str
    severity: Severity  # ERROR, WARNING, INFO
    fix_suggestion: str
```

**Validation Checks**:

```python
# 1. Completeness Validation
- All required fields present
- No conflicting settings

# 2. Network Validation
- Domain/IP is reachable
- DNS resolution works (if domain)
- Ports are available (not in use)

# 3. Security Validation
- HTTPS enabled for production environments
- Strong password for database
- Certificate available if HTTPS + custom cert

# 4. Resource Validation
- Sufficient disk space
- Sufficient memory
- Docker daemon running

# 5. Live Prober Validation (IMPORTANT!)
- Start minimal proxy with user's config
- Test HTTP endpoint
- Test HTTPS endpoint (if enabled)
- Test URL rewriting (if namespace enabled)
- Test header forwarding
- Measure response time
- Generate recommendations
```

---

### 5. Prober Integration (External Repo)
**File**: Uses existing `docker_prober_utility` repo

**Responsibilities**:
- Accept configuration as JSON/ENV
- Launch minimal Caddy proxy + hello backend
- Probe configured endpoints
- Test TLS if enabled
- Test URL rewriting if enabled
- Return detailed test results
- Clean up test containers

**Prober API** (to be implemented in prober repo):
```python
# In docker_prober_utility/api.py

class ProberClient:
    def __init__(self, docker_client: DockerClient)
    
    def test_configuration(config: Dict[str, str]) -> ProberTestResult
    def cleanup() -> None
    
class ProberTestResult:
    success: bool
    http_accessible: bool
    http_status_code: int
    http_response_time_ms: float
    https_accessible: bool
    https_status_code: int
    https_response_time_ms: float
    url_rewriting_works: bool
    headers_forwarded_correctly: bool
    tls_version: Optional[str]
    certificate_valid: bool
    recommendations: List[str]
    errors: List[str]
```

**Prober Test Flow**:
```
1. Receive configuration from Interactive Collector
2. Generate minimal Caddyfile from config
3. docker run -d prober with config
4. Wait for container healthy
5. Test HTTP endpoint: curl http://localhost:<port>
6. Test HTTPS endpoint: curl https://localhost:<port> (if enabled)
7. Test URL rewriting: curl http://localhost/<namespace>/
8. Check response headers
9. Measure response times
10. Collect logs
11. docker stop & rm prober
12. Return ProberTestResult
```

---

### 6. Configuration Finalizer
**File**: `src/openproject_deploy/interactive/finalizer.py`

**Responsibilities**:
- Merge discovery defaults + user input + validation fixes
- Generate final `.env` file
- Generate final `interactive_config.cfg` file
- Write configuration summary
- Create backup of existing config
- Provide next-step instructions

**Interface**:
```python
class ConfigurationFinalizer:
    def __init__(
        self,
        collected_config: CollectedConfig,
        validation_report: ValidationReport,
        config_manager: ConfigManager
    )
    
    def finalize() -> FinalizationResult
    def write_env_file(path: Path) -> None
    def write_cfg_file(path: Path) -> None
    def create_backup() -> Path
    def generate_summary() -> str
    
class FinalizationResult:
    env_file_path: Path
    cfg_file_path: Path
    backup_path: Optional[Path]
    summary: str
    next_steps: List[str]
```

**Finalization Process**:
```
1. Backup existing .env and .cfg (if they exist)
2. Merge configuration:
   - Discovery defaults (lowest priority)
   - User input (medium priority)
   - Validation fixes (highest priority)
3. Write .env file (Docker Compose format)
4. Write interactive_config.cfg (Bash-style format)
5. Generate human-readable summary
6. Display next steps:
   - "Run: openproject validate"
   - "Run: openproject deploy"
   - "Or run: openproject test" (integration prober)
```

---

## File Structure

```
src/openproject_deploy/
├── interactive/
│   ├── __init__.py
│   ├── orchestrator.py         # Main coordinator
│   ├── discovery.py            # Environment discovery
│   ├── collector.py            # Interactive Q&A (Rich UI)
│   ├── validation.py           # Configuration validation
│   ├── finalizer.py            # Config file generation
│   └── prober_client.py        # Prober integration
│
tests/interactive/
├── test_discovery.py
├── test_collector.py
├── test_validation.py
├── test_finalizer.py
└── test_orchestrator.py
```

---

## CLI Integration

```python
# In cli.py

@main.command()
@click.option('--resume', is_flag=True, help='Resume interrupted configuration')
@click.option('--skip-discovery', is_flag=True, help='Skip environment discovery')
@click.option('--skip-validation', is_flag=True, help='Skip live validation')
def configure(resume: bool, skip_discovery: bool, skip_validation: bool):
    """Interactive configuration wizard"""
    
    from openproject_deploy.interactive.orchestrator import InteractiveConfigOrchestrator
    from openproject_deploy.interactive.prober_client import ProberClient
    
    config_mgr = ConfigManager()
    prober = ProberClient(DockerClient())
    orchestrator = InteractiveConfigOrchestrator(config_mgr, prober)
    
    result = orchestrator.run_interactive_config(
        resume=resume,
        skip_discovery=skip_discovery
    )
    
    if result.success:
        console.print("[green]✓[/green] Configuration complete!")
        console.print(f"Config written to: {result.config_file_path}")
        console.print("\nNext steps:")
        for step in result.next_steps:
            console.print(f"  • {step}")
    else:
        console.print("[red]✗[/red] Configuration failed")
        for error in result.validation_results:
            console.print(f"  [red]•[/red] {error.message}")
```

---

## User Experience Example

```
╭──────────────────────────────────────────────────────────────╮
│  🚀 OpenProject Interactive Configuration                    │
│  Let's configure your OpenProject deployment!                │
╰──────────────────────────────────────────────────────────────╯

🔍 Discovering your environment...
  ✓ Operating System: Debian 12 (Bookworm)
  ✓ Network: srv1035368.hstgr.cloud (203.0.113.42)
  ✓ Docker: 24.0.5, Compose 2.20.2
  ✓ Available Ports: 80, 443, 8080
  ✓ Memory: 8 GB available

╭─────────────── Section 1/7: Environment Type ───────────────╮
│ What is this environment for?                               │
│                                                              │
│ 1) Production (public-facing)                               │
│ 2) Development (local testing)                              │
│ 3) Staging (pre-production)                                 │
│                                                              │
│ Select [1-3]: 1                                             │
╰──────────────────────────────────────────────────────────────╯

✓ Production environment selected

╭─────────────── Section 2/7: Network Configuration ──────────╮
│ Domain name or IP address                                   │
│ This is how users will access OpenProject                   │
│                                                              │
│ [default: srv1035368.hstgr.cloud]: ▌                        │
╰──────────────────────────────────────────────────────────────╯

✓ Using: srv1035368.hstgr.cloud

Enable HTTPS? [Y/n]: y
✓ HTTPS enabled

HTTP port [default: 80]: 
✓ Using port 80

HTTPS port [default: 443]: 
✓ Using port 443

╭──────────── Section 3/7: TLS Configuration ─────────────────╮
│ TLS certificate mode:                                       │
│                                                              │
│ 1) Let's Encrypt (automatic, production)                   │
│ 2) Let's Encrypt Staging (automatic, testing)              │
│ 3) Custom certificate (provide your own)                   │
│ 4) None (HTTP only - not recommended for production)       │
│                                                              │
│ Select [1-4] [default: 1]: 2                                │
╰──────────────────────────────────────────────────────────────╯

✓ Using Let's Encrypt Staging

... (more sections) ...

╭──────────────── Configuration Summary ──────────────────────╮
│ ┌─────────────────────────┬───────────────────────────────┐│
│ │ Setting                 │ Value                         ││
│ ├─────────────────────────┼───────────────────────────────┤│
│ │ Environment             │ Production                    ││
│ │ Domain                  │ srv1035368.hstgr.cloud        ││
│ │ HTTPS                   │ Enabled                       ││
│ │ TLS Mode                │ Let's Encrypt Staging         ││
│ │ HTTP Port               │ 80                            ││
│ │ HTTPS Port              │ 443                           ││
│ │ OpenProject Version     │ 16-slim                       ││
│ │ Database Storage        │ Docker Volumes                ││
│ └─────────────────────────┴───────────────────────────────┘│
╰──────────────────────────────────────────────────────────────╯

🧪 Running live validation with prober...
  ✓ Starting test environment
  ✓ HTTP endpoint accessible (15ms)
  ✓ HTTPS endpoint accessible (23ms)
  ✓ TLS certificate valid
  ✓ Headers forwarded correctly
  ✓ Cleaning up test environment

✅ Configuration is valid!

💾 Saving configuration...
  ✓ Backup created: .env.backup.2025-10-11T21-30-00
  ✓ Written: .env
  ✓ Written: scripts/installation_scripts/interactive_config.cfg

Next steps:
  1. Review configuration: openproject config
  2. Test deployment: openproject test
  3. Deploy OpenProject: openproject deploy
```

---

## Prober Enhancements Needed

To support this architecture, the prober repo needs:

### 1. Accept Configuration via JSON
```python
# prober/config_loader.py
def load_config_from_json(json_str: str) -> ProberConfig
def load_config_from_env() -> ProberConfig
```

### 2. Return Structured Results
```python
# prober/test_runner.py
class TestRunner:
    def run_tests(config: ProberConfig) -> ProberTestResult
    def test_http() -> TestResult
    def test_https() -> TestResult
    def test_url_rewriting() -> TestResult
    def test_headers() -> TestResult
```

### 3. API Interface
```python
# prober/api.py
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/test', methods=['POST'])
def test_configuration():
    config = request.json
    result = TestRunner().run_tests(config)
    return jsonify(result.to_dict())

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})
```

---

## Migration Strategy

### Phase 1: Build Interactive System (This Proposal)
- Implement all 6 components
- Integrate with existing ConfigManager
- Use prober for validation

### Phase 2: Enhance Prober (Parallel Work)
- Add JSON config input
- Add structured result output
- Add API interface (optional)

### Phase 3: Deprecate Bash Scripts
- Mark `interactive_config.sh` as deprecated
- Update documentation
- Provide migration path

---

## Open Questions

1. **Should the prober run as:**
   - A) Docker container with API (cleaner, requires build)
   - B) Python script called directly (simpler, requires Python on host)
   - C) Both (flexible, more complexity)

2. **Should discovery be cacheable?**
   - Cache results for X minutes to speed up re-runs?

3. **Should we support config templates?**
   - Pre-defined configs for common scenarios (dev, prod, staging)?

4. **Should validation be optional or mandatory?**
   - Skip prober validation for advanced users?

5. **Should we support non-interactive mode?**
   - Accept all config via CLI flags for automation?

---

## Approval Checklist

- [ ] Overall architecture makes sense
- [ ] Discovery scope is appropriate
- [ ] Interactive collector UX approach is good
- [ ] Validation strategy (especially prober) is sound
- [ ] Prober enhancements are feasible
- [ ] File structure is clear
- [ ] Ready to proceed with implementation

---

**Next Step**: Once approved, we'll create detailed implementation tasks and begin with the Discovery Engine.
