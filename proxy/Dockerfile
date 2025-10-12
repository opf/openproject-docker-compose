FROM caddy:2

COPY ./Caddyfile.template /etc/caddy/Caddyfile.template

ARG APP_HOST
ARG HOCUSPOCUS_HOST
RUN sed -e 's|${APP_HOST}|'"$APP_HOST"'|g' \
        -e 's|${HOCUSPOCUS_HOST}|'"$HOCUSPOCUS_HOST"'|g' \
    /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile

ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
