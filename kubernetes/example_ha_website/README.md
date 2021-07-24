# Example HA Web service
This example will create a, Ingress Controller, Service, Deployment and 5x Nginx pods that will print out the node name they are running on!

```
pi@node00:~ $ kubectl get pods
No resources found.
pi@node00:~ $ kubectl apply -f web/ingress-controller-base.yaml
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
pi@node00:~ $ kubectl apply -f web/ingress-service-nodeport.yaml

pi@node00:~ $ kubectl apply -f web/ingress-service-deployment-web.yaml
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
