# Helm
A number of the examples below use and require Helm. It can be installed from here: https://github.com/helm/helm/releases

## Installing the helm binary
This is for an amd64 CPU, the ansible bootstrapping here will configure your ~/.kube/config file that allows cluster access!
If you're downloading onto the rpi directly to run, you'll need to compile it yourself or find a prebuilt ARMv7 binary.
See https://github.com/peterhuene/arm-charts/blob/master/README.md for context around building this yourself.

```
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz
unzip helm-v2.12.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
sudo mv linux-amd64/tiller /usr/local/bin/
rm -rf linux-amd64
```

## Installing helm onto the cluster
This is actually installing 'tiller' onto the Kubernetes cluster itself. This is what helm (the client binary) interacts with.
```
# This creates the RBAC ServiceAccount for tiller, binding it to the 'cluster-admin' role, giving it full permissions over the cluster
kubectl create -f helm/rbac-configuration.yaml

# This installs tiller into the kube-system namespace, using kubernetes secrets for config management and the 'tiller' ServiceAccount for RBAC
helm init --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' --service-account=tiller --tiller-image=jessestuart/tiller:v2.12.1
```

Note: The above 'helm init' command is pinned to v2.12.1 as per the above helm download and copy, once helm get off their butts and produce proper arm images we can remove the '--tiller-image' flag

A good example of a multiarch docker image build is https://github.com/jessestuart/tiller-multiarch/blob/master/.circleci/config.yml

## Installing Helm charts
Helm charts don't generally work with arm unless they have multiarch support in the images (you'll need to verify this beforehand).

Here's a list of arm chart repo's you can add into Helm to mess with:
* https://github.com/peterhuene/arm-charts

This is an example mysql install (ripped straight from the quickstart guide https://docs.helm.sh/using\_helm/#quickstart-guide)

```
$ helm install stable/mysql
$ helm inspect stable/mysql

$ kubectl get secret --namespace default <release-name> -o jsonpath="{.data.mysql-root-password}" | base64 --decode; echo

$ helm ls
NAME                    REVISION        UPDATED                         STATUS          CHART           APP VERSION
        NAMESPACE
exacerbated-eagle       1               Fri Jan  4 23:35:26 2019        DEPLOYED        mysql-0.12.0    5.7.14
        default

```
