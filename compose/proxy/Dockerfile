FROM caddy:2

COPY ./Caddyfile.template /etc/caddy/Caddyfile.template

ARG APP_HOST
RUN sed 's|${APP_HOST}|'"$APP_HOST"'|g' /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile

ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
