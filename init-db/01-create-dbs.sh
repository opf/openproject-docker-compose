#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE mattermost;
    CREATE DATABASE wiki;
    GRANT ALL PRIVILEGES ON DATABASE mattermost TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE wiki TO postgres;
EOSQL
