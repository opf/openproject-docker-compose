"""Test fixtures and utilities for the test suite."""

import pytest
import tempfile
import shutil
from pathlib import Path
from typing import Dict, Any
from unittest.mock import Mock

from openproject_config_manager.core.config import Configuration, DatabaseConfig, ProxyConfig, StorageConfig


@pytest.fixture
def temp_dir():
    """Create a temporary directory for test files."""
    temp_path = tempfile.mkdtemp()
    yield Path(temp_path)
    shutil.rmtree(temp_path)


@pytest.fixture
def sample_config_data():
    """Sample configuration data for testing."""
    return {
        'secret_key_base': 'a' * 64,
        'rails_env': 'production',
        'rails_cache_store': 'memcache',
        'database': {
            'adapter': 'postgresql',
            'host': 'db',
            'port': 5432,
            'name': 'openproject',
            'username': 'openproject',
            'password': 'test_password',
            'encoding': 'utf8'
        },
        'proxy': {
            'domain': 'openproject.example.com',
            'additional_domains': ['op.example.com'],
            'ssl_enabled': True,
            'lets_encrypt': True,
            'lets_encrypt_email': 'admin@example.com',
            'reverse_proxy_enabled': True
        },
        'storage': {
            'data_volume': 'openproject_data',
            'logs_volume': 'openproject_logs',
            'backup_enabled': True,
            'backup_schedule': '0 2 * * *',
            'backup_retention_days': 30,
            'backup_location': './backups'
        },
        'email_delivery_method': 'smtp',
        'smtp_address': 'smtp.example.com',
        'smtp_port': 587,
        'smtp_domain': 'example.com',
        'smtp_user_name': 'openproject@example.com',
        'smtp_password': 'smtp_password',
        'smtp_enable_starttls_auto': True,
        'memcached_server': 'cache:11211',
        'web_concurrency': 2,
        'web_timeout': 60,
        'web_max_requests': 1000,
        'force_ssl': True,
        'session_cookie_secure': True,
        'attachments_storage': 'file',
        'log_level': 'info',
        'rails_log_to_stdout': True,
        'custom_variables': {'CUSTOM_VAR': 'custom_value'}
    }


@pytest.fixture
def sample_configuration(sample_config_data):
    """Sample Configuration object for testing."""
    return Configuration(**sample_config_data)


@pytest.fixture
def sample_discovered_data():
    """Sample discovered data for testing."""
    return {
        'environment': {
            'relevant_vars': {
                'SECRET_KEY_BASE': 'existing_secret',
                'DATABASE_HOST': 'existing_db'
            },
            'relevant_count': 2,
            'sensitive_count': 1,
            'all_vars_count': 50,
            'docker_vars': {},
            'compose_vars': {},
            'dotenv_files': []
        },
        'system': {
            'platform': {
                'system': 'Linux',
                'release': '5.4.0',
                'hostname': 'test-host',
                'fqdn': 'test-host.local'
            },
            'hardware': {
                'cpu_count': 4,
                'memory': {
                    'total': 8589934592,  # 8GB
                    'available': 4294967296,  # 4GB
                    'total_gb': 8.0,
                    'available_gb': 4.0
                },
                'disk': {
                    'total': 107374182400,  # 100GB
                    'free': 53687091200,   # 50GB
                    'total_gb': 100.0,
                    'free_gb': 50.0
                }
            },
            'network': {
                'hostname': 'test-host',
                'interfaces': [
                    {
                        'name': 'eth0',
                        'addresses': {
                            'ipv4': [{'addr': '192.168.1.100'}]
                        }
                    }
                ]
            },
            'recommendations': {
                'memory': {'info': 'Sufficient memory for production deployment.'},
                'network': {'suggested_domain': 'test-host.local'},
                'performance': {'web_concurrency': 2}
            }
        },
        'docker': {
            'docker_available': True,
            'docker_info': {
                'version': '20.10.0',
                'containers': 5,
                'containers_running': 3,
                'images': 10
            },
            'containers': [
                {
                    'id': 'abc123',
                    'name': 'test_postgres',
                    'image': 'postgres:13',
                    'status': 'running',
                    'ports': {'5432/tcp': '0.0.0.0:5432'},
                    'database_type': 'postgres'
                }
            ],
            'database_containers': [
                {
                    'id': 'abc123',
                    'name': 'test_postgres',
                    'image': 'postgres:13',
                    'status': 'running',
                    'database_type': 'postgres'
                }
            ],
            'openproject_containers': [],
            'recommendations': {
                'setup': {'info': 'Docker is available and ready for deployment'},
                'database': {
                    'suggested_adapter': 'postgresql',
                    'suggested_host': 'test_postgres'
                }
            }
        }
    }


@pytest.fixture
def mock_docker_client():
    """Mock Docker client for testing."""
    mock_client = Mock()
    
    # Mock info method
    mock_client.info.return_value = {
        'Version': '20.10.0',
        'Containers': 5,
        'ContainersRunning': 3,
        'Images': 10
    }
    
    # Mock version method
    mock_client.version.return_value = {
        'Version': '20.10.0',
        'ApiVersion': '1.41'
    }
    
    # Mock ping method
    mock_client.ping.return_value = True
    
    # Mock containers
    mock_container = Mock()
    mock_container.id = 'abc123'
    mock_container.name = 'test_postgres'
    mock_container.image.tags = ['postgres:13']
    mock_container.status = 'running'
    mock_container.labels = {}
    mock_container.attrs = {
        'NetworkSettings': {'Ports': {'5432/tcp': [{'HostIp': '0.0.0.0', 'HostPort': '5432'}]}},
        'Mounts': [],
        'Config': {'Env': []}
    }
    
    mock_client.containers.list.return_value = [mock_container]
    
    # Mock images, networks, volumes
    mock_client.images.list.return_value = []
    mock_client.networks.list.return_value = []
    mock_client.volumes.list.return_value = []
    
    return mock_client


@pytest.fixture
def sample_cfg_content():
    """Sample .cfg file content for testing."""
    return '''# OpenProject Configuration
SECRET_KEY_BASE="test_secret_key"
RAILS_ENV="production"
DATABASE_ADAPTER="postgresql"
DATABASE_HOST="db"
DATABASE_PORT="5432"
DATABASE_NAME="openproject"
DATABASE_USERNAME="openproject"
DATABASE_PASSWORD="test_password"
DOMAIN="openproject.example.com"
SSL_ENABLED="true"
LETS_ENCRYPT="true"
LETS_ENCRYPT_EMAIL="admin@example.com"
'''


@pytest.fixture
def mock_ui():
    """Mock UI for testing interactive components."""
    mock = Mock()
    mock.show_title = Mock()
    mock.show_phase_header = Mock()
    mock.show_section_header = Mock()
    mock.show_step = Mock()
    mock.show_success = Mock()
    mock.show_error = Mock()
    mock.show_warning = Mock()
    mock.show_info = Mock()
    mock.prompt = Mock()
    mock.prompt_int = Mock()
    mock.prompt_password = Mock()
    mock.confirm = Mock()
    mock.select = Mock()
    return mock


@pytest.fixture
def mock_console_ui(mock_ui):
    """Mock ConsoleUI class."""
    return mock_ui


def create_test_config_file(path: Path, content: str = None):
    """Helper to create a test configuration file."""
    if content is None:
        content = '''SECRET_KEY_BASE="test_secret"
RAILS_ENV="production"
DATABASE_ADAPTER="postgresql"
DATABASE_HOST="db"
DATABASE_PORT="5432"
'''
    
    path.write_text(content, encoding='utf-8')
    return path