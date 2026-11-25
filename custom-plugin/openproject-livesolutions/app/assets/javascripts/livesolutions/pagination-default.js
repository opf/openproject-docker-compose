// Live Solutions — pagination default for OpenProject.
//
// Request #778:
//   * The per-page option list is 20, 100, 250, 500 (mirrors
//     OPENPROJECT_PER_PAGE__OPTIONS in .env and the database's
//     per_page_options column).
//   * The default for a fresh visitor must be 100, not 20.
//   * Any cached op_pagination.perPage value that is no longer in
//     the allowed list (e.g. legacy "50" or "10") must be cleared
//     so the frontend falls back to the new default.
//
// Loaded synchronously in <head> from /javascripts/livesolutions/
// pagination-default.js (mounted via docker-compose.override.yml
// into the OpenProject container's /app/public/javascripts tree).
// This file is NOT served by the fingerprinted Sprockets pipeline
// on purpose — we want it to be hot-swappable without rebuilding
// the OpenProject image, matching the existing
// livesolutions-theme.css mount.

(function () {
  'use strict';

  // Keep in sync with .env (OPENPROJECT_PER__PAGE__OPTIONS) and the
  // database's per_page_options column.
  var ALLOWED_OPTIONS = ['20', '100', '250', '500'];
  var DEFAULT_PER_PAGE = '100';
  var STORAGE_KEY = 'pagination.perPage';

  // Prefer OpenProject's wrapped storage when it's available — it
  // honours incognito/permission policies. The OP helper is a function:
  //   guardedLocalStorage(key)         -> read
  //   guardedLocalStorage(key, value)  -> write
  //   guardedLocalStorage(key, null)   -> remove
  // Fall back to plain localStorage so the script still works during the
  // very first request before OpenProject has booted.
  function getStore() {
    var op = (typeof window !== 'undefined' && window.OpenProject) || null;
    if (op && typeof op.guardedLocalStorage === 'function') {
      return {
        get: function (k) { return op.guardedLocalStorage(k); },
        set: function (k, v) { op.guardedLocalStorage(k, v); },
        remove: function (k) { op.guardedLocalStorage(k, null); }
      };
    }
    try {
      return {
        get: function (k) { return window.localStorage.getItem(k); },
        set: function (k, v) { window.localStorage.setItem(k, v); },
        remove: function (k) { window.localStorage.removeItem(k); }
      };
    } catch (e) {
      // Storage disabled (Safari private mode, quota, etc.) — silently no-op.
      return null;
    }
  }

  function canonicalize(value) {
    if (value === null || value === undefined) { return null; }
    var s = String(value).trim();
    for (var i = 0; i < ALLOWED_OPTIONS.length; i++) {
      if (ALLOWED_OPTIONS[i] === s) { return ALLOWED_OPTIONS[i]; }
    }
    return null;
  }

  function apply() {
    var store = getStore();
    if (!store) { return; }

    var current = store.get(STORAGE_KEY);
    var canonical = canonicalize(current);

    if (canonical === null) {
      if (current !== null && current !== undefined && current !== '') {
        // Stale value from a previous options list (e.g. '10', '50',
        // 'all'). Drop it so the frontend picks the new default.
        store.remove(STORAGE_KEY);
      }
      // No cached choice — seed the requested baseline default of 100.
      store.set(STORAGE_KEY, DEFAULT_PER_PAGE);
    } else if (canonical !== current) {
      // Stored value is allowed but not in canonical form (e.g. ' 100 ').
      // Rewrite it so downstream consumers see a clean value.
      store.set(STORAGE_KEY, canonical);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', apply, { once: true });
  } else {
    apply();
  }
})();
