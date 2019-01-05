# Kubernetes Dashboard
```
# Applies the non-TLS version of kubernetes dashboard for ARM (rpi compatible)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/alternative/kubernetes-dashboard-arm.yaml

# Overrides the installed ServiceAccount with one with admin credentials
kubectl apply -f dashboard/admin-rbac.yaml

# Overrides the installed Service with a 'NodePort' service to expose this to the outside
kubectl apply -f dashboard/endpoint.yaml
```

You can now navigate to the dashboard from outside your cluster by finding the exposed NodePort high port
In the below example, the high port is 31648, and visiting the dashboard through: http://node-ip-address:31648/
```
$ kubectl get services --all-namespaces | grep kubernetes-dashboard
kube-system   kubernetes-dashboard   NodePort    10.97.125.254    <none>        80:31648/TCP    10m
```

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

# Example HA Web service
This example will create a, Ingress Controller, Service, Deployment and 5x Nginx pods that will print out the node name they are running on!

```
pi@node00:~ $ kubectl get pods
No resources found.
pi@node00:~ $ kubectl apply -f example_ha_website/web/ingress-controller-base.yaml
namespace "ingress-nginx" configured
deployment.extensions "default-http-backend" configured
service "default-http-backend" unchanged
configmap "nginx-configuration" unchanged
configmap "tcp-services" unchanged
configmap "udp-services" unchanged
serviceaccount "nginx-ingress-serviceaccount" unchanged
clusterrole.rbac.authorization.k8s.io "nginx-ingress-clusterrole" configured
role.rbac.authorization.k8s.io "nginx-ingress-role" unchanged
rolebinding.rbac.authorization.k8s.io "nginx-ingress-role-nisa-binding" unchanged
clusterrolebinding.rbac.authorization.k8s.io "nginx-ingress-clusterrole-nisa-binding" configured
deployment.extensions "nginx-ingress-controller" configured
pi@node00:~ $ kubectl apply -f example_ha_website/web/ingress-service-nodeport.yaml

pi@node00:~ $ kubectl apply -f example_ha_website/web/ingress-service-deployment-web.yaml
service "webserver-service" created
deployment.apps "webserver-deployment" created
pi@node00:~ $ kubectl get pods
NAME                                    READY     STATUS              RESTARTS   AGE
webserver-deployment-7c7948b97f-q9bpk   0/1       ContainerCreating   0          5s
webserver-deployment-7c7948b97f-s95tp   0/1       ContainerCreating   0          5s
webserver-deployment-7c7948b97f-tls8n   0/1       ContainerCreating   0          5s
pi@node00:~ $ kubectl get pods
NAME                                    READY     STATUS    RESTARTS   AGE
webserver-deployment-7c7948b97f-q9bpk   1/1       Running   0          28s
webserver-deployment-7c7948b97f-s95tp   1/1       Running   0          28s
webserver-deployment-7c7948b97f-tls8n   1/1       Running   0          28s
```

We can then simulate node failure by shutting down a node.
It took around 5 minutes for k8s to detect the node failure and respond by rescheudling the pod on another node.
Currently investigating how we can speed this up.
```
pi@node03:~ $ sudo shutdown -h now
Connection to 192.168.60.63 closed by remote host.
Connection to 192.168.60.63 closed.

pi@node00:~ $ kubectl get pods -o wide
NAME                                    READY     STATUS    RESTARTS   AGE       IP           NODE
webserver-deployment-7c7948b97f-q9bpk   1/1       Running   0          23m       10.244.1.4   node04
webserver-deployment-7c7948b97f-s95tp   1/1       Running   0          23m       10.244.4.6   node02
webserver-deployment-7c7948b97f-tls8n   1/1       Running   0          23m       10.244.3.6   node03

pi@node00:~ $ kubectl get nodes
NAME      STATUS     ROLES     AGE       VERSION
node00    Ready      master    2d        v1.10.1
node01    Ready      <none>    2d        v1.10.1
node02    Ready      <none>    2d        v1.10.1
node03    NotReady   <none>    2d        v1.10.1
node04    Ready      <none>    2d        v1.10.1

pi@node00:~ $ kubectl get node node03 --output=yaml
...
  - lastHeartbeatTime: 2018-04-27T12:28:19Z
    lastTransitionTime: 2018-04-27T12:29:01Z
    message: Kubelet stopped posting node status.
    reason: NodeStatusUnknown
    status: Unknown
    type: Ready
...

pi@node00:~ $ kubectl get deployment webserver-deployment --output=yaml
...
  - lastTransitionTime: 2018-04-27T12:29:01Z
    lastUpdateTime: 2018-04-27T12:29:01Z
    message: Deployment does not have minimum availability.
    reason: MinimumReplicasUnavailable
    status: "False"
    type: Available
  observedGeneration: 1
  readyReplicas: 2
  replicas: 3
  unavailableReplicas: 1
  updatedReplicas: 3
...

pi@node00:~ $ kubectl get pods -o wide
NAME                                    READY     STATUS    RESTARTS   AGE       IP           NODE
webserver-deployment-7c7948b97f-lld6r   1/1       Running   0          47s       10.244.2.4   node01
webserver-deployment-7c7948b97f-q9bpk   1/1       Running   0          27m       10.244.1.4   node04
webserver-deployment-7c7948b97f-s95tp   1/1       Running   0          27m       10.244.4.6   node02
webserver-deployment-7c7948b97f-tls8n   1/1       Unknown   0          27m       10.244.3.6
```
