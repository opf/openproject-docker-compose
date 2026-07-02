#!/bin/bash
# OpenProject post-upgrade / periodic health checks.
# Verifies that data, formatting, style, and core integrations survive an upgrade.
#
# Usage:
#   ./scripts/health-check.sh

set -e
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

PUBLIC_URL="${OPENPROJECT_BASE_URL:-https://projects.livesolutionsnow.com}"
INTERNAL_PROXY="http://proxy:80"
FAILED=0

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

warn() {
  log "WARN: $*" >&2
  FAILED=$((FAILED+1))
}

fail() {
  log "FAIL: $*" >&2
  FAILED=$((FAILED+1))
}

# ---------------------------------------------------------------------------
# 1. Container health
# ---------------------------------------------------------------------------
log "Checking required containers are running/healthy..."
required_services=(db web worker cron proxy relay hocuspocus)
for svc in "${required_services[@]}"; do
  container="$(docker compose ps -q "${svc}" 2>/dev/null || true)"
  if [ -z "$container" ]; then
    fail "Service ${svc} has no running container"
  else
    log "OK: ${svc} is running"
  fi
done

# ---------------------------------------------------------------------------
# 2. Database connectivity and basic integrity
# ---------------------------------------------------------------------------
log "Checking database connectivity..."
if docker compose exec -T db pg_isready -U postgres -d openproject > /dev/null 2>&1; then
  log "OK: PostgreSQL is ready"
else
  fail "PostgreSQL is not ready"
fi

log "Checking database row counts..."
user_count="$(docker compose exec -T db psql -U postgres -d openproject -At -c 'SELECT COUNT(*) FROM users;' 2>/dev/null || echo -1)"
if [ "$user_count" -ge 0 ] 2>/dev/null; then
  log "OK: users table readable (count=${user_count})"
else
  fail "Could not read users table"
fi

# ---------------------------------------------------------------------------
# 3. Web health endpoint
# ---------------------------------------------------------------------------
log "Checking OpenProject health endpoint..."
for i in $(seq 1 30); do
  if docker compose exec -T web curl -fsS -H 'Host: projects.livesolutionsnow.com' -H 'X-Forwarded-Proto: https' http://localhost:8080/health_checks/default > /dev/null 2>&1; then
    log "OK: OpenProject health endpoint returns success"
    break
  fi
  if [ "$i" -eq 30 ]; then
    fail "OpenProject health endpoint failed after 30 attempts"
  fi
  sleep 2
done

# ---------------------------------------------------------------------------
# 4. Brand theme CSS is reachable
# ---------------------------------------------------------------------------
log "Checking brand theme CSS is served..."
for i in $(seq 1 30); do
  if docker compose exec -T web curl -fsS -H 'Host: projects.livesolutionsnow.com' -H 'X-Forwarded-Proto: https' "http://localhost:8080/stylesheets/livesolutions-theme.css" > /dev/null 2>&1; then
    log "OK: livesolutions-theme.css is reachable"
    break
  fi
  if [ "$i" -eq 30 ]; then
    fail "livesolutions-theme.css is not reachable (brand formatting may be broken)"
  fi
  sleep 2
done

# ---------------------------------------------------------------------------
# 5. Custom plugin path mounted
# ---------------------------------------------------------------------------
log "Checking custom plugin mount..."
if docker compose exec -T web test -d /usr/src/app/plugins/openproject-livesolutions; then
  log "OK: openproject-livesolutions plugin directory mounted"
else
  fail "openproject-livesolutions plugin directory missing"
fi

# ---------------------------------------------------------------------------
# 6. Cloudflare Access initializer present
# ---------------------------------------------------------------------------
log "Checking Cloudflare Access initializer..."
if docker compose exec -T web test -f /app/config/initializers/custom/cloudflare_access_auth.rb; then
  log "OK: cloudflare_access_auth.rb initializer present"
else
  fail "cloudflare_access_auth.rb initializer missing (SSO will break)"
fi

# ---------------------------------------------------------------------------
# 7. Premium feature unlock initializer mounted
# ---------------------------------------------------------------------------
log "Checking premium feature unlock initializer..."
if docker compose exec -T web test -f /app/config/initializers/custom/community_unlock.rb; then
  log "OK: community_unlock.rb initializer present (premium features remain unlocked)"
else
  fail "community_unlock.rb initializer missing; premium features will re-lock"
fi

# ---------------------------------------------------------------------------
# 7. Public site returns 200 and contains login form
# ---------------------------------------------------------------------------
log "Checking public login page via Cloudflare Tunnel..."
if curl -fsS -L --max-time 30 "${PUBLIC_URL}/login" > /dev/null 2>&1; then
  log "OK: public URL ${PUBLIC_URL}/login reachable"
else
  warn "Public URL ${PUBLIC_URL}/login not reachable (may be expected from this host)"
fi

# ---------------------------------------------------------------------------
# 8. Asset directory writable and not empty (after real use)
# ---------------------------------------------------------------------------
log "Checking asset directory..."
asset_size="$(docker compose exec -T web du -sb /var/openproject/assets 2>/dev/null | cut -f1 || echo -1)"
if [ "$asset_size" -ge 0 ] 2>/dev/null; then
  log "OK: asset directory accessible (size=${asset_size} bytes)"
else
  warn "Could not determine asset directory size"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAILED" -eq 0 ]; then
  log "HEALTH CHECK PASSED"
  exit 0
else
  log "HEALTH CHECK FAILED: ${FAILED} issue(s) detected"
  exit 1
fi
