# Kubernetes Dashboard

## Install the dashboard
```
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
# If you're running natively
kubectl proxy

# Our default 'kubectl' alias doesn't pass the 8001 port through, so here's one that does
docker run -it --rm -v ~/.kube:/.kube -v $(pwd):/pwd -w /pwd -p 8001:8001 bitnami/kubectl:1.21.3 proxy --address 0.0.0.0

# Navigate in your browser
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```
