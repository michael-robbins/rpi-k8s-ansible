# Gitea
A simple Git web management interface and Git server

## Install
https://docs.gitea.io/en-us/install-on-kubernetes/

```bash
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update

kubectl create namespace gitea

# cp gitea-secret.yaml.template gitea-secret.yaml
# Modify gitea-secret.yaml and set a username and password
kubectl apply -f gitea-secret.yaml

helm --namespace gitea install gitea gitea-charts/gitea -f gitea-values.yaml
```
