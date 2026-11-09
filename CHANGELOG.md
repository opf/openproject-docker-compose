# Release notes

## PostgreSQL 18 (OpenProject 18.0 rollout)

- Default to `pgvector/pgvector:pg18-bookworm` and enable vector in newly initialized databases.
- Mount database storage at `/var/lib/postgresql`; PostgreSQL 18 stores the cluster in its `18/docker` subdirectory.
- Require an explicit database upgrade for existing installations. No automatic major upgrade runs.
- Keep the existing host-side `PGDATA` setting. Use new storage for the upgraded database.
- To stay on PostgreSQL 17, retain its image and previous mount with the override in the README. Setting `POSTGRES_VERSION=17` alone is insufficient.

See the [migration guide](https://www.openproject.org/docs/installation-and-operations/misc/migration-to-postgresql18/) for backup, restore, activation, verification, and rollback.
