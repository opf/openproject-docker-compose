"""
Tests for ConfigManager
"""

from pathlib import Path
from openproject_deploy.config_manager import ConfigManager


def test_config_manager_defaults():
    """Test that ConfigManager loads defaults"""
    config = ConfigManager(env_file=Path("/nonexistent/.env"), cfg_file=Path("/nonexistent/.cfg"))

    assert config.get("TAG") == "16-slim"
    assert config.get("OPENPROJECT_HTTPS") == "false"
    assert config.get("PORT") == "8080"


def test_config_manager_get_set():
    """Test getting and setting config values"""
    config = ConfigManager(env_file=Path("/nonexistent/.env"), cfg_file=Path("/nonexistent/.cfg"))

    config.set("TEST_KEY", "test_value")
    assert config.get("TEST_KEY") == "test_value"
    assert config.get("NONEXISTENT_KEY") is None
    assert config.get("NONEXISTENT_KEY", "default") == "default"


def test_config_validation():
    """Test configuration validation"""
    config = ConfigManager(env_file=Path("/nonexistent/.env"), cfg_file=Path("/nonexistent/.cfg"))

    # Should be invalid initially (missing required keys)
    is_valid, missing = config.validate()
    assert not is_valid
    assert "OPENPROJECT_TAG" in missing

    # Set required keys
    config.set("OPENPROJECT_HOST__NAME", "example.com")
    config.set("DOMAIN_NAME", "example.com")
    config.set("OPENPROJECT_HTTPS", "true")
    config.set("OPENPROJECT_TAG", "16-slim")

    # Should be valid now
    is_valid, missing = config.validate()
    assert is_valid
    assert len(missing) == 0


def test_config_summary():
    """Test configuration summary generation"""
    config = ConfigManager(env_file=Path("/nonexistent/.env"), cfg_file=Path("/nonexistent/.cfg"))

    summary = config.get_summary()
    assert "Configuration Summary" in summary
    assert "TAG" in summary


def test_save_and_load_env(tmp_path):
    """Test saving and loading .env file"""
    env_file = tmp_path / ".env"

    # Create and save config
    config1 = ConfigManager(env_file=env_file, cfg_file=Path("/nonexistent/.cfg"))
    config1.set("TEST_KEY", "test_value")
    config1.save_env()

    # Load config from saved file
    config2 = ConfigManager(env_file=env_file, cfg_file=Path("/nonexistent/.cfg"))
    assert config2.get("TEST_KEY") == "test_value"


def test_save_and_load_cfg(tmp_path):
    """Test saving and loading .cfg file"""
    cfg_file = tmp_path / "test.cfg"

    # Create and save config
    config1 = ConfigManager(env_file=Path("/nonexistent/.env"), cfg_file=cfg_file)
    config1.set("TEST_KEY", "test_value")
    config1.save_cfg()

    # Load config from saved file
    config2 = ConfigManager(env_file=Path("/nonexistent/.env"), cfg_file=cfg_file)
    assert config2.get("TEST_KEY") == "test_value"
