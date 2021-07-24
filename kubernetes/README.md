# Table of contents
- [Kubernetes with OIDC Authentication](oidc/)
- [Kubernetes Dashboard](dashboard/)
- [Helm 3](helm/)
- [Persistant Volumes Support](pv/)
- [MetalLB](metallb/)
- [Example HA Website](example_ha_website/)

# Misc
This is to pin your local 'kubectl' to the version on the cluster, you can ignore this if you know what you're doing.

We link in the $PWD to the `/pwd` folder and make it the WORKDIR so all commands inside the container still appear 'relative' to the current PWD outside the container.
```
alias kubectl='docker run -it --rm -v ~/.kube:/.kube -v $(pwd):/pwd -w /pwd bitnami/kubectl:1.21.3'
```

