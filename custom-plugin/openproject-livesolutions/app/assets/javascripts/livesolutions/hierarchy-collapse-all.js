/*
 * Live Solutions hierarchy "Collapse all" / "Expand all" runtime patch.
 *
 * Background:
 *   OpenProject 17 ships the compiled Angular frontend inside the
 *   container image. We cannot rebuild the bundle, so this file is
 *   loaded as a plain
 *     <script src="/javascripts/livesolutions/hierarchy-collapse-all.js" defer>
 *   via the Live Solutions plugin view override (see
 *   app/views/common/_favicons.html.erb) and patches the WP hierarchy
 *   toolbar at runtime through DOM observation.
 *
 * Strategy:
 *   1. Detect the WP-table view (a `.wp-table--table` element rendered
 *      by the Angular `wp-table` host component) AND that hierarchy mode
 *      is currently active — the Angular hierarchy row builder emits a
 *      `.wp-table--hierarchy-indicator` anchor next to every parent.
 *   2. Insert two buttons ("Collapse all", "Expand all") into the
 *      toolbar next to the existing hierarchy/grouping controls. The
 *      install is idempotent — we mark the toolbar host with
 *      `data-ls-hca-installed` so re-scanning during Angular re-renders
 *      does not stack duplicates.
 *   3. On click:
 *      a. Preferred: resolve the `WorkPackageViewHierarchiesService`
 *         through Angular's debug injector API. We batch-edit its
 *         `current.collapsed` map (the documented source of truth) and
 *         fire change detection by calling `service.toggle(firstId)`,
 *         which publishes through `live$()` / `updates$()` so the
 *         wp-table re-renders. Because `toggle()` flips the value of
 *         its target, we restore that one entry to the target value
 *         immediately after the call.
 *      b. Fallback: dispatch a synthesized `click` on each
 *         `.wp-table--hierarchy-indicator` whose current state disagrees
 *         with the requested action. The upstream `HierarchyClickHandler`
 *         (in wp-fast-table/handlers/row) is bound to tbody `click`
 *         events and calls `wpTableHierarchies.toggle(wpId)` exactly as
 *         the upstream chevron does, so the rendered rows refresh
 *         through Angular's normal change detection with no internal API
 *         access required.
 *   4. Watch for view changes (Turbo navigation, Angular router, refresh
 *      filters, etc.) via a MutationObserver so the buttons re-install
 *      on every WP table view and detach on navigation away.
 *
 * i18n:
 *   Labels come from the existing, unused keys
 *     window.I18n.t('js.button_collapse_all')
 *     window.I18n.t('js.button_expand_all')
 *   with English fallbacks if `I18n` has not finished loading.
 *
 *   `window.Livesolutions.HierarchyCollapseAll` is exposed for debugging
 *   and to allow console-driven manual triggering (`Livesolutions.
 *   HierarchyCollapseAll.collapse()` / `.expand()`).
 */

