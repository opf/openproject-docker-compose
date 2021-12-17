#!/bin/bash
set -e
set -o pipefail

/control/upgrade/scripts/00-db-upgrade.sh

echo "Please restart your installation by issuing the following command:"
echo "  docker-compose up -d"
