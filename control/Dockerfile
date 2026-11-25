FROM postgres:17-bookworm

# Install rsync and compression tools useful for upgrade/restore, plus any PG
# client version we might need if we ever have to convert PG 13 -> 17 in-place.
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
       rsync wget ca-certificates locales \
    && rm -rf /var/lib/apt/lists/*

# Keep the same locale the upstream Postgres image already sets.
ENV LANG en_US.utf8

ADD . /control
