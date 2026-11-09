# Release notes

## PostgreSQL 18

New databases use `pgvector/pgvector:pg18-bookworm` and enable vector. The container storage mount changes to `/var/lib/postgresql`; the host-side `PGDATA` setting keeps its meaning.

Existing databases require an explicit upgrade. To stay on PostgreSQL 17, use the [image and mount override](README.md#postgresql-18-upgrade). Setting `POSTGRES_VERSION=17` alone is insufficient.

Follow the [migration guide](https://www.openproject.org/docs/installation-and-operations/misc/migration-to-postgresql18/) before upgrading.
