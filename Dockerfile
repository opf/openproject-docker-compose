FROM openproject/openproject:17-slim

# --- Phase 1: Install system deps needed at build time ---
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# --- Phase 2: Copy custom plugins into the plugins directory ---
COPY --chown=app:app custom-plugin/openproject-livesolutions  /app/plugins/openproject-livesolutions
COPY --chown=app:app custom-plugin/openproject-request-portal /app/plugins/openproject-request-portal

# --- Phase 3: Register plugins via Gemfile.plugins ---
RUN printf "gem 'openproject-livesolutions', path: 'plugins/openproject-livesolutions'\ngem 'openproject-request-portal', path: 'plugins/openproject-request-portal'\n" \
    > /app/Gemfile.plugins \
    && chown app:app /app/Gemfile.plugins

# --- Phase 4: Bundle install (unlock deployment mode so new gems resolve) ---
USER root
RUN cd /app \
    && sed -i 's/^BUNDLE_DEPLOYMENT:/#BUNDLE_DEPLOYMENT:/' .bundle/config \
    && chown app:app .bundle/config \
    && su app -c "bundle install" \
    && sed -i 's/^#BUNDLE_DEPLOYMENT:/BUNDLE_DEPLOYMENT:/' .bundle/config \
    && chown app:app .bundle/config

# --- Phase 5: Cleanup git (not needed at runtime) ---
USER root
RUN apt-get purge -y --auto-remove git \
    && rm -rf /var/lib/apt/lists/*

# --- Phase 6: Ensure correct ownership of all app files ---
RUN chown -R app:app /app

USER app
