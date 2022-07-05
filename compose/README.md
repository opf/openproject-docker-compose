# OpenProject installation with Docker Compose

## Install

Clone this repository:

    git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/12 openproject

Go to the compose folder: 

    cd openproject/compose

Make sure you are using the latest version of the Docker images:

    docker-compose pull

Launch the containers:

    docker-compose up -d

After a while, OpenProject should be up and running on <http://localhost:8080>.

## Configuration

If you want to specify a different port, you can do so with:

    PORT=4000 docker-compose up -d

If you want to specify a custom tag for the OpenProject docker image, you can do so with:

    TAG=my-docker-tag docker-compose up -d

You can also set those variables into an `.env` file in your current working
directory, and Docker Compose will pick it up automatically. See `.env.example`
for details.

## Upgrade

Go to the compose folder:

    cd openproject/compose

Retrieve any changes from the `openproject-deploy` repository:

    git pull origin stable/12

Make sure you are using the latest version of the Docker images:

    docker-compose pull

Relaunch the containers:

    docker-compose up -d

## Uninstall

You can remove the stack with:

    docker-compose down

## Troubleshooting

You can look at the logs with:

    docker-compose logs -n 1000

For the complete documentation, please refer to https://docs.openproject.org/installation-and-operations/.

### Network issues

If you're running into weird network issues and timeouts such as the one described in [OP#42802](https://community.openproject.org/work_packages/42802), you might have success in remove the two separate frontend and backend networks. This might be connected to using podman for orchestration, although we haven't been able to confirm this.
