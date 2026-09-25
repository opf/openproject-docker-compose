#!/bin/bash
# Live logical PostgreSQL backup.
# Runs pg_dumpall against the running db container so it can be restored into a
# different Postgres major version. This does NOT replace the offline physical
# backup used by the upgrade orchestrator; it is an additional safety net.
#
# Usage:
#   ./scripts/backup-logical.sh

set -e
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

mkdir -p backups
timestamp=$(date +%s)
file="backups/${timestamp}-openproject.sql.gz"

# If the backups directory is root-owned from previous control-plane runs, fall
# back to /tmp/opencode/ so the script still succeeds for the current user.
if [ ! -w "backups" ]; then
  echo "WARN: backups/ is not writable by $(id -un); writing to /tmp/opencode/ instead." >&2
  mkdir -p /tmp/opencode
  file="/tmp/opencode/${timestamp}-openproject.sql.gz"
fi

echo "Creating logical backup: ${file} ..."
docker compose exec -T db pg_dumpall -U postgres --clean --if-exists | gzip > "${file}"
echo "Logical backup complete: ${file}"
ls -lh "${file}"
