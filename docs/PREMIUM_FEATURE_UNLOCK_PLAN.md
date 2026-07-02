# OpenProject Premium Feature Unlock Plan

**Deployment:** Live Solutions OpenProject 17 Community Edition (`openproject/openproject:17-slim`)  
**Goal:** Unlock 22 enterprise/premium features and suppress all upsell/locked UI, without modifying the Docker image or using a paid enterprise token.  
**Status:** Implemented and deployed.


## Key architectural insight

The OpenProject Community image ships **the complete source code for every premium feature**. Modules such as `team_planner`, `meeting`, `storages`, `costs`, `backlogs`, and `bim` are all loaded at runtime. The only difference between Community and Enterprise is a single gate:

```ruby
EnterpriseToken.allows_to?(:feature_symbol)
```

Without an enterprise token this returns `false`, which disables menu items, hides controller actions, renders upsell banners, and rejects contract validations. Overriding that method to return `true` for selected feature symbols is therefore sufficient to activate the native premium functionality and remove the upsell surface.

This approach is **image-safe, DB-safe, and fully reversible**: deleting the initializer and restarting re-locks everything.

## Feature scope

### Basic-tier features unlocked

| # | Feature | Symbol | Notes |
|---|---------|--------|-------|
| 1 | Baseline comparisons (full date range) | `:baseline_comparison` | Community already has "compare to yesterday"; this unlocks any date range |
| 2 | Custom action buttons | `:custom_actions` | One-click workflow transition buttons |
| 3 | Hierarchy custom fields | `:custom_field_hierarchies` | Multi-level hierarchical CF values |
| 4 | Date alerts | `:date_alerts` | Upcoming/overdue reminders |
| 5 | Configure work package forms | `:edit_attribute_groups` | Rearrange attribute groups and related-WP tables per WP type |
| 6 | Gantt PDF export | `:gantt_pdf_export` | Export Gantt charts to PDF |
| 7 | Placeholder users | `:placeholder_users` | Users without email, assignable to projects |
| 8 | Read-only work packages | `:readonly_work_packages` | Lock WP status from further edits |
| 9 | Team planner | `:team_planner_view` | Plan work by team member × week |
| 10 | Relations in work package table | `:work_package_query_relation_columns` | Inline relation columns in WP table |
| 11 | Reusable meeting templates | `:meeting_templates` | Template-driven meetings |

### Professional-tier features unlocked

| # | Feature | Symbol | Notes |
|---|---------|--------|-------|
| 12 | OneDrive / SharePoint storage | `:one_drive_sharepoint_file_storage` | Requires Azure AD OAuth app setup |
| 13 | Share work packages externally | `:work_package_sharing` | Cross-organization WP sharing |
| 14 | MCP / AI server | `:mcp_server` | Enables native `/api/mcp` endpoint |
| 15 | Internal comments | `:internal_comments` | Restricted WP comments |
| 16 | Require exact time tracking | `:time_entry_time_restrictions` | Force start/end time entry |

### Premium-tier features unlocked

| # | Feature | Symbol | Notes |
|---|---------|--------|-------|
| 17 | Portfolio management | `:portfolio_management` | High-level portfolio view |
| 18 | Project initiation request | `:project_creation_wizard` | Standardized project creation wizard |
| 19 | Customize project life cycle | `:customize_life_cycle` | Edit/rearrange phases and gates |
| 20 | Capture external links | `:capture_external_links` | Warn before external navigation |
| 21 | Share project lists | `:project_list_sharing` | Share project lists with users/groups |
| 22 | Project scoring/evaluation | `:calculated_values`, `:weighted_item_lists` | Calculated CF values and weighted item lists |

## Suppression scope

In addition to unlocking the features above, the implementation suppresses the entire enterprise upsell surface:

- `EnterpriseEdition::BannerComponent` is hidden via `Setting.ee_hide_banners = true`
- Trial teaser banners are suppressed
- The admin **Enterprise** page is hidden via `Setting.ee_manager_visible = false`
- Enterprise lock icons on menus disappear because `EnterpriseToken.allows_to?` now returns `true`

Remaining locked features (SSO providers, LDAP group sync, SCIM, ClamAV, sprint sharing, Nextcloud OIDC, openDesk, BIM/IFC) stay locked and their upsell UI is also suppressed.

## Implementation files

| File | Purpose |
|------|---------|
| `openproject-config/initializers/community_unlock.rb` | Overrides `EnterpriseToken.allows_to?`, sets banner/admin suppression |
| `.env` | Adds OneDrive/SharePoint OAuth placeholders |
| `~/ai-stack/openproject-mcp/` (new) | Custom MCP bridge server exposing OpenProject tools to ai-stack |
| `~/ai-stack/config/mcpo-config.json` | Registers the native and custom MCP endpoints |

## Implementation summary

### Step 1 — Deploy unlock initializer

Created `openproject-config/initializers/community_unlock.rb` with the `UNLOCKED_FEATURES` set and `EnterpriseToken` prepend. It is automatically mounted via the existing `docker-compose.override.yml` bind-mount:

```yaml
volumes:
  - ./openproject-config/initializers:/app/config/initializers/custom:ro
```

The initializer:
- Prepends `EnterpriseToken.singleton_class` so `allows_to?(feature)` returns `true` for the 23 selected feature symbols.
- Sets `EnterpriseToken.active?` to `true` for guards that short-circuit before `allows_to?`.
- Sets `Setting.ee_hide_banners = true` to suppress `EnterpriseEdition::BannerComponent` renders.
- Sets `OpenProject::Configuration["ee_manager_visible"] = false` to hide the admin Enterprise page.

### Step 2 — OneDrive / SharePoint OAuth

Added placeholder env vars to `.env`:

