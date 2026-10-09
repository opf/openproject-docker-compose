/*
 * Live Solutions hierarchy "Collapse all" / "Expand all" runtime patch.
 *
 * Background:
 *   OpenProject 17 ships the compiled Angular frontend inside the container
 *   image. We cannot rebuild the bundle, so this file is loaded as a plain
 *   <script src="/javascripts/livesolutions/hierarchy-collapse-all.js" defer>
 *   via the Live Solutions plugin view override (see
 *   app/views/common/_favicons.html.erb) and patches the WP hierarchy toolbar
 *   at runtime through DOM observation.
 *
 * Strategy:
 *   1. Detect a WP-table view. The Angular <wp-table> component renders a
 *      <table class="keyboard-accessible-list generic-table work-package-table">
 *      with hierarchy-mode rows containing `.wp-table--hierarchy-indicator`
 *      anchors. We look for that indicator as proof that hierarchy mode is
 *      active on this table.
 *   2. Insert two buttons ("Collapse all", "Expand all") into the WP page
 *      toolbar (`.toolbar-container .toolbar-items`). The install is
 *      idempotent — we mark the toolbar host with `data-ls-hca-installed` so
 *      re-scanning during Angular re-renders does not stack duplicates.
 *   3. On click, resolve the `WorkPackageViewHierarchiesService` through
 *      Angular's debug injector API and call its public `collapse(wpId)` /
 *      `expand(wpId)` methods for every parent whose state disagrees with the
 *      target. This updates `current.collapsed`, emits through `updates$()`,
 *      and Angular repaints the rows. If the service cannot be resolved, we
 *      fall back to synthesized clicks on the indicator anchors.
 *   4. Persist the collapsed state to the BACKEND (not localStorage) via
 *      /api/v3/livesolutions_hierarchy_state. The state is tied to the user
 *      account, so it survives refresh, navigation, project switch, and
 *      moving between browsers/devices. This makes the feature programmatic
 *      and permanent for all users.
 *   5. On every WP table view, fetch the user's saved state and restore it
 *      (collapse all if all_collapsed is true, otherwise expand all). Existing
 *      and future users receive a default row with all_collapsed=true from the
 *      backend, so the feature is always-on out of the box.
 *   6. Watch for view changes (Turbo navigation, Angular router, filter
 *      refresh, etc.) via a MutationObserver so the buttons re-install on
 *      every WP table view and detach on navigation away.
 *
 * i18n:
 *   Labels come from the existing keys
 *     window.I18n.t('js.button_collapse_all')
 *     window.I18n.t('js.button_expand_all')
 *   with English fallbacks if `I18n` has not finished loading.
 *
 *   `window.Livesolutions.HierarchyCollapseAll` is exposed for debugging
 *   and manual triggering:
 *     Livesolutions.HierarchyCollapseAll.collapse()
 *     Livesolutions.HierarchyCollapseAll.expand()
 *     Livesolutions.HierarchyCollapseAll.status()
 */

