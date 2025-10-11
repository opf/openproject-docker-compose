"""
Configuration Manager for OpenProject deployment

This module handles loading, validating, and managing configuration from:
- .env files (Docker Compose environment variables)
- interactive_config.cfg files (installation script configuration)
- Environment variables
"""

import os
from pathlib import Path
from typing import Dict, Optional, List
from dotenv import dotenv_values
import logging

logger = logging.getLogger(__name__)


class ConfigManager:
    """Manages configuration for OpenProject deployment"""

    # Required configuration keys
    REQUIRED_KEYS = [
        "OPENPROJECT_HOST__NAME",
        "DOMAIN_NAME",
        "OPENPROJECT_HTTPS",
        "OPENPROJECT_TAG",
    ]

    # Optional keys with defaults
    DEFAULTS = {
        "TAG": "16-slim",
        "OPENPROJECT_HTTPS": "false",
        "OPENPROJECT_HOST__NAME": "localhost:8080",
        "PORT": "8080",
        "OPENPROJECT_RAILS__RELATIVE__URL__ROOT": "",
        "IMAP_ENABLED": "false",
        "DATABASE_URL": (
            "postgres://postgres:p4ssw0rd@db/openproject?"
            "pool=20&encoding=unicode&reconnect=true"
        ),
        "RAILS_MIN_THREADS": "4",
        "RAILS_MAX_THREADS": "16",
        "PGDATA": "/var/lib/postgresql/data",
        "OPDATA": "/var/openproject/assets",
    }

    def __init__(
        self, env_file: Optional[Path] = None, cfg_file: Optional[Path] = None
    ):
        """
        Initialize configuration manager

        Args:
            env_file: Path to .env file (defaults to .env in current directory)
            cfg_file: Path to .cfg file (defaults to
                scripts/installation_scripts/interactive_config.cfg)
        """
        self.env_file = env_file or Path(".env")
        self.cfg_file = cfg_file or Path(
            "scripts/installation_scripts/interactive_config.cfg"
        )
        self.config: Dict[str, str] = {}
        self._load_config()

    def _load_config(self) -> None:
        """Load configuration from all sources"""
        # Load defaults first
        self.config = self.DEFAULTS.copy()

        # Load from .env file if it exists
        if self.env_file.exists():
            logger.info(f"Loading configuration from {self.env_file}")
            env_config = dotenv_values(self.env_file)
            self.config.update({k: v for k, v in env_config.items() if v is not None})

        # Load from .cfg file if it exists
        if self.cfg_file.exists():
            logger.info(f"Loading configuration from {self.cfg_file}")
            cfg_config = self._load_cfg_file(self.cfg_file)
            self.config.update(cfg_config)

        # Override with environment variables
        for key in self.config.keys():
            env_value = os.getenv(key)
            if env_value is not None:
                self.config[key] = env_value

    def _load_cfg_file(self, cfg_path: Path) -> Dict[str, str]:
        """
        Load configuration from .cfg file (bash-style key=value)

        Args:
            cfg_path: Path to .cfg file

        Returns:
            Dictionary of configuration values
        """
        config = {}
        with open(cfg_path, "r") as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if not line or line.startswith("#"):
                    continue
                # Parse key=value pairs
                if "=" in line:
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    config[key] = value
        return config

    def get(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """
        Get configuration value

        Args:
            key: Configuration key
            default: Default value if key not found

        Returns:
            Configuration value or default
        """
        return self.config.get(key, default)

    def set(self, key: str, value: str) -> None:
        """
        Set configuration value

        Args:
            key: Configuration key
            value: Configuration value
        """
        self.config[key] = value

    def validate(self) -> tuple[bool, List[str]]:
        """
        Validate configuration

        Returns:
            Tuple of (is_valid, list_of_missing_keys)
        """
        missing_keys = []
        for key in self.REQUIRED_KEYS:
            if not self.config.get(key):
                missing_keys.append(key)

        return len(missing_keys) == 0, missing_keys

    def save_env(self, path: Optional[Path] = None) -> None:
        """
        Save configuration to .env file

        Args:
            path: Path to save .env file (defaults to self.env_file)
        """
        env_path = path or self.env_file
        logger.info(f"Saving configuration to {env_path}")

        with open(env_path, "w") as f:
            f.write("##\n")
            f.write("# OpenProject Docker Compose Configuration\n")
            f.write("# Generated by openproject-deploy\n")
            f.write("##\n\n")

            for key, value in sorted(self.config.items()):
                f.write(f"{key}={value}\n")

    def save_cfg(self, path: Optional[Path] = None) -> None:
        """
        Save configuration to .cfg file

        Args:
            path: Path to save .cfg file (defaults to self.cfg_file)
        """
        cfg_path = path or self.cfg_file
        logger.info(f"Saving configuration to {cfg_path}")

        # Ensure directory exists
        cfg_path.parent.mkdir(parents=True, exist_ok=True)

        with open(cfg_path, "w") as f:
            f.write("# OpenProject Installation Configuration\n")
            f.write("# Generated by openproject-deploy\n\n")

            for key, value in sorted(self.config.items()):
                f.write(f'{key}="{value}"\n')

    def get_summary(self) -> str:
        """
        Get a formatted summary of current configuration

        Returns:
            Formatted configuration summary
        """
        lines = ["Configuration Summary:", "=" * 50]
        for key, value in sorted(self.config.items()):
            # Mask sensitive values
            display_value = value
            if any(sensitive in key.lower() for sensitive in ["password", "secret", "token"]):
                display_value = "***REDACTED***"
            lines.append(f"{key:40} = {display_value}")
        lines.append("=" * 50)
        return "\n".join(lines)
