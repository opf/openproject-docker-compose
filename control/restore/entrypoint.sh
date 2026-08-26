#!/bin/bash
# OpenProject restore entrypoint.
# Restores a previous backup set into the live PGDATA and OPDATA paths.
# Use this only when the stack is DOWN.
#
# Usage:
#   docker compose -f docker-compose.yml -f docker-compose.control.yml \
#     run --rm -e RESTORE_TIMESTAMP=1782964243 restore
#
# If RESTORE_TIMESTAMP is omitted, the most recent backup set is used.

set -e
set -o pipefail

BACKUP_DIR=/backups

timestamp="${RESTORE_TIMESTAMP:-}"
if [ -z "$timestamp" ]; then
  timestamp="$(ls -1 "$BACKUP_DIR" | grep -E '^[0-9]+-manifest\.txt$' | sort -n | tail -1 | cut -d- -f1)"
fi

if [ -z "$timestamp" ]; then
  echo "ERROR: no backup manifest found in $BACKUP_DIR" >&2
  exit 1
fi

echo "Restoring backup set: ${timestamp}"

# ---------------------------------------------------------------------------
# 1. Restore OpenProject assets
# ---------------------------------------------------------------------------
opdata_file="${BACKUP_DIR}/${timestamp}-opdata.tar.gz"
if [ -f "$opdata_file" ]; then
  echo "Restoring assets from ${opdata_file} ..."
  mkdir -p "$OPDATA"
  rm -rf "${OPDATA:?}"/*
  tar xzf "$opdata_file" -C "$OPDATA"
  echo "Assets restored."
else
  echo "WARNING: ${opdata_file} not found; skipping asset restore." >&2
fi

# ---------------------------------------------------------------------------
# 2. Restore PostgreSQL physical data
# ---------------------------------------------------------------------------
pgdata_file="${BACKUP_DIR}/${timestamp}-pgdata.tar.gz"
if [ -f "$pgdata_file" ]; then
  echo "Restoring PostgreSQL data from ${pgdata_file} ..."
  rm -rf "${PGDATA:?}"/*
  tar xzf "$pgdata_file" -C "$PGDATA"
  chown -R postgres:postgres "$PGDATA"
  echo "PostgreSQL data restored."
else
  echo "WARNING: ${pgdata_file} not found; skipping PG physical restore." >&2
fi

# ---------------------------------------------------------------------------
# 3. Re-apply container network ACLs (in case an old cluster lacked them)
# ---------------------------------------------------------------------------
if [ -d "$PGDATA" ] && [ -f "$PGDATA/postgresql.conf" ]; then
  if ! grep -q "listen_addresses = '\*'" "$PGDATA/postgresql.conf"; then
    echo "Ensuring listen_addresses='*' is set..."
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
  fi
  if ! grep -q "host all all all md5" "$PGDATA/pg_hba.conf"; then
    echo "Ensuring host all all all md5 is set..."
    echo "host all all all md5" >> "$PGDATA/pg_hba.conf"
  fi
fi

echo "DONE: restore complete for timestamp ${timestamp}."
echo "Start the stack with: docker compose up -d --build --pull always"