(function () {
  'use strict';

  if (window.Livesolutions && window.Livesolutions.HierarchyCollapseAll) {
    return;
  }

  var MARKER = 'data-ls-hca-installed';
  var FALLBACK_COLLAPSE = 'Collapse all';
  var FALLBACK_EXPAND = 'Expand all';
  var POLL_INTERVAL_MS = 250;
  var POLL_MAX_TRIES = 80; // ~20s. Enough for a cold boot on a slow disk.
  var INDICATOR_CLASS = 'wp-table--hierarchy-indicator';
  var COLLAPSED_CLASS = '-hierarchy-collapsed';
  var API_PATH = '/api/v3/livesolutions_hierarchy_state';
  var SYNC_DEBOUNCE_MS = 800;

  var backendState = null; // { all_collapsed: bool, collapsed_ids: [int,...] }
  var pendingSave = null;
  var syncTimer = null;
  var lastSyncedCollapsedJSON = null;
  var bootstrapRead = false;

  function log() {
    if (window.console && console.debug) {
      // eslint-disable-next-line no-console
      console.debug.apply(
        console,
        ['[LS:hierarchy-collapse-all]'].concat(Array.prototype.slice.call(arguments))
      );
    }
  }

  function warn() {
    if (window.console && console.warn) {
      // eslint-disable-next-line no-console
      console.warn.apply(
        console,
        ['[LS:hierarchy-collapse-all]'].concat(Array.prototype.slice.call(arguments))
      );
    }
  }

  function t(key, fallback) {
    try {
      if (window.I18n && typeof window.I18n.t === 'function') {
        var v = window.I18n.t(key);
        if (v && typeof v === 'string' && v !== key) return v;
      }
    } catch (_e) { /* ignore */ }
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Backend API helpers
  // ---------------------------------------------------------------------------

  function csrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  }

  /**
   * Try to read the hierarchy state that Rails embedded in the page head as a
   * meta tag. This avoids an extra API round-trip on the initial work-package
   * list load and lets us restore state before Angular paints the rows.
   */
  function readBootstrapState() {
    try {
      var meta = document.querySelector('meta[name="ls-hierarchy-state"]');
      if (!meta) return null;
      var raw = meta.getAttribute('content');
      if (!raw) return null;
      var data = JSON.parse(raw);
      return {
        all_collapsed: !!data.all_collapsed,
        collapsed_ids: Array.isArray(data.collapsed_ids) ? data.collapsed_ids : []
      };
    } catch (_e) {
      warn('failed to parse bootstrap hierarchy state', _e);
      return null;
    }
  }

  function fetchBackendState() {
    return window.fetch(API_PATH, {
      method: 'GET',
      credentials: 'same-origin',
      headers: { 'Accept': 'application/json' }
    }).then(function (resp) {
      if (!resp.ok) throw new Error('GET ' + API_PATH + ' returned ' + resp.status);
      return resp.json();
    }).then(function (data) {
      backendState = {
        all_collapsed: !!data.all_collapsed,
        collapsed_ids: Array.isArray(data.collapsed_ids) ? data.collapsed_ids : []
      };
      return backendState;
    }).catch(function (err) {
      warn('failed to fetch backend hierarchy state', err);
      backendState = { all_collapsed: true, collapsed_ids: [] };
      return backendState;
    });
  }

  function saveBackendState(allCollapsed, collapsedIds) {
    if (pendingSave) {
      pendingSave.all_collapsed = allCollapsed;
      pendingSave.collapsed_ids = collapsedIds;
    } else {
      pendingSave = {
        all_collapsed: allCollapsed,
        collapsed_ids: Array.isArray(collapsedIds) ? collapsedIds : []
      };
    }

    if (syncTimer) {
      window.clearTimeout(syncTimer);
    }
    syncTimer = window.setTimeout(function () {
      var payload = pendingSave;
      pendingSave = null;
      syncTimer = null;

      window.fetch(API_PATH, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken()
        },
        body: JSON.stringify(payload)
      }).then(function (resp) {
        if (!resp.ok) throw new Error('POST ' + API_PATH + ' returned ' + resp.status);
        return resp.json();
      }).then(function (data) {
        backendState = {
          all_collapsed: !!data.all_collapsed,
          collapsed_ids: Array.isArray(data.collapsed_ids) ? data.collapsed_ids : []
        };
        log('saved backend hierarchy state', backendState);
      }).catch(function (err) {
        warn('failed to save backend hierarchy state', err);
      });
    }, SYNC_DEBOUNCE_MS);
  }

  // ---------------------------------------------------------------------------
  // DOM helpers
  // ---------------------------------------------------------------------------

  /**
   * A hierarchy-mode WP table is one that renders at least one
   * .wp-table--hierarchy-indicator anchor inside a row that has children.
   * On flat lists the rows exist but every indicator is hidden or
   * non-interactive. Presence of the element is the sufficient signal —
   * we only operate on visible indicators anyway.
   */
  function findHierarchyTable() {
    var selectors = ['table.work-package-table', 'table.wp-table--table'];
    for (var s = 0; s < selectors.length; s++) {
      var tables = document.querySelectorAll(selectors[s]);
      for (var i = 0; i < tables.length; i++) {
        if (tables[i].querySelector('.' + INDICATOR_CLASS)) {
          return tables[i];
        }
      }
    }
    return null;
  }

  /**
   * Locate a toolbar element that we can append our button group to.
   * OpenProject 17.6 places the hierarchy toggle in the subject column
   * header (<th class="wp-table--table-header"> with <sortHeader>), not
   * in a dedicated toolbar group. We therefore append the bulk-action buttons
   * to the main `.toolbar-items` list inside `.toolbar-container`, which is
   * present on every partitioned/embedded WP page.
   */
  function findToolbarHost(table) {
    var host = null;
    var root = table.closest('.work-packages-partitioned-query-space--container')
            || table.closest('.work-packages-embedded-view--container')
            || table.closest('[class*="work-packages"]')
            || document.body;

    var toolbars = root.querySelectorAll('.toolbar-container .toolbar-items, .toolbar .toolbar-items, .toolbar-items');
    for (var i = 0; i < toolbars.length; i++) {
      var items = toolbars[i];
      if (items.children.length > 0) {
        host = items;
        break;
      }
    }
    if (!host && toolbars.length) {
      host = toolbars[0];
    }
    return host;
  }

  function makeButton(label, kind) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'button ls-hca-button ls-hca-' + kind;
    btn.setAttribute('data-ls-hca-kind', kind);
    btn.textContent = label;
    btn.setAttribute('aria-label', label);
    return btn;
  }

  function installButtons(host) {
    if (!host || host.hasAttribute(MARKER)) return false;
    var existing = host.querySelector('.ls-hca-buttons');
    if (existing && existing.parentNode) {
      existing.parentNode.removeChild(existing);
    }

    var wrap = document.createElement('li');
    wrap.className = 'toolbar-item ls-hca-buttons';
    wrap.setAttribute('role', 'group');
    wrap.setAttribute('aria-label', 'Hierarchy bulk actions');

    var collapseBtn = makeButton(t('js.button_collapse_all', FALLBACK_COLLAPSE), 'collapse-all');
    var expandBtn   = makeButton(t('js.button_expand_all',   FALLBACK_EXPAND),   'expand-all');

    collapseBtn.addEventListener('click', function () { runAction('collapse'); });
    expandBtn.addEventListener('click',   function () { runAction('expand');   });

    wrap.appendChild(collapseBtn);
    wrap.appendChild(expandBtn);

    var sibling = host.querySelector('.toolbar-item [class*="hierarchy"], .toolbar-item [class*="group-by"], .toolbar-item [class*="filter"]');
    if (sibling && sibling.closest('.toolbar-item') && sibling.closest('.toolbar-item').parentNode === host) {
      var ref = sibling.closest('.toolbar-item');
      host.insertBefore(wrap, ref.nextSibling);
    } else if (host.firstChild) {
      host.insertBefore(wrap, host.firstChild.nextSibling || host.firstChild);
    } else {
      host.appendChild(wrap);
    }

    host.setAttribute(MARKER, '1');
    log('installed buttons on', host);
    return true;
  }

  function cleanup() {
    var orphans = document.querySelectorAll('.ls-hca-buttons');
    for (var i = 0; i < orphans.length; i++) {
      var host = orphans[i].parentElement;
      if (host && host.hasAttribute && host.hasAttribute(MARKER)) {
        host.removeAttribute(MARKER);
      }
      if (orphans[i].parentNode) {
        orphans[i].parentNode.removeChild(orphans[i]);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // State / action
  // ---------------------------------------------------------------------------

  /**
   * Walk an anchor's row ancestors to find `data-work-package-id`.
   */
  function findWpIdFromIndicator(anchor) {
    var el = anchor;
    while (el && el !== document.body) {
      if (el.dataset && el.dataset.workPackageId) {
        var id = parseInt(el.dataset.workPackageId, 10);
        if (!isNaN(id)) return id;
      }
      el = el.parentElement;
    }
    return null;
  }

  /**
   * Read the source-of-truth collapsed state for a work package from the
   * Angular service. Returns null on failure.
   */
  function readServiceState(table) {
    var service = resolveHierarchyService(table);
    if (!service) return null;
    if (!service.current) return null;
    if (service.current.collapsed === null) return null;
    if (typeof service.current.collapsed !== 'object') return null;
    return service;
  }

  function currentCollapsedIdsMap(table) {
    var service = readServiceState(table);
    if (!service) return {};
    return service.current.collapsed || {};
  }

  /**
   * Extract an array of currently collapsed work package ids from the
   * Angular service state map. The map keys are ids as strings and values
   * are booleans.
   */
  function currentCollapsedIdsArray(table) {
    var map = currentCollapsedIdsMap(table);
    var ids = [];
    Object.keys(map).forEach(function (key) {
      if (map[key]) {
        var id = parseInt(key, 10);
        if (!isNaN(id)) ids.push(id);
      }
    });
    return ids.sort(function (a, b) { return a - b; });
  }

  /**
   * Apply a "collapse" or "expand" action to every parent row currently
   * rendered, then persist the resulting state to the backend.
   */
  function runAction(kind) {
    var table = findHierarchyTable();
    if (!table) {
      warn('runAction: no hierarchy table found');
      return;
    }
    var indicators = table.querySelectorAll('.' + INDICATOR_CLASS);
    if (!indicators.length) {
      warn('runAction: no parent indicators rendered');
      return;
    }

    var wantCollapsed = (kind === 'collapse');
    var service = readServiceState(table);

    if (service) {
      var touchedIds = [];
      indicators.forEach(function (anchor) {
        var wpId = findWpIdFromIndicator(anchor);
        if (wpId == null) return;
        var currentlyCollapsed = Boolean(service.current.collapsed[wpId]);
        if (currentlyCollapsed !== wantCollapsed) {
          touchedIds.push(wpId);
        }
      });
      if (touchedIds.length) {
        try {
          var action = wantCollapsed ? service.collapse : service.expand;
          touchedIds.forEach(function (wpId) { action.call(service, wpId); });
          var collapsedIds = wantCollapsed ? currentCollapsedIdsArray(table) : [];
          saveBackendState(wantCollapsed, collapsedIds);
          log('runAction', kind, 'service-path touched=' + touchedIds.length);
          return;
        } catch (_e) {
          warn('service-path failed, falling back to per-click', _e);
        }
      } else {
        var collapsedIds = wantCollapsed ? currentCollapsedIdsArray(table) : [];
        saveBackendState(wantCollapsed, collapsedIds);
        log('runAction: already in target state, persisted');
        return;
      }
    }

    // Per-click fallback: dispatch a synthesized click on each disagreeing
    // indicator. The upstream HierarchyClickHandler does the rest. We wait a
    // short beat so Angular can update the row DOM, then read the final
    // collapsed state from the indicator CSS class.
    var clickedIds = [];
    indicators.forEach(function (anchor) {
      var isCollapsedNow = anchor.classList.contains(COLLAPSED_CLASS);
      if (isCollapsedNow !== wantCollapsed) {
        var wpId = findWpIdFromIndicator(anchor);
        if (wpId != null) clickedIds.push(wpId);
        anchor.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, button: 0 }));
      }
    });
    log('runAction', kind, 'per-click clicks=' + clickedIds.length);

    window.setTimeout(function () {
      var collapsedMap = {};
      indicators.forEach(function (anchor) {
        var wpId = findWpIdFromIndicator(anchor);
        if (wpId == null) return;
        collapsedMap[wpId] = anchor.classList.contains(COLLAPSED_CLASS);
      });
      var collapsedIds = wantCollapsed
        ? Object.keys(collapsedMap).filter(function (k) { return collapsedMap[k]; }).map(function (k) { return parseInt(k, 10); }).sort(function (a, b) { return a - b; })
        : [];
      saveBackendState(wantCollapsed, collapsedIds);
    }, 150);
  }

  /**
   * Read the current hierarchy state directly from the DOM. Returns
   * { all_collapsed, collapsed_ids } based on the `-hierarchy-collapsed`
   * class on each indicator. This works in production builds where the
   * Angular debug injector is unavailable.
   */
  function readCollapsedStateFromDOM(table) {
    var indicators = table.querySelectorAll('.' + INDICATOR_CLASS);
    var collapsedIds = [];
    var allCollapsed = true;
    indicators.forEach(function (anchor) {
      var wpId = findWpIdFromIndicator(anchor);
      if (wpId == null) return;
      var isCollapsed = anchor.classList.contains(COLLAPSED_CLASS);
      if (isCollapsed) {
        collapsedIds.push(wpId);
      } else {
        allCollapsed = false;
      }
    });
    collapsedIds.sort(function (a, b) { return a - b; });
    return { all_collapsed: allCollapsed, collapsed_ids: collapsedIds };
  }

  /**
   * Restore the backend-persisted state for this table view. Called once per
   * unique table appearance.
   *
   * If the Angular hierarchy service is resolvable, we use it. In production
   * builds `window.ng` is usually absent, so we fall back to synthesized clicks
   * on the hierarchy indicator anchors. We only click indicators whose current
   * DOM state disagrees with the target, and we avoid saving the state back to
   * the backend if the DOM already matches (so initial loads do not generate a
   * spurious write).
   */
  function restoreBackendState(table) {
    if (!backendState) {
      warn('cannot restore state: backend state not loaded');
      return;
    }
    var wantCollapsed = backendState.all_collapsed;
    var indicators = table.querySelectorAll('.' + INDICATOR_CLASS);

    // Preferred path: Angular service is available.
    var service = readServiceState(table);
    if (service) {
      var touched = 0;
      indicators.forEach(function (anchor) {
        var wpId = findWpIdFromIndicator(anchor);
        if (wpId == null) return;
        var currentlyCollapsed = Boolean(service.current.collapsed[wpId]);
        if (currentlyCollapsed !== wantCollapsed) {
          try {
            if (wantCollapsed) {
              service.collapse(wpId);
            } else {
              service.expand(wpId);
            }
            touched++;
          } catch (_e) {
            warn('failed to restore state for wp', wpId, _e);
          }
        }
      });

      if (!wantCollapsed && backendState.collapsed_ids && backendState.collapsed_ids.length) {
        backendState.collapsed_ids.forEach(function (wpId) {
          if (!service.current.collapsed[wpId]) {
            try {
              service.collapse(wpId);
              touched++;
            } catch (_e) {
              warn('failed to collapse individual wp', wpId, _e);
            }
          }
        });
      }

      var domState = readCollapsedStateFromDOM(table);
      if (JSON.stringify(domState) !== JSON.stringify({
        all_collapsed: backendState.all_collapsed,
        collapsed_ids: backendState.collapsed_ids
      })) {
        saveBackendState(domState.all_collapsed, domState.collapsed_ids);
      }
      log('restored backend hierarchy state: all_collapsed=' + wantCollapsed + ', touched=' + touched);
      return;
    }

    // Fallback path: only click indicators that actually need to change.
    var clickedIds = [];
    indicators.forEach(function (anchor) {
      var isCollapsedNow = anchor.classList.contains(COLLAPSED_CLASS);
      if (isCollapsedNow !== wantCollapsed) {
        var wpId = findWpIdFromIndicator(anchor);
        if (wpId != null) clickedIds.push(wpId);
        anchor.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, button: 0 }));
      }
    });

    // Wait for Angular to finish repainting, then read the final DOM state and
    // persist it only if it differs from what we already have stored.
    window.setTimeout(function () {
      var domState = readCollapsedStateFromDOM(table);
      var backendSnapshot = {
        all_collapsed: backendState.all_collapsed,
        collapsed_ids: backendState.collapsed_ids
      };
      if (JSON.stringify(domState) !== JSON.stringify(backendSnapshot)) {
        saveBackendState(domState.all_collapsed, domState.collapsed_ids);
      }
      log('restored backend hierarchy state via fallback: all_collapsed=' + wantCollapsed + ', clicks=' + clickedIds.length);
    }, 250);
  }

  /**
   * Detect user-driven individual hierarchy toggles by reading the DOM state
   * and sync it to the backend when it changes. This does not require the
   * Angular debug injector.
   */
  function syncIfChanged(table) {
    var domState = readCollapsedStateFromDOM(table);
    var snapshot = JSON.stringify(domState);
    if (snapshot === lastSyncedCollapsedJSON) return;
    lastSyncedCollapsedJSON = snapshot;
    saveBackendState(domState.all_collapsed, domState.collapsed_ids);
    log('synced individual toggle state', domState);
  }

  /**
   * Best-effort: resolve the WorkPackageViewHierarchiesService from the
   * Angular debug injector (`window.ng.getInjector`).
   *
   * OpenProject 17 production builds often do not expose `window.ng`, so this
   * helper is intentionally defensive. When it returns null the caller falls
   * back to synthesized clicks on the hierarchy indicator anchors.
   */
  function resolveHierarchyService(table) {
    var ng = window.ng;
    if (!ng || typeof ng.getInjector !== 'function') return null;

    var probe = table;
    while (probe && probe !== document.documentElement) {
      try {
        var inj = ng.getInjector(probe);
        if (inj && typeof inj.get === 'function') {
          var token = findServiceTokenByShape(inj);
          if (token) {
            var svc = inj.get(token);
            if (svc && typeof svc.toggle === 'function'
                && typeof svc.collapse === 'function'
                && typeof svc.expand === 'function'
                && typeof svc.collapsed === 'function'
                && svc.current && svc.current.collapsed !== null
                && typeof svc.current.collapsed === 'object') {
              return svc;
            }
          }
        }
      } catch (_e) { /* try parent */ }
      probe = probe.parentElement;
    }
    return null;
  }

  function findServiceTokenByShape(inj) {
    try {
      // In recent Angular production builds the token records live on
      // `injector._r3Injector.records` with token objects as keys.
      var candidates = [];
      if (inj.records && typeof inj.records === 'object') candidates.push(inj.records);
      if (inj._providers && typeof inj._providers === 'object') candidates.push(inj._providers);
      if (inj.providers && typeof inj.providers === 'object') candidates.push(inj.providers);
      if (inj._r3Injector && inj._r3Injector.records && typeof inj._r3Injector.records === 'object') {
        candidates.push(inj._r3Injector.records);
      }
      for (var c = 0; c < candidates.length; c++) {
        var records = candidates[c];
        var keys = Object.keys(records);
        for (var i = 0; i < keys.length; i++) {
          try {
            var inst = inj.get(keys[i]);
            if (!inst) continue;
            if (typeof inst.toggle !== 'function') continue;
            if (typeof inst.collapse !== 'function') continue;
            if (typeof inst.expand !== 'function') continue;
            if (typeof inst.collapsed !== 'function') continue;
            if (!inst.current) continue;
            if (inst.current.collapsed === null) continue;
            if (typeof inst.current.collapsed !== 'object') continue;
            return keys[i];
          } catch (_e) { /* skip */ }
        }
      }
    } catch (_e) { /* ignore */ }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  var lastRestored = false;
  var tableObserver = null;
  var tableObserverTimer = null;

  function stopWatchingTable() {
    if (tableObserverTimer) {
      window.clearTimeout(tableObserverTimer);
      tableObserverTimer = null;
    }
    if (tableObserver) {
      tableObserver.disconnect();
      tableObserver = null;
    }
  }

  /**
   * Watch a specific hierarchy table for class changes on the indicator
   * anchors. This lets us sync individual user toggles back to the backend
   * without relying on the Angular debug injector (`window.ng`), which is not
   * exposed in production builds.
   */
  function watchTableForToggles(table) {
    stopWatchingTable();
    if (!table) return;

    // Take an initial snapshot so we do not re-save the restore state.
    lastSyncedCollapsedJSON = JSON.stringify(readCollapsedStateFromDOM(table));

    tableObserver = new MutationObserver(function (mutations) {
      var relevant = false;
      for (var i = 0; i < mutations.length; i++) {
        var target = mutations[i].target;
        if (target && target.classList && target.classList.contains(INDICATOR_CLASS)) {
          relevant = true;
          break;
        }
      }
      if (!relevant) return;

      if (tableObserverTimer) window.clearTimeout(tableObserverTimer);
      tableObserverTimer = window.setTimeout(function () {
        syncIfChanged(table);
      }, 400);
    });

    tableObserver.observe(table, {
      attributes: true,
      attributeFilter: ['class'],
      subtree: true
    });
  }

  function scan() {
    try {
      var table = findHierarchyTable();
      if (!table) {
        cleanup();
        lastRestored = false;
        stopWatchingTable();
        return;
      }
      var host = findToolbarHost(table);
      if (!host) {
        warn('found hierarchy table but no toolbar host');
        return;
      }
      installButtons(host);

      // Restore backend state on the first scan after a table appears.
      if (!lastRestored) {
        lastRestored = true;
        watchTableForToggles(table);
        setTimeout(function () { restoreBackendState(table); }, 0);
      }
    } catch (e) {
      warn('scan failed', e);
    }
  }

  var observer = null;

  function start() {
    // Prefer the bootstrap meta tag (rendered by Rails on work-package pages)
    // over an extra API round-trip. This lets restore happen before Angular
    // paints the table rows.
    var boot = readBootstrapState();
    if (boot) {
      backendState = boot;
      bootstrapRead = true;
      log('loaded hierarchy state from bootstrap meta', boot);
    }

    var statePromise = boot ? Promise.resolve(boot) : fetchBackendState();
    statePromise.then(function () {
      var tries = 0;
      function tick() {
        scan();
        tries++;
        if (!document.querySelector('[' + MARKER + ']') && tries < POLL_MAX_TRIES) {
          setTimeout(tick, POLL_INTERVAL_MS);
        } else if (!observer) {
          observer = new MutationObserver(function () { scan(); });
          observer.observe(document.body, { childList: true, subtree: true });
        }
      }
      tick();
    });

    document.addEventListener('turbo:load', function () {
      lastRestored = false;
      stopWatchingTable();
      var nextBoot = readBootstrapState();
      if (nextBoot) {
        backendState = nextBoot;
        bootstrapRead = true;
      }
      (nextBoot ? Promise.resolve(nextBoot) : fetchBackendState()).then(scan);
    });
    window.addEventListener('hashchange', scan);
    window.addEventListener('popstate', scan);

    window.addEventListener('pagehide', function () {
      if (observer) { observer.disconnect(); observer = null; }
      stopWatchingTable();
    });
  }

  // Public debug surface.
  window.Livesolutions = window.Livesolutions || {};
  window.Livesolutions.HierarchyCollapseAll = {
    scan: scan,
    collapse: function () { runAction('collapse'); },
    expand: function () { runAction('expand'); },
    status: function () {
      var table = findHierarchyTable();
      var service = table ? readServiceState(table) : null;
      return {
        tableFound: !!table,
        serviceResolved: !!service,
        backendState: backendState,
        currentCollapsed: service ? service.current.collapsed : null
      };
    },
    clear: function () {
      saveBackendState(false, []);
      backendState = { all_collapsed: false, collapsed_ids: [] };
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
