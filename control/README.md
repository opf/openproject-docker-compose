# Control your OpenProject installation

## Backup

Switch off your current installation:
```shell
    docker-compose down
````
Build the control scripts:
```shell
    docker-compose -f docker-compose.yml -f docker-compose.control.yml build
```
Take a backup of your existing PostgreSQL data and OpenProject assets:
```shell
    docker-compose -f docker-compose.yml -f docker-compose.control.yml run backup
```
Restart your OpenProject installation
```shell
    docker-compose up -d
````
## Upgrade

Switch off your current installation (using the outdated postgres engine):
```shell
    docker-compose down
```
Fetch the latest changes from this repository:
```shell
    git pull origin stable/15 # adjust if needed
```
Build the control plane:
```shell
    docker-compose -f docker-compose.yml -f docker-compose.control.yml build
```
Take a backup of your existing postgresql data and openproject assets:
```shell
    docker-compose -f docker-compose.yml -f docker-compose.control.yml run backup
```
Run the upgrade:
```shell
    docker-compose -f docker-compose.yml -f docker-compose.control.yml run upgrade
```
Relaunch your OpenProject installation, using the normal Compose command:
```shell
    docker-compose up -d
```
Test that everything works again, the database container should now be running postgres 17.
