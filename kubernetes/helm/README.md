# Helm
Helm is a 'package manager' for kubernetes insofar as it will package and manage applications (charts) running on your
 cluster.

Each chart is made up of templates, which can be configured by the user through a config file (kinda similar to Ansible roles).

Helm 3 no longer needs anything installed on the cluster itself so it's purely client side.

## Docker
```bash
docker run -it --rm -v $(pwd):/apps -w /apps \
    -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm \
    -v ~/.config/helm:/root/.config/helm \
    -v ~/.cache/helm:/root/.cache/helm \
    alpine/helm:3.6.2
```