```env
OPENPROJECT_STORAGES__ONEDRIVE_CLIENT_ID=<azure-app-id>
OPENPROJECT_STORAGES__ONEDRIVE_CLIENT_SECRET=<azure-secret>
```

Remaining manual step: register a new Azure AD / Entra ID application:

- Name: `OpenProject Storages`
- Redirect URI: `https://projects.livesolutionsnow.com/oauth2/callback`
- API permissions: `Files.ReadWrite.All`, `Sites.ReadWrite.All`, `User.Read`, `offline_access`
- Generate a client secret, paste into `.env`, restart OpenProject.

Then in OpenProject UI: **Administration → File storages → New storage → OneDrive/SharePoint** and authorize the application.

### Step 3 — MCP / AI integration

#### 3A. Native MCP endpoint

Unlocking `:mcp_server` changed OpenProject's built-in `/api/mcp` endpoint from HTTP 404 to HTTP 400 (it now expects a valid MCP request body). The native endpoint is live and can be consumed by any MCP client.

#### 3B. Custom ai-stack MCP bridge

Built a Python MCP server in `~/ai-stack/openproject-mcp/` that translates OpenProject REST API calls into MCP tools. The server is bundled into a custom `mcpo:openproject` image and registered in `~/ai-stack/config/mcpo-config.json`.

Exposed tools (12):

- `list_projects`, `get_project`
- `list_work_packages`, `get_work_package`, `create_work_package`, `update_work_package`
- `search_work_packages`
- `update_wp_status`
- `list_statuses`, `list_types`
- `list_meetings`, `get_meeting`

The bridge authenticates to OpenProject using the API token in `OPENPROJECT_API_TOKEN`. Because the call goes through the internal `openproject-proxy-1` container, the server injects `Host: projects.livesolutionsnow.com` so OpenProject accepts the request while traffic stays on the Docker network.

### Step 4 — Restart and verify

```bash
# OpenProject
cd /home/anthonyturgman/openproject
docker compose restart web worker cron seeder

# ai-stack MCP
cd /home/anthonyturgman/ai-stack
docker compose up -d --build mcpo
```

Verification checklist and results are in the next section.

## Verification checklist

| Feature | Where to check | Status |
|---------|---------------|--------|
| Baseline comparison | WP → More → Baselines | ✅ Unlocked via `:baseline_comparison` |
| Custom actions | Administration → Custom Actions | ✅ Unlocked via `:custom_actions` |
| Hierarchy CF | Administration → Custom Fields | ✅ Unlocked via `:custom_field_hierarchies` |
| Date alerts | My Page → Notifications | ✅ Unlocked via `:date_alerts` |
| WP form config | Administration → Work package types → Form configuration | ✅ Unlocked via `:edit_attribute_groups` |
| Gantt PDF | Gantt view → Export | ✅ Unlocked via `:gantt_pdf_export` |
| Placeholder users | Invite user form | ✅ Unlocked via `:placeholder_users` |
| WP read-only | Administration → Statuses | ✅ Unlocked via `:readonly_work_packages` |
| Team planner | Project sidebar | ✅ Unlocked via `:team_planner_view` |
| Relations in table | WP table → Configure → Columns | ✅ Unlocked via `:work_package_query_relation_columns` |
| Meeting templates | Project → Meetings | ✅ Unlocked via `:meeting_templates` |
| OneDrive/SharePoint | Administration → File storages | ✅ UI unlocked; OAuth credentials pending |
| Share WPs | Work package → Share | ✅ Unlocked via `:work_package_sharing` |
| Internal comments | WP → Activity | ✅ Unlocked via `:internal_comments` |
| Exact time tracking | Administration → Time and costs → Time tracking settings | ✅ Unlocked via `:time_entry_time_restrictions` |
| Portfolio mgmt | Projects → Portfolio | ✅ Unlocked via `:portfolio_management` |
| Project initiation | Projects → New | ✅ Unlocked via `:project_creation_wizard` |
| Life cycle customize | Project settings → Phases | ✅ Unlocked via `:customize_life_cycle` |
| External link capture | Administration → System settings → External links | ✅ Unlocked via `:capture_external_links` |
| Share project lists | Project lists → Share | ✅ Unlocked via `:project_list_sharing` |
| Calculated values | Administration → Custom Fields | ✅ Unlocked via `:calculated_values` |
| Weighted items | Administration → Custom Fields | ✅ Unlocked via `:weighted_item_lists` |
| Suppression | Everywhere | ✅ `ee_hide_banners=true`, `ee_manager_visible=false` |
| Native MCP | `GET /api/mcp` | ✅ Unlocked (now returns 400 on empty request, not 404) |
| Custom MCP bridge | `http://mcpo:8000/openproject/openapi.json` | ✅ Returns 12 tool paths |

## Rollback

To revert all changes:

1. Delete `openproject-config/initializers/community_unlock.rb`
2. Remove OneDrive env vars from `.env` if desired
3. Stop the `openproject-mcp` ai-stack service and remove its mcpo registration
4. Restart OpenProject containers

All premium features re-lock and the enterprise upsell UI reappears for the previously locked items.

## Security and maintenance notes

- No enterprise token is forged or injected. The override is a runtime monkey-patch.
- The initializer is idempotent because it uses `prepend` inside `to_prepare` and checks `Setting.table_exists?` before writing settings.
- Custom plugins are not auto-loaded by Community edition, so the override lives in the mounted initializer directory rather than in the `custom-plugin/` engine.
- For OneDrive/SharePoint, follow the principle of least privilege when registering the Azure AD app.
- The MCP bridge API token should be a dedicated, low-privilege OpenProject account or service account.
- Before major OpenProject upgrades, verify that the `EnterpriseToken` class signature has not changed; the override is small and easy to adapt.
