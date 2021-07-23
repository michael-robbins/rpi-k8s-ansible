# Helm
Helm is a 'package manager' for kubernetes insofar as it will package and manage applications (charts) running on your
 cluster.

Each chart is made up of templates, which can be configured by the user through a config file (kinda similar to Ansible roles).

Helm 3 no longer needs anything installed on the cluster itself so it's purely client side.

## Docker Client
```bash
docker run -it --rm -v $(pwd):/apps -w /apps \
    -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm \
    -v ~/.config/helm:/root/.config/helm \
    -v ~/.cache/helm:/root/.cache/helm \
    alpine/helm:3.6.3
```

### Using an alias to make it easier
```
alias helm='docker run -it --rm -v $(pwd):/apps -w /apps -v ~/.kube:/root/.kube -v ~/.helm:/root/.helm -v ~/.config/helm:/root/.config/helm -v ~/.cache/helm:/root/.cache/helm alpine/helm:3.6.3'
```

## Bitnami Helm Charts
Currently they do not support ARM, but it might be coming soon (so is Christmas...)

See: https://github.com/bitnami/bitnami-docker-redis/issues/192

## Installing Helm charts
Helm charts don't generally work with arm unless they have multiarch support in the images (you'll need to verify this beforehand).

Here's a list of arm chart repo's you can add into Helm to mess with:
* https://github.com/peterhuene/arm-charts (just contains MariaDB)

```
# Install arm-charts as 'arm-stable'
helm repo add arm-stable https://peterhuene.github.io/arm-charts/stable
```

This is an example mariadb install

```
$ helm install arm-stable/mariadb
$ helm inspect arm-stable/mariadb

$ kubectl get secret --namespace default <release-name> -o jsonpath="{.data.mariadb-root-password}" | base64 --decode; echo

$ helm ls
NAME            REVISION        UPDATED                         STATUS          CHART           APP VERSION     NAMESPACE
knobby-quokka   1               Tue Jan 15 00:08:24 2019        DEPLOYED        mariadb-0.1.0   10.1.22         default

$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
knobby-quokka-mariadb-c76c6dbf4-n7qnz   1/1     Running   1          5m11s
```
