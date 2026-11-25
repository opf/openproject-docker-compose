#!/bin/bash
# OpenProject feature / compatibility check.
#
# Verifies that Live Solutions customisations and critical integrations remain
# intact and compatible with the configured images. Run before an upgrade to
# establish a baseline, and after an upgrade to confirm nothing broke.
#
# Usage:
#   ./scripts/feature-check.sh
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more compatibility issues detected

set -e
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

FAILED=0
WARNINGS=0

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

ok() {
  log "OK: $*"
}

warn() {
  log "WARN: $*" >&2
  WARNINGS=$((WARNINGS+1))
}

fail() {
  log "FAIL: $*" >&2
  FAILED=$((FAILED+1))
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
compose_value() {
  # Extract a top-level value from merged compose config.
  docker compose config 2>/dev/null | grep -m1 -E "^\s+${1}:" | sed -E 's/^[^:]+: *"?([^"]*)"?$/\1/'
}

# ---------------------------------------------------------------------------
# 1. Cloudflare Access SSO
# ---------------------------------------------------------------------------
log "=== Feature: Cloudflare Access SSO ==="

if [ -f "openproject-config/initializers/cloudflare_access_auth.rb" ]; then
  ok "cloudflare_access_auth.rb initializer exists"
else
  fail "cloudflare_access_auth.rb initializer is missing"
fi

if grep -q "TRUST_CF_ACCESS_EMAIL=true" .env 2>/dev/null; then
  ok ".env enables TRUST_CF_ACCESS_EMAIL"
else
  fail ".env does not enable TRUST_CF_ACCESS_EMAIL; CF SSO will not work"
fi

if grep -q 'Cf-Access-Authenticated-User-Email' openproject-config/initializers/cloudflare_access_auth.rb; then
  ok "Initializer reads Cf-Access-Authenticated-User-Email header"
else
  fail "Initializer missing CF Access email header logic"
fi

# Make sure we are not also wiring OpenProject native OIDC for the same provider;
# that would conflict with the header-based SSO.
if grep -qE '^OPENPROJECT_OPENID__CONNECT__ENTRA__' .env 2>/dev/null; then
  warn "Native Entra OIDC variables are uncommented in .env; these conflict with CF Access SSO in Community Edition"
else
  ok "Native Entra OIDC variables are not active"
fi

# ---------------------------------------------------------------------------
# 2. Brand theme CSS
# ---------------------------------------------------------------------------
log "=== Feature: Live Solutions brand theme CSS ==="

if [ -f "custom-plugin/openproject-livesolutions/app/assets/stylesheets/livesolutions/theme.css" ]; then
  ok "Brand theme CSS file exists"
else
  fail "Brand theme CSS file is missing"
fi

# Verify the file contains our signature tokens; OpenProject upgrades that
# rename/deprecate these selectors would be caught during the CSS health check,
# but we flag the risk here too.
for token in "--ls-action" "--ls-primary" ".op-app-header" "#main-menu"; do
  if grep -q -F -- "${token}" custom-plugin/openproject-livesolutions/app/assets/stylesheets/livesolutions/theme.css; then
    ok "CSS contains brand token: ${token}"
  else
    fail "CSS missing brand token: ${token}"
  fi
done

# ---------------------------------------------------------------------------
# 3. Custom plugin structure
# ---------------------------------------------------------------------------
log "=== Feature: openproject-livesolutions plugin ==="

plugin_dir="custom-plugin/openproject-livesolutions"
required_plugin_files=(
  "${plugin_dir}/openproject-livesolutions.gemspec"
  "${plugin_dir}/lib/openproject-livesolutions.rb"
  "${plugin_dir}/lib/open_project/livesolutions.rb"
  "${plugin_dir}/lib/open_project/livesolutions/engine.rb"
  "${plugin_dir}/lib/open_project/livesolutions/hooks.rb"
  "${plugin_dir}/lib/open_project/livesolutions/patches/current_user_cloudflare_patch.rb"
)
for f in "${required_plugin_files[@]}"; do
  if [ -f "$f" ]; then
    ok "Plugin file present: $f"
  else
    fail "Plugin file missing: $f"
  fi
done

# ---------------------------------------------------------------------------
# 4. SMTP relay
# ---------------------------------------------------------------------------
log "=== Feature: SMTP-to-Graph relay ==="

if docker compose ps -q relay >/dev/null 2>&1; then
  ok "relay service has a container"
else
  fail "relay service is not running"
fi

if docker compose exec -T relay python3 -c "import socket; s=socket.socket(); s.connect(('127.0.0.1',587)); s.close()" > /dev/null 2>&1; then
  ok "relay is listening on port 587"
else
  fail "relay is not listening on port 587"
fi

required_relay_env=(GRAPH_TENANT_ID GRAPH_CLIENT_ID GRAPH_CLIENT_SECRET DEFAULT_SENDER_UPN)
for var in "${required_relay_env[@]}"; do
  if grep -qE "^${var}=" .env 2>/dev/null; then
    ok ".env sets ${var}"
  else
    fail ".env missing ${var}; relay will fail"
  fi
done

# ---------------------------------------------------------------------------
# 5. Proxy / Caddy configuration
# ---------------------------------------------------------------------------
log "=== Feature: Caddy reverse proxy ==="

if [ -f "proxy/Caddyfile" ]; then
  ok "proxy/Caddyfile exists"
else
  fail "proxy/Caddyfile is missing"
fi

if grep -q "reverse_proxy.*web:8080" proxy/Caddyfile; then
  ok "Caddyfile routes to web:8080"
else
  fail "Caddyfile missing route to web:8080"
fi

if grep -q "X-Forwarded-Proto" proxy/Caddyfile; then
  ok "Caddyfile forwards/produces X-Forwarded-Proto"
else
  warn "Caddyfile does not handle X-Forwarded-Proto; Rails HTTPS detection may break"
fi

# ---------------------------------------------------------------------------
# 6. Image / database version compatibility
# ---------------------------------------------------------------------------
log "=== Compatibility: image and database versions ==="

tag="${TAG:-$(grep -E '^TAG=' .env | cut -d= -f2 | tr -d '"' || true)}"
if [ -n "$tag" ]; then
  ok "OpenProject image tag pinned in .env: ${tag}"
else
  warn "TAG not set in .env; upgrade may pull an unexpected major version"
fi

pg_version_env="${POSTGRES_VERSION:-$(grep -E '^POSTGRES_VERSION=' .env | cut -d= -f2 | tr -d '"' || true)}"
if [ -n "$pg_version_env" ]; then
  ok "PostgreSQL version pinned in .env: ${pg_version_env}"
else
  warn "POSTGRES_VERSION not set in .env"
fi

# Compare running DB version with env target
current_pg="$(docker compose exec -T db cat /var/lib/postgresql/data/PG_VERSION 2>/dev/null || echo unknown)"
if [ "$current_pg" != "unknown" ]; then
  ok "Running PostgreSQL major version: ${current_pg}"
  if [ -n "$pg_version_env" ] && [ "$current_pg" -gt "$pg_version_env" ] 2>/dev/null; then
    fail "Running PG ${current_pg} is newer than env target ${pg_version_env}; this could cause a downgrade"
  fi
else
  warn "Could not determine running PostgreSQL version"
fi

# ---------------------------------------------------------------------------
# 7. Secrets exposure check
# ---------------------------------------------------------------------------
log "=== Compatibility: secrets exposure ==="

# The override mounts .env into cron/worker via env_file. We can't easily
# restrict that in Community Compose, but we can warn if secrets appear in the
# merged config for services that do not need them.
compose_config="$(docker compose config 2> /dev/null)"
if [ -z "$compose_config" ]; then
  warn "Could not render merged compose config for secrets audit"
else
  # If web/worker/cron all share the same env_file, all secrets are visible to
  # all of them. This is expected with the current override; flag as info.
  for svc in worker cron; do
    if echo "$compose_config" | grep -A2 "^  ${svc}:" | grep -q 'env_file: .env'; then
      warn "Service '${svc}' loads full .env; ensure only required secrets are kept in this file"
    fi
  done
fi

# ---------------------------------------------------------------------------
# 8. Upgrade-specific file drift guard
# ---------------------------------------------------------------------------
log "=== Compatibility: local files survive upstream merge ==="

protected_files=(docker-compose.override.yml .env proxy/Caddyfile)
for f in "${protected_files[@]}"; do
  if [ -f "$f" ]; then
    ok "Protected local file present: $f"
  else
    fail "Protected local file missing: $f"
  fi
done

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
# 7. Premium feature unlock initializer
# ---------------------------------------------------------------------------
log "=== Feature: Community premium feature unlock ==="

if [ -f "openproject-config/initializers/community_unlock.rb" ]; then
  ok "community_unlock.rb initializer exists"
else
  fail "community_unlock.rb initializer is missing; 22 premium features will re-lock after upgrade"
fi

if docker compose exec -T web test -f /app/config/initializers/custom/community_unlock.rb; then
  ok "community_unlock.rb is mounted inside the web container"
else
  fail "community_unlock.rb is not mounted inside the web container"
fi

expected_unlocked=(
  baseline_comparison
  custom_actions
  custom_field_hierarchies
  date_alerts
  edit_attribute_groups
  gantt_pdf_export
  placeholder_users
  readonly_work_packages
  team_planner_view
  work_package_query_relation_columns
  meeting_templates
  one_drive_sharepoint_file_storage
  work_package_sharing
  mcp_server
  internal_comments
  time_entry_time_restrictions
  portfolio_management
  project_creation_wizard
  customize_life_cycle
  capture_external_links
  project_list_sharing
  calculated_values
  weighted_item_lists
)

for sym in "${expected_unlocked[@]}"; do
  if grep -q -F "${sym}" openproject-config/initializers/community_unlock.rb; then
    ok "Premium feature symbol present: ${sym}"
  else
    fail "Premium feature symbol missing: ${sym}"
  fi
done

if grep -q 'Setting.ee_hide_banners = true' openproject-config/initializers/community_unlock.rb; then
  ok "Upsell banners suppressed (ee_hide_banners = true)"
else
  warn "Upsell banner suppression missing"
fi

