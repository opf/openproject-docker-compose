#!/bin/bash
set -e
set -o pipefail

CURRENT_PGVERSION="$(cat $PGDATA/PG_VERSION)"
NEW_PGVERSION="13"
PGWORKDIR=${PGWORKDIR:=/var/lib/postgresql/work}

if [ ! "$CURRENT_PGVERSION" -lt "$NEW_PGVERSION" ]; then
	echo "Current PG version is higher or equal to the PG version to be installed ($CURRENT_PGVERSION > $NEW_PGVERSION). Ignoring."
	exit 0
fi

export PGBINOLD="/usr/lib/postgresql/$CURRENT_PGVERSION/bin"
export PGBINNEW="/usr/lib/postgresql/$NEW_PGVERSION/bin"
export PGDATAOLD="$PGDATA"
export PGDATANEW="$PGWORKDIR/datanew"

rm -rf "$PGWORKDIR" && mkdir -p "$PGWORKDIR" "$PGDATANEW"
chown -R postgres.postgres "$PGDATA" "$PGWORKDIR"
cd "$PGWORKDIR"
# initialize new db
su -m postgres -c "$PGBINNEW/initdb --pgdata=$PGDATANEW --encoding=unicode --auth=trust"
echo "Performing a dry-run migration to PostgreSQL $NEW_PGVERSION..."
su -m postgres -c "$PGBINNEW/pg_upgrade -c"
echo "Performing the real migration to PostgreSQL $NEW_VERSION..."
su -m postgres -c "$PGBINNEW/pg_upgrade"
su -m postgres -c "rm -rf $PGDATAOLD/* && mv $PGDATANEW/* $PGDATAOLD/"
# as per docker hub documentation
su -m postgres -c "echo \"listen_addresses = '*'\" >> $PGDATAOLD/postgresql.conf"
su -m postgres -c "echo \"host all all all md5\" >> $PGDATAOLD/pg_hba.conf"
echo "DONE"
