# OpenProject installation using Kubernetes

This is an example setup of OpenProject on Kubernetes.

## Install

Clone this repository:

```
git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/12 openproject
```

Go to the compose folder:

```
cd openproject/kubernetes
```

Adjust the host name for the ingress in [09-proxy-ingress.yaml](./09-proxy-ingress.yaml).
The default value `k8s.openproject-dev.com` simply points to `127.0.0.1`.
You will have to insert the actual host name here and set up the DNS so that it points to the cluster IP.

Next, apply the definitions:

```
kubectl apply -f .
```

## Ingress

For the ingress to work you will need to enable an ingress addon in your cluster.

If you already have a load balancer you want to use to expose the service,
simply delete [09-proxy-ingress.yaml](./09-proxy-ingress.yaml) and integrate
the [proxy service](./08-proxy-service.yaml) in your existing ingress or load balancer.

## SSL Termination

This setup does not include SSL termination.
The ingress simply listens on port 80 and serves HTTP requests.

You will have to set up HTTPS yourself.
You can find more information on this in the [kubernetes docs](https://kubernetes.github.io/ingress-nginx/user-guide/tls/).

## Scaling

You can adjust the `replica` specs in the [web](./05-web-deployment.yaml) and [worker](./05-worker-deployment.yaml) deployments
to scale up the respective processes.

## TROUBLESHOOTING

### The **db** deployment fails due to the data directory not being empty

This can happen if your cluster creates the `opdata` PVC (persistent volume claims) with an ext4 file system
which will automatically have a `lost+found` folder.

To fix the issue you can add the following to the [db-deployment](./02-db-deployment.yaml)'s env next to
`POSTGRES_USER` and `POSTGRES_PASSWORD`:

```
- name: PGDATA
  value: /var/lib/postgresql/data/pgdata
```

This makes the postgres container use a subfolder of the mount path (`/var/lib/postgresql/data`) as the data directory.
