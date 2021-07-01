#!/bin/bash
set -e

timestamp=$(date +%s)
mkdir -p /backups
cd /backups
filename="${timestamp}-pgdata.tar.gz"
echo "Backing up PostgreSQL data into backups/${filename}..."
tar czf "${filename}" -C "$PGDATA" .
filename="${timestamp}-opdata.tar.gz"
echo "Backing up OpenProject assets into backups/${filename}..."
tar czf "${filename}" -C "$OPDATA" .
echo "DONE"