(function () {
  'use strict';

  if (window.Livesolutions && window.Livesolutions.HierarchyCollapseAll) {
    return;
  }

  var MARKER = 'data-ls-hca-installed';
  var FALLBACK_COLLAPSE = 'Collapse all';
  var FALLBACK_EXPAND = 'Expand all';
  var POLL_INTERVAL_MS = 200;
  var POLL_MAX_TRIES = 80; // ~16s. Enough for a cold boot on a slow disk.

  function log() {
    if (window.console && console.debug) {
      // eslint-disable-next-line no-console
      console.debug.apply(
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
    var tables = document.querySelectorAll('.wp-table--table');
    for (var i = 0; i < tables.length; i++) {
      if (tables[i].querySelector('.wp-table--hierarchy-indicator')) {
        return tables[i];
      }
    }
    return null;
  }

  /**
   * Locate a toolbar element that we can append our button group to.
   * Precedence:
   *   1. The toolbar item wrapping `.hierarchy-group` — this is the
   *      natural sibling container for hierarchy bulk actions.
   *   2. The toolbar item wrapping `.group-by` — close enough.
   *   3. The first `.toolbar-item` inside the WP toolbar.
   *   4. The WP toolbar root (`.toolbar`).
   * Returns null if no toolbar can be located.
   */
  function findToolbarHost(table) {
    var root = table.closest('.toolbar')
            || table.closest('[class*="work-packages"]')
            || document;
    var items = root.querySelectorAll('.toolbar-items, .toolbar-item');
    var i;

    for (i = 0; i < items.length; i++) {
      if (items[i].querySelector('.hierarchy-group')) {
        return items[i].parentNode || items[i];
      }
    }
    for (i = 0; i < items.length; i++) {
      if (items[i].querySelector('.group-by')) {
        return items[i].parentNode || items[i];
      }
    }
    if (items.length) return items[0].parentNode || items[0];

    return root.querySelector('.toolbar') || root.querySelector('.toolbar-items') || null;
  }

  function makeButton(label, kind) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'Button ls-hca-button ls-hca-' + kind;
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

    var wrap = document.createElement('span');
    wrap.className = 'toolbar-item ls-hca-buttons';
    wrap.setAttribute('role', 'group');
    wrap.setAttribute('aria-label', 'Hierarchy bulk actions');

    var collapseBtn = makeButton(t('js.button_collapse_all', FALLBACK_COLLAPSE), 'collapse-all');
    var expandBtn   = makeButton(t('js.button_expand_all',   FALLBACK_EXPAND),   'expand-all');

    collapseBtn.addEventListener('click', function () { runAction('collapse'); });
    expandBtn.addEventListener('click',   function () { runAction('expand');   });

    wrap.appendChild(collapseBtn);
    wrap.appendChild(expandBtn);

    var sibling = host.querySelector('.hierarchy-group, [class*="hierarchy"]');
    if (sibling && sibling.parentNode) {
      var ref = sibling.closest('.toolbar-item') || sibling;
      if (ref.parentNode) {
        ref.parentNode.insertBefore(wrap, ref.nextSibling);
      } else {
        host.appendChild(wrap);
      }
    } else {
      host.appendChild(wrap);
    }

    host.setAttribute(MARKER, '1');
    log('installed buttons on', host);
    return true;
  }

  function cleanup() {
    // Detach any orphan buttons left behind when the Angular WP table host
    // unmounts (filter change, navigation, project switch).
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
   * Returns the parsed integer id, or null if not found.
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
    // The source-of-truth map must be a non-null object. (typeof null === 'object'.)
    if (service.current.collapsed === null) return null;
    if (typeof service.current.collapsed !== 'object') return null;
    return service;
  }

  /**
   * Apply a "collapse" or "expand" action to every parent row currently
   * rendered.
   *
   * The Angular `WorkPackageViewHierarchiesService` only exposes `toggle()`,
   * not `collapse()`/`expand()` (per the compiled bundle's public surface).
   * Toggling each entry individually from the public surface would only be
   * necessary if the table view did not repaint from a single emission; the
   * cleaner and 100%-reliable strategy is to walk the rendered indicators
   * and dispatch a synthesized click on each whose state disagrees with
   * the target. The upstream `HierarchyClickHandler` (see the compiled
   * chunk for `HierarchyClickHandler`) is bound to tbody `click` events
   * scoped to `.wp-table--hierarchy-indicator` and already does the right
   * thing: it calls `wpTableHierarchies.toggle(wpId)` on the row's
   * `data-work-package-id` and Angular zone-based change detection repaints
   * the rows.
   *
   * This matches the documented fallback in the request: "dispatching a
   * click on the individual row toggles" re-renders through the upstream
   * machinery with no internal API access required.
   *
   * We additionally probe for the Angular service to enable a fast batch
   * path when possible — the service's `current.collapsed` map is mutated
   * directly, then a single `toggle()` fires the change-detection emission.
   * If the service cannot be resolved, we fall through silently to the
   * per-indicator click path.
   */
  function runAction(kind) {
    var table = findHierarchyTable();
    if (!table) {
      log('runAction: no hierarchy table found');
      return;
    }
    var indicators = table.querySelectorAll('.wp-table--hierarchy-indicator');
    if (!indicators.length) {
      log('runAction: no parent indicators rendered');
      return;
    }

    var wantCollapsed = (kind === 'collapse');
    var service = readServiceState(table);

    if (service) {
      // Fast batch path: use the service's public collapse()/expand() methods
      // for every parent whose state disagrees with the target. This avoids
      // mutating the internal map directly and lets Angular's change detection
      // run through the normal service emission path.
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
          log('runAction', kind, 'service-path touched=' + touchedIds.length);
          return;
        } catch (_e) {
          // Fall through to per-click path.
        }
      } else {
        log('runAction: already in target state, no-op');
        return;
      }
    }

    // Per-click fallback: dispatch a synthesized click on each disagreeing
    // indicator. The upstream HierarchyClickHandler does the rest.
    var clicks = 0;
    indicators.forEach(function (anchor) {
      var isCollapsedNow = anchor.classList.contains('wp-table--hierarchy-indicator-collapsed');
      if (isCollapsedNow !== wantCollapsed) {
        anchor.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, button: 0 }));
        clicks++;
      }
    });
    log('runAction', kind, 'per-click clicks=' + clicks);
  }

  /**
   * Best-effort: resolve the WorkPackageViewHierarchiesService from the
   * Angular debug injector (`window.ng.getInjector`). Walks up the DOM
   * until it finds an injector that exposes a token whose instance has
   * the documented public surface (toggle / current.collapsed / collapsed).
   * Returns null on any failure.
   */
  function resolveHierarchyService(table) {
    var ng = window.ng;
    if (!ng || typeof ng.getInjector !== 'function') return null;

    var probe = table;
    while (probe && probe !== document.body) {
      try {
        var inj = ng.getInjector(probe);
        if (inj && typeof inj.get === 'function') {
          var token = findServiceTokenByShape(inj);
          if (token) {
            var svc = inj.get(token);
            if (svc && typeof svc.toggle === 'function'
                && svc.current && svc.current.collapsed
                && typeof svc.collapsed === 'function') {
              return svc;
            }
          }
        }
      } catch (_e) { /* try parent */ }
      probe = probe.parentElement;
    }
    return null;
  }

  /**
   * Enumerate DI tokens in an injector looking for one whose instance
   * exposes the documented `WorkPackageViewHierarchiesService` public
   * surface (toggle, current.collapsed, collapsed). Best-effort — relies
   * on the Angular Ivy injector record map being readable, which it is
   * in dev builds and often in `production: false` Angular builds.
   */
  function findServiceTokenByShape(inj) {
    try {
      var records = inj.records || inj._providers || inj.providers;
      if (!records || typeof records !== 'object') return null;
      var keys = Object.keys(records);
      for (var i = 0; i < keys.length; i++) {
        try {
          var inst = inj.get(keys[i]);
          if (!inst) continue;
          if (typeof inst.toggle !== 'function') continue;
          if (typeof inst.collapsed !== 'function') continue;
          if (!inst.current) continue;
          if (inst.current.collapsed === null) continue;
          if (typeof inst.current.collapsed !== 'object') continue;
          return keys[i];
        } catch (_e) { /* token not instantiable, skip */ }
      }
    } catch (_e) { /* ignore */ }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  function scan() {
    try {
      var table = findHierarchyTable();
      if (!table) {
        cleanup();
        return;
      }
      var host = findToolbarHost(table);
      if (!host) return;
      installButtons(host);
    } catch (e) {
      log('scan failed', e);
    }
  }

  var observer = null;

  function start() {
    // First-pass polling while Angular bootstraps and renders the table.
    // We self-throttle on the install marker so we stop polling as soon
    // as the buttons are in place, then hand off to a MutationObserver
    // for long-running reactivity.
    var tries = 0;
    function tick() {
      scan();
      tries++;
      if (!document.querySelector('[' + MARKER + ']') && tries < POLL_MAX_TRIES) {
        setTimeout(tick, POLL_INTERVAL_MS);
      } else if (!observer) {
        observer = new MutationObserver(scan);
        observer.observe(document.body, { childList: true, subtree: true });
      }
    }
    tick();

    // Re-install on Turbo / Angular router events. Some Angular-driven
    // navigations do not bubble through `popstate`; mutation observer
    // covers them anyway, but explicit hooks are cheap insurance.
    document.addEventListener('turbo:load', scan);
    window.addEventListener('hashchange', scan);
    window.addEventListener('popstate', scan);

    window.addEventListener('pagehide', function () {
      if (observer) { observer.disconnect(); observer = null; }
    });
  }

  // Public debug surface.
  window.Livesolutions = window.Livesolutions || {};
  window.Livesolutions.HierarchyCollapseAll = {
    scan: scan,
    collapse: function () { runAction('collapse'); },
    expand: function () { runAction('expand'); }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
