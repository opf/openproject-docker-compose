# Control your OpenProject installation

## Backup

Switch off your current installation:

    docker-compose down

Build the control scripts:

    docker-compose -f docker-compose.yml -f docker-compose.control.yml build

Take a backup of your existing PostgreSQL data and OpenProject assets:

    docker-compose -f docker-compose.yml -f docker-compose.control.yml run backup

Restart your OpenProject installation

    docker-compose up -d

## Upgrade

Switch off your current installation (using the outdated postgres engine):

    docker-compose down

Fetch the latest changes from this repository:

    git pull origin stable/12 # adjust if needed

Build the control plane:

    docker-compose -f docker-compose.yml -f docker-compose.control.yml build

Take a backup of your existing postgresql data and openproject assets:

    docker-compose -f docker-compose.yml -f docker-compose.control.yml run backup

Run the upgrade:

    docker-compose -f docker-compose.yml -f docker-compose.control.yml run upgrade

Relaunch your OpenProject installation, using the normal Compose command:

    docker-compose up -d

Test that everything works again, the database container should now be running postgres 13.
