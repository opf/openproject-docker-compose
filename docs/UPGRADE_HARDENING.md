# OpenProject Upgrade Hardening Guide

This document describes the hardening layer added to this OpenProject Docker
Compose deployment so that upstream updates can be applied without data loss,
formatting/style regressions, or prolonged outages.

It is stored in `docs/` (not in the upstream `README.md`) so it survives
`git pull origin stable/17`.

## 1. What is protected

| Asset | Location / mechanism | Protection |
|-------|----------------------|------------|
| PostgreSQL data | Named volume `openproject_openproject_pgdata` | Offline physical tarball + live logical `pg_dumpall` |
| OpenProject attachments/assets | Bind mount `/var/openproject/assets` | Offline tarball in `backups/` |
| Brand CSS / custom theme | `custom-plugin/openproject-livesolutions/.../theme.css` mounted to `/app/public/stylesheets/livesolutions-theme.css` | Health check verifies it is served after every restart |
| Custom plugin | `custom-plugin/openproject-livesolutions/` copied into image by `Dockerfile` | Verified present by health check; version compatibility still needs manual review on major upgrades |
| Cloudflare Access SSO | `openproject-config/initializers/cloudflare_access_auth.rb` mounted to `/app/config/initializers/custom/` | Verified present by health check |
| Hierarchy collapse state (#777) | `db/migrate/20260825210000_create_user_hierarchy_collapse_states.rb` + backend API | Migration must be run after image rebuild; state persists per user across browsers |
| Pagination default 100 (#778) | `lib/open_project/livesolutions/patches/query_params_representer_patch.rb` | Enforced at API level for all users and queries |
| Premium feature unlock | `openproject-config/initializers/community_unlock.rb` mounted to `/app/config/initializers/custom/` | 22 enterprise features unlocked; verified present by feature check |
| Proxy / Caddyfile | `proxy/Caddyfile` bind-mounted | Preserved during `git pull` by upgrade wrapper |
| Secrets | `.env` (gitignored) | Never committed; restored automatically after `git pull` |

## 2. Files added by hardening

```text
scripts/
  upgrade.sh           # Orchestrated upgrade with backup, dry-run, rollback
  health-check.sh      # Post-upgrade / periodic validation
  backup-logical.sh    # Live logical SQL backup while stack is up
control/
  Dockerfile           # Now based on postgres:17-bookworm with PG upgrade tools
  backup/entrypoint.sh # Physical offline backup (PGDATA + OPDATA + manifest)
  restore/entrypoint.sh # Restore a backup set and relaunch
  upgrade/scripts/00-db-upgrade.sh # Version-agnostic pg_upgrade wrapper
docs/
  UPGRADE_HARDENING.md # This document
```

## 3. Normal upgrade workflow

Run everything from `/home/anthonyturgman/openproject`.

### 3.1 Preview what upstream will change (safe)

```bash
./scripts/upgrade.sh --dry-run
```

This fetches `origin/stable/17`, shows the diff, verifies custom files are
present, and prints the commands it would run. No containers are modified.

### 3.2 Perform the upgrade

```bash
./scripts/upgrade.sh
```

The wrapper executes, in order:

1. Verifies the merged Docker Compose configuration is valid.
2. Verifies all custom files exist.
3. Takes an **offline physical backup** of PGDATA and OPDATA with a timestamped
   manifest in `backups/`.
4. Pulls upstream changes (`git pull origin stable/17`).
   - If a merge conflict occurs, it aborts the merge and restores your local
     `docker-compose.override.yml` and `.env`.
5. Runs the database major-version upgrade container only if the PG version
   changed.
6. Restarts the stack with `docker compose up -d --build --pull always`.
7. Runs `./scripts/health-check.sh`. If it fails, **automatically restores the
   backup and restarts the previous version**.

## 4. Manual rollback

If anything is wrong after an upgrade, restore the latest backup and restart:

```bash
./scripts/upgrade.sh --restore-only
```

Or restore a specific timestamp:

```bash
RESTORE_TIMESTAMP=1782965033 docker compose -f docker-compose.yml -f docker-compose.control.yml run --rm restore
docker compose up -d
```

## 5. Additional live backups

The offline physical backup used by `upgrade.sh` is tied to the PG version
running in the volume. For extra safety (especially before a major Postgres
upgrade), create a portable logical dump while the stack is running:

```bash
./scripts/backup-logical.sh
```

The resulting `*.sql.gz` can be restored into a fresh Postgres container of any
major version.

## 6. Periodic health checks

Run the health checker manually or from a cron job:

```bash
./scripts/health-check.sh
```

It verifies:

- Required containers are running.
- PostgreSQL is ready and the `users` table is readable.
- The OpenProject `/health_checks/default` endpoint returns success.
- The Live Solutions brand CSS is reachable.
- The custom plugin directory is mounted.
- The Cloudflare Access initializer is present.
- The hierarchy-collapse backend migration has been applied
  (`user_hierarchy_collapse_states` table exists).
- The pagination-default patch is active (an API query returns `pageSize=100`
  when no explicit page size is requested).
- The public login page is reachable via Cloudflare Tunnel.
- The asset directory is accessible.

## 7. Premium features

The deployment unlocks 22 OpenProject Enterprise features via
`openproject-config/initializers/community_unlock.rb` (see
`docs/PREMIUM_FEATURE_UNLOCK_PLAN.md`). This file is mounted into the
container just like the Cloudflare Access initializer.

Before any upgrade, the feature check verifies:

- `community_unlock.rb` exists and is mounted.
- All 22 expected feature symbols are present in the unlock list.
- Upsell banner suppression (`ee_hide_banners = true`) is configured.

After the upgrade, the same checks run again; if any fail, the orchestrator
rolls back to the pre-upgrade backup so the premium features stay unlocked.

## 8. Important caveats

- **`.env` and `docker-compose.override.yml` are gitignored.** The upgrade
  wrapper restores them after `git pull`, but you should keep an encrypted
  off-host copy of `.env` as well.
- **`backups/` may be owned by root** if created by the control-plane container.
  Ensure the host user can write to it, or `chown -R 1000:1000 backups/` after
  the first backup.
- **Major OpenProject version upgrades** (e.g., 17 → 18) may break custom
  plugin hooks or CSS selectors. The health checks will catch a missing CSS
  file or initializer, but you must still review upstream release notes and
  update `theme.css` / plugin code as needed.
- **Major PostgreSQL upgrades** from a version older than 17 require PG binaries
  for both the old and new versions in the control image. If you are on PG 13 and
  need to migrate to 17, extend `control/Dockerfile` to install the old
  `postgresql-13` package from apt.postgresql.org, or restore a logical backup
  into a fresh PG 17 volume.

## 9. Disaster-recovery checklist

1. Stop the stack: `docker compose down`
2. Identify the backup timestamp to restore: `ls -1 backups/*-manifest.txt`
3. Restore: `RESTORE_TIMESTAMP=<ts> docker compose -f docker-compose.yml -f docker-compose.control.yml run --rm restore`
4. Start: `docker compose up -d`
5. Validate: `./scripts/health-check.sh`

## 10. References

- Upstream compose repo: https://github.com/opf/openproject-docker-compose
- OpenProject Docker upgrade docs: https://www.openproject.org/docs/installation-and-operations/installation/docker/
- PostgreSQL pg_upgrade docs: https://www.postgresql.org/docs/current/pgupgrade.html
