"""
CLI Interface for OpenProject deployment utilities
"""

import click
import logging
from pathlib import Path
from rich.console import Console
from rich.table import Table
from openproject_deploy.config_manager import ConfigManager

console = Console()


def setup_logging(verbose: bool = False) -> None:
    """Configure logging"""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=level, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")


@click.group()
@click.option("--verbose", "-v", is_flag=True, help="Enable verbose logging")
@click.pass_context
def main(ctx: click.Context, verbose: bool) -> None:
    """OpenProject Docker Compose deployment utilities"""
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose
    setup_logging(verbose)


@main.command()
@click.option("--env-file", "-e", type=click.Path(exists=True), help="Path to .env file")
@click.option("--cfg-file", "-c", type=click.Path(exists=True), help="Path to .cfg file")
@click.pass_context
def config(ctx: click.Context, env_file: str, cfg_file: str) -> None:
    """Display current configuration"""
    env_path = Path(env_file) if env_file else None
    cfg_path = Path(cfg_file) if cfg_file else None

    config_mgr = ConfigManager(env_file=env_path, cfg_file=cfg_path)

    # Display configuration in a table
    table = Table(title="OpenProject Configuration")
    table.add_column("Key", style="cyan", no_wrap=True)
    table.add_column("Value", style="green")

    for key, value in sorted(config_mgr.config.items()):
        # Mask sensitive values
        display_value = value
        if any(sensitive in key.lower() for sensitive in ["password", "secret", "token"]):
            display_value = "***REDACTED***"
        table.add_row(key, display_value)

    console.print(table)

    # Validate configuration
    is_valid, missing_keys = config_mgr.validate()
    if is_valid:
        console.print("\n[green]✓[/green] Configuration is valid")
    else:
        console.print("\n[red]✗[/red] Configuration is missing required keys:")
        for key in missing_keys:
            console.print(f"  [red]•[/red] {key}")


@main.command()
@click.option("--env-file", "-e", type=click.Path(), help="Path to .env file")
@click.option("--cfg-file", "-c", type=click.Path(), help="Path to .cfg file")
@click.option("--key", "-k", required=True, help="Configuration key")
@click.option("--value", "-V", required=True, help="Configuration value")
@click.pass_context
def set_config(ctx: click.Context, env_file: str, cfg_file: str, key: str, value: str) -> None:
    """Set a configuration value"""
    env_path = Path(env_file) if env_file else None
    cfg_path = Path(cfg_file) if cfg_file else None

    config_mgr = ConfigManager(env_file=env_path, cfg_file=cfg_path)
    config_mgr.set(key, value)

    # Save to both .env and .cfg
    config_mgr.save_env()
    config_mgr.save_cfg()

    console.print(f"[green]✓[/green] Set {key} = {value}")
    console.print(f"[green]✓[/green] Saved to {config_mgr.env_file} and {config_mgr.cfg_file}")


@main.command()
@click.option("--env-file", "-e", type=click.Path(), help="Path to output .env file")
@click.pass_context
def init_config(ctx: click.Context, env_file: str) -> None:
    """Initialize configuration with defaults"""
    env_path = Path(env_file) if env_file else Path(".env")

    config_mgr = ConfigManager(env_file=None, cfg_file=None)
    config_mgr.save_env(env_path)

    console.print(f"[green]✓[/green] Initialized configuration at {env_path}")
    console.print("\nNext steps:")
    console.print("  1. Edit the .env file with your settings")
    console.print("  2. Run 'openproject validate' to check your configuration")
    console.print("  3. Run 'openproject deploy' to start OpenProject")


@main.command()
@click.option("--env-file", "-e", type=click.Path(exists=True), help="Path to .env file")
@click.option("--cfg-file", "-c", type=click.Path(exists=True), help="Path to .cfg file")
@click.pass_context
def validate(ctx: click.Context, env_file: str, cfg_file: str) -> None:
    """Validate configuration"""
    env_path = Path(env_file) if env_file else None
    cfg_path = Path(cfg_file) if cfg_file else None

    config_mgr = ConfigManager(env_file=env_path, cfg_file=cfg_path)
    is_valid, missing_keys = config_mgr.validate()

    if is_valid:
        console.print("[green]✓[/green] Configuration is valid")
        exit(0)
    else:
        console.print("[red]✗[/red] Configuration is invalid")
        console.print("\nMissing required keys:")
        for key in missing_keys:
            console.print(f"  [red]•[/red] {key}")
        exit(1)


@main.command()
def version() -> None:
    """Display version information"""
    from openproject_deploy import __version__

    console.print(f"openproject-deploy version {__version__}")


if __name__ == "__main__":
    main()
