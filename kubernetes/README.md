# Table of contents
- [Kubernetes with OIDC Authentication](oidc/)
- [Kubernetes Dashboard](dashboard/)
- [Helm 3](helm/)
- [MetalLB](metallb/)
- [Cert Manager](cert-manager/)
- [Ingress Controller](ingress-controller/)
- [Persistant Volumes Providers](pv/)
- [Gitea](gitea/)
- [Example HA Website](example_ha_website/)

# Misc
## kubectl
This is to pin your local 'kubectl' to the version on the cluster, you can ignore this if you know what you're doing.

We link in the $PWD to the `/pwd` folder and make it the WORKDIR so all commands inside the container still appear 'relative' to the current PWD outside the container.
```
alias kubectl='docker run -it --rm -v ~/.kube:/.kube -v $(pwd):/pwd -w /pwd bitnami/kubectl:1.21.3'
```

## helm3
THis is to pin your local 'helm' to the latest verified version, you can ignore this if you know what you're doing.

We link in the $PWD to the `/pwd` folder and make it the WORKDIR so all commands inside the container still appear 'relative' to the current PWD outline the container.
```
alias helm='docker run -it --rm -v $(pwd):/pwd -w /pwd -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm -v ~/.config/helm:/root/.config/helm -v ~/.cache/helm:/root/.cache/helm alpine/helm:3.6.3'
```
