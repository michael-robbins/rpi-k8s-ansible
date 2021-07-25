# NGINX Ingress Controller
Assumptions:
* MetalLB or similar here to support creating a 'LoadBalancer' type Service
* cert-manager or similar here to provision TLS/HTTPS certificates

The ingress contoller will be created and MetalLB will provide the 'ExternalIP'.

See https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#a-pure-software-solution-metallb for some context about this.

## Install
### Kubectl
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx
```
