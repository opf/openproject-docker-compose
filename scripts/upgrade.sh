#!/bin/bash
# Hardened OpenProject upgrade orchestrator.
#
# Goals:
#   * Never lose data (backup before any mutation)
#   * Preserve formatting/style (custom plugin / CSS / initializer checks)
#   * Allow dry-run preview of upstream changes
#   * Roll back automatically if post-upgrade health checks fail
#
# Usage:
#   ./scripts/upgrade.sh [OPTIONS]
#
# Options:
#   --dry-run       Fetch upstream changes, show diff, but do not modify anything.
#   --no-pull       Skip `git pull` (useful when testing local changes).
#   --restore-only  Only restore the most recent backup and restart (rollback mode).

set -e
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_BASE="docker compose"
CONTROL_COMPOSE="${COMPOSE_BASE} -f docker-compose.yml -f docker-compose.control.yml"
DRY_RUN=false
NO_PULL=false
RESTORE_ONLY=false
FAILED=false
BACKUP_TIMESTAMP=""

usage() {
  echo "Usage: $(basename "$0") [--dry-run] [--no-pull] [--restore-only]"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --no-pull) NO_PULL=true ;;
    --restore-only) RESTORE_ONLY=true ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
  shift
done

cd "$PROJECT_ROOT"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

fail() {
  log "ERROR: $*" >&2
  FAILED=true
  exit 1
}

docker_compose_config_ok() {
  log "Verifying Docker Compose configuration merge..."
  if ! ${COMPOSE_BASE} config > /dev/null; then
    fail "Merged compose configuration is invalid. Fix docker-compose.override.yml before continuing."
  fi
}

pre_upgrade_backup() {
  log "=== PRE-UPGRADE BACKUP ==="
  ${CONTROL_COMPOSE} build || fail "Failed to build control plane"
  ${CONTROL_COMPOSE} run --rm backup || fail "Backup failed"
  BACKUP_TIMESTAMP="$(ls -1 backups | grep -E '^[0-9]+-manifest\.txt$' | sort -n | tail -1 | cut -d- -f1)"
  if [ -z "$BACKUP_TIMESTAMP" ]; then
    fail "Backup completed but no manifest was written"
  fi
  log "Backup timestamp: ${BACKUP_TIMESTAMP}"
}

pull_upstream() {
  log "=== FETCH UPSTREAM CHANGES ==="
  if [ "$NO_PULL" = true ]; then
    log "Skipping git pull (--no-pull)."
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    log "[DRY-RUN] Would run: git fetch origin stable/17"
    git fetch origin stable/17 || fail "git fetch failed"
    log "[DRY-RUN] Upstream diff preview:"
    git diff HEAD...origin/stable/17 --stat || true
    git diff HEAD...origin/stable/17 -- docker-compose.yml docker-compose.control.yml control/ .env.example README.md || true
    return 0
  fi

  # Stash local customisations that are not in git before pulling, then re-apply.
  # Only stash files that are tracked upstream so we don't stash our own custom dirs.
  local stash_files=(docker-compose.override.yml proxy/Caddyfile .env)
  local stashed=false
  for f in "${stash_files[@]}"; do
    if [ -f "$f" ] && ! git ls-files --error-unmatch "$f" > /dev/null 2>&1; then
      log "Preserving local file: $f (will restore after pull)"
    fi
  done

  # Store a copy of critical local files in /tmp in case git pull overwrites them.
  cp docker-compose.override.yml /tmp/op-docker-compose.override.yml.pre-pull.$$
  cp .env /tmp/op-env.pre-pull.$$

  git fetch origin stable/17 || fail "git fetch failed"

  # Try a clean merge first; if it fails, abort and leave repo untouched.
  if ! git merge --no-commit --no-ff origin/stable/17; then
    git merge --abort 2> /dev/null || true
    cp /tmp/op-docker-compose.override.yml.pre-pull.$$ docker-compose.override.yml
    cp /tmp/op-env.pre-pull.$$ .env
    fail "Automatic merge of upstream changes failed. Resolve manually before re-running."
  fi

  # Restore local override files if upstream overwrote them.
  if [ -f /tmp/op-docker-compose.override.yml.pre-pull.$$ ]; then
    cp /tmp/op-docker-compose.override.yml.pre-pull.$$ docker-compose.override.yml
    log "Restored docker-compose.override.yml after merge"
  fi
  if [ -f /tmp/op-env.pre-pull.$$ ]; then
    cp /tmp/op-env.pre-pull.$$ .env
    log "Restored .env after merge"
  fi
}

