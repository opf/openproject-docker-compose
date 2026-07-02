#!/bin/bash
# OpenProject offline backup entrypoint.
# Creates a point-in-time physical backup of the PostgreSQL data directory and
# OpenProject assets. This is intended to run when the stack is DOWN, via the
# control compose file.
#
# For a live logical SQL dump (more portable across Postgres major versions),
# use scripts/backup-logical.sh while the stack is up.

set -e
set -o pipefail

timestamp=$(date +%s)
mkdir -p /backups
cd /backups

# ---------------------------------------------------------------------------
# 1. Physical PostgreSQL data tarball
# ---------------------------------------------------------------------------
pgdata_file="${timestamp}-pgdata.tar.gz"
echo "Creating physical PostgreSQL data backup: backups/${pgdata_file} ..."
tar czf "${pgdata_file}" -C "$PGDATA" .
echo "Physical backup complete: backups/${pgdata_file}"

# ---------------------------------------------------------------------------
# 2. OpenProject assets tarball
# ---------------------------------------------------------------------------
opdata_file="${timestamp}-opdata.tar.gz"
echo "Creating OpenProject assets backup: backups/${opdata_file} ..."
tar czf "${opdata_file}" -C "$OPDATA" .
echo "Assets backup complete: backups/${opdata_file}"

# ---------------------------------------------------------------------------
# 3. Configuration / customization manifest
# ---------------------------------------------------------------------------
manifest_file="${timestamp}-manifest.txt"
echo "Writing backup manifest: backups/${manifest_file} ..."
{
  echo "backup_timestamp=${timestamp}"
  echo "backup_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "postgres_version=$(cat "$PGDATA/PG_VERSION" 2>/dev/null || echo unknown)"
  echo "opdata_size=$(du -sb "$OPDATA" | cut -f1)"
  echo "pgdata_size=$(du -sb "$PGDATA" | cut -f1)"
  echo "pgdata_file=${pgdata_file}"
  echo "opdata_file=${opdata_file}"
  echo "custom_plugin_commit=$(git -C /control rev-parse --short HEAD 2>/dev/null || echo n/a)"
} > "${manifest_file}"

echo "DONE: backups/${manifest_file}"
ls -lh /backups/${timestamp}-*
