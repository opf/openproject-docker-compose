# OpenProject installation Kubernetes

## Install

Clone this repository:

    git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/12 openproject

Go to the compose folder:

    cd openproject/k8

And there are the resources needed to run openproject in kubernetes.

You can apply all the `yaml` files. It was tested using flux to apply all the resources.

It was tested with a nginx serving as proxy pass to the cluster

## Configuration

Change the ingress host value in the file `web-deployment.yaml`
