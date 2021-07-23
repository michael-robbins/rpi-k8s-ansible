# Table of contents
- [Kubernetes with OIDC Authentication](oidc/)
- [Kubernetes Dashboard](dashboard/)
- [Helm 3](helm/)
- [Persistant Volumes Support](pv/)
- [MetalLB](metallb/)
- [Example HA Website](example_ha_website/)

# Misc
A lot of the commands in these subfolder run a command 'kctl', this is simply an alias to:
```
alias kctl='docker run -it --rm -v ~/.kube:/.kube -v $(pwd):/app bitnami/kubectl:1.21.3'
```

This is so the doco/etc doesn't have to constantly reference this docker run command all over the place.

We link in the $PWD to the `/app` folder so any README.md commands below this will use the `/app` folder to represent their directory.
