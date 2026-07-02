#!/bin/bash
# PostgreSQL major-version upgrade script for the OpenProject control plane.
# Uses pg_upgrade when the running (old) Postgres major version is lower than
# the target version supplied by the container image.
#
# IMPORTANT: This script is meant to be run via the `upgrade` service defined in
# docker-compose.control.yml. The stack must be DOWN before running it, because
# it rewrites the contents of the PGDATA volume.

set -e
set -o pipefail

CURRENT_PGVERSION="$(cat "$PGDATA/PG_VERSION")"
# Use the major version of the postgres binaries baked into this image.
NEW_PGVERSION="$(pg_ctl --version | sed -E 's/.* ([0-9]+).*/\1/')"
PGWORKDIR=${PGWORKDIR:=/var/lib/postgresql/work}

echo "Detected current PGDATA version: ${CURRENT_PGVERSION}"
echo "Control-plane image PG version:  ${NEW_PGVERSION}"

if [ ! "$CURRENT_PGVERSION" -lt "$NEW_PGVERSION" ]; then
	echo "Current PG version is already >= target version (${CURRENT_PGVERSION} >= ${NEW_PGVERSION}). Nothing to do."
	exit 0
fi

export PGBINOLD="/usr/lib/postgresql/$CURRENT_PGVERSION/bin"
export PGBINNEW="/usr/lib/postgresql/$NEW_PGVERSION/bin"
export PGDATAOLD="$PGDATA"
export PGDATANEW="$PGWORKDIR/datanew"

if [ ! -d "$PGBINOLD" ] || [ ! -x "$PGBINOLD/pg_ctl" ]; then
  echo "ERROR: old cluster binaries not found at $PGBINOLD" >&2
  echo "The control image only contains PG ${NEW_PGVERSION}. You must build or use an image that also ships PG ${CURRENT_PGVERSION} binaries." >&2
  exit 1
fi

rm -rf "$PGWORKDIR" && mkdir -p "$PGWORKDIR" "$PGDATANEW"
chown -R postgres:postgres "$PGDATA" "$PGWORKDIR"
cd "$PGWORKDIR"

# initialize new db cluster
echo "Initializing new PostgreSQL ${NEW_PGVERSION} cluster..."
su -m postgres -c "$PGBINNEW/initdb --pgdata=$PGDATANEW --encoding=unicode --auth=trust"

echo "Performing a dry-run migration to PostgreSQL ${NEW_PGVERSION}..."
su -m postgres -c "$PGBINNEW/pg_upgrade --old-datadir=$PGDATAOLD --new-datadir=$PGDATANEW --old-bindir=$PGBINOLD --new-bindir=$PGBINNEW -c"

echo "Performing the real migration to PostgreSQL ${NEW_PGVERSION}..."
su -m postgres -c "$PGBINNEW/pg_upgrade --old-datadir=$PGDATAOLD --new-datadir=$PGDATANEW --old-bindir=$PGBINOLD --new-bindir=$PGBINNEW"

echo "Replacing old cluster data with upgraded cluster..."
su -m postgres -c "rm -rf $PGDATAOLD/* && mv $PGDATANEW/* $PGDATAOLD/"

# as per docker hub documentation, ensure remote container access still works
su -m postgres -c "echo \"listen_addresses = '*'\" >> $PGDATAOLD/postgresql.conf"
su -m postgres -c "echo \"host all all all md5\" >> $PGDATAOLD/pg_hba.conf"

echo "DONE"
