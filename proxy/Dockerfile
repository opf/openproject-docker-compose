ARG TAG=17-slim
FROM openproject/openproject:${TAG} AS openproject

FROM caddy:2

COPY --from=openproject /app/public/assets /srv/assets
COPY ./Caddyfile.template /etc/caddy/Caddyfile.template

ARG APP_HOST
RUN sed 's|${APP_HOST}|'"$APP_HOST"'|g' /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile

ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
