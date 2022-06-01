# Accessing OpenProject

If the minikube tunnel doesn't work, find out the used OpenProject port via

```
kubectl --context minikube get services
```

and then open the tunnel yourself via

```
ssh -i $(minikube ssh-key) docker@localhost -p 60390 -L 8080:localhost:30265
```

to be able to access OpenProject under http://localhost:8080.

60390 would be the minikube container's mapped ssh port which you can see via `docker ps`.
