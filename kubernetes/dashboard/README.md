# Kubernetes Dashboard

## Install the dashboard
```
# Non TLS version
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/alternative.yaml

# TLS version (requires a few extra steps, check https://github.com/kubernetes/dashboard)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
```

## (Optional) Configure cluster-wide permissions
Overrides the installed ServiceAccount with one with admin credentials, never expose your cluster publically with this
```
kubectl delete -f admin-rbac.yaml
kubectl apply -f admin-rbac.yaml
```

You will now need to get the 'kubernetes-dashboard' service accounts token. This will let you login to the cluster.
```
kubectl get secrets -n kubernetes-dashboard -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='kubernetes-dashboard')].data.token}" | base64 --decode; echo
```

Proxy the dashboard to your local computer and login with the above token
```
kubectl proxy

# If you're running kubectl in docker, need to listen on 0.0.0.0
kubectl proxy --address 0.0.0.0

# Non TLS version
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/

# TLS version
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```
