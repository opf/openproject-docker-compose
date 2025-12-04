FROM caddy:2

COPY ./Caddyfile.template /etc/caddy/Caddyfile

# We don't need sed anymore, Caddy handles {$VAR} natively
ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