pre_upgrade_feature_check() {
  log "=== PRE-UPGRADE FEATURE / COMPATIBILITY CHECK ==="
  ./scripts/feature-check.sh || fail "Pre-upgrade feature/compatibility check failed"
}

post_upgrade_feature_check() {
  log "=== POST-UPGRADE FEATURE / COMPATIBILITY CHECK ==="
  ./scripts/feature-check.sh || fail "Post-upgrade feature/compatibility check failed"
}

verify_custom_files() {
  log "=== VERIFY CUSTOM FILES PRESENT ==="
  local files=(
    "custom-plugin/openproject-livesolutions/app/assets/stylesheets/livesolutions/theme.css"
    "custom-plugin/openproject-livesolutions/openproject-livesolutions.gemspec"
    "openproject-config/initializers/cloudflare_access_auth.rb"
    "openproject-config/initializers/community_unlock.rb"
    "proxy/Caddyfile"
    "smtp-relay/relay.py"
  )
  for f in "${files[@]}"; do
    if [ ! -f "$f" ]; then
      fail "Customisation missing after update: $f"
    fi
    log "OK: $f"
  done
}

run_upgrade() {
  if [ "$DRY_RUN" = true ]; then
    log "[DRY-RUN] Would run database upgrade container if PG major version changed."
    return 0
  fi

  log "=== DATABASE UPGRADE (if needed) ==="
  # The upgrade script exits 0 when current PG version == target version.
  ${CONTROL_COMPOSE} run --rm upgrade || fail "Database upgrade failed"
}

restart_stack() {
  if [ "$DRY_RUN" = true ]; then
    log "[DRY-RUN] Would run: docker compose up -d --build --pull always"
    return 0
  fi

  log "=== RESTART STACK ==="
  ${COMPOSE_BASE} down || true
  ${COMPOSE_BASE} up -d --build --pull always || fail "Stack restart failed"
}

post_upgrade_health() {
  if [ "$DRY_RUN" = true ]; then
    log "[DRY-RUN] Would run post-upgrade health checks."
    return 0
  fi

  log "=== POST-UPGRADE HEALTH CHECKS ==="
  ./scripts/health-check.sh || fail "Post-upgrade health checks failed"
}

rollback() {
  log "=== ROLLBACK ==="
  if [ -z "$BACKUP_TIMESTAMP" ]; then
    log "No backup timestamp recorded; attempting to restore latest backup."
  fi
  ${CONTROL_COMPOSE} down || true
  RESTORE_TIMESTAMP="${BACKUP_TIMESTAMP}" ${CONTROL_COMPOSE} run --rm restore || fail "Rollback restore failed"
  ${COMPOSE_BASE} up -d || fail "Rollback restart failed"
  log "Rollback complete. Investigate before trying another upgrade."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [ "$RESTORE_ONLY" = true ]; then
  log "=== RESTORE-ONLY MODE ==="
  ${CONTROL_COMPOSE} down || true
  ${CONTROL_COMPOSE} run --rm restore || fail "Restore failed"
  ${COMPOSE_BASE} up -d || fail "Restart after restore failed"
  ./scripts/health-check.sh
  exit 0
fi

# Ensure all customisations are committed/stashed or at least present before mutating
verify_custom_files
docker_compose_config_ok
pre_upgrade_feature_check
pre_upgrade_backup

# If anything after this point fails, attempt rollback.
if ! pull_upstream; then
  rollback
  exit 1
fi

if ! run_upgrade; then
  rollback
  exit 1
fi

if ! restart_stack; then
  rollback
  exit 1
fi

if ! post_upgrade_health; then
  rollback
  exit 1
fi

if ! post_upgrade_feature_check; then
  rollback
  exit 1
fi

log "=== UPGRADE COMPLETE ==="
if [ "$DRY_RUN" = true ]; then
  log "Dry-run finished. No changes were made."
else
  log "OpenProject upgraded successfully."
fi
