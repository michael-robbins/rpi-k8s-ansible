# Cluster OIDC Authentication with Keycloak
Roughly following these sites:
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens
- https://docs.kublr.com/articles/oidc/
- https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

Need to try out:
- https://www.talkingquickly.co.uk/setting-up-oidc-login-kubernetes-kubectl-with-keycloak
- https://github.com/int128/kubelogin

## Setup Keycloak
1. Create 2 groups 'kubernetes-admin' and 'kubernetes-viewer'
2. Create a user and set a password
3. Assign the user to the 'kubernetes-admin' group
4. Create a new realm (eg. rpi-cluster)
5. Create a client (eg. kubernetes)
    1. Set it to Confidential
    2. Record the client secret (eg. 12345678-abcd-1234-abcd-123456789101)
    3. Create a new mapper
        1. Name: 'user_groups'
        2. Mapper Type: 'Group Membership'
        3. Token Claim Name: 'user_groups'
        4. Full group path: OFF
    4. Create a new mapper
        1. Name: 'override-audience'
        2. Mapper Type: 'Audience'
        3. Included Client Audience: 'kubernetes' (same as client name)
        4. Add to ID token: ON

The second mapper from above came from trying to run 'kubectl version' from the steps further down:
```
$ docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 version
Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.2", GitCommit:"092fbfbf53427de67cac1e9fa54aaa09a28371d7", GitTreeState:"clean", BuildDate:"2021-06-16T12:59:11Z", GoVersion:"go1.16.5", Compiler:"gc", Platform:"linux/amd64"}
error: You must be logged in to the server (the server has asked for the client to provide credentials)

# Looking at the kube-apiserver logs
2021-06-27T16:03:00.35346176+01:00 stderr F E0627 15:03:00.353124       1 authentication.go:63] "Unable to authenticate the request" err="[invalid bearer token, oidc: verify token: oidc: expected audience \"kubernetes\" got [\"account\"]]"

# Googling around found this, which lead to creating the second mapper
https://stackoverflow.com/questions/53550321/keycloak-gatekeeper-aud-claim-and-client-id-do-not-match
```

## Setup Kubernetes
Because we setup our cluster bootstrapped through kubeadm, the apiserver is defined through a file on the master node.

Modify `/etc/kubernetes/manifests/kube-apiserver.yaml` and set the following:
```
Under spec.containers[name=kube-apiserver].command
Append:
    - --oidc-issuer-url=https://<KEYCLOAK_DOMAIN>/auth/realms/rpi-cluster
    - --oidc-client-id=kubernetes
    - --oidc-username-claim=preferred_username
    - --oidc-groups-claim=user_groups

Kubernetes will restart the kube-apiserver pod automatically
```

Create some RBAC roles binding the OIDC groups to roles on the cluster:
```
cat <<EOF | kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: oidc-kubernetes-admin
subjects:
- kind: Group
  name: kubernetes-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: oidc-kubernetes-viewer
subjects:
- kind: Group
  name: kubernetes-viewer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Configure the client
```
# Get an access_token and refresh_token
curl \
    -d "grant_type=password" \
    -d "client_id=kubernetes" \
    -d "client_secret=12345678-abcd-1234-abcd-123456789101" \
    -d "username=<USERNAME>" \
    -d "password=<PASSWORD>" \
    https://<KEYCLOAK_DOMAIN>/auth/realms/rpi-cluster/protocol/openid-connect/token | jq

# (Optionally) Review your ID token
curl \
    --user "kubernetes:<CLIENT_SECRET>" \
    -d "token=<ACCESS_TOKEN>" \
    https://<KEYCLOAK_DOMAIN>/auth/realms/rpi-cluster/protocol/openid-connect/token/introspect | jq

# Configure kubectl with the user
docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 config set-credentials admin-oidc \
    --auth-provider=oidc \
    --auth-provider-arg=idp-issuer-url=https://<KEYCLOAK_DOMAIN>/auth/realms/rpi-cluster \
    --auth-provider-arg=client-id=kubernetes \
    --auth-provider-arg=client-secret=12345678-abcd-1234-abcd-123456789101 \
    --auth-provider-arg=refresh-token=<REFRESH_TOKEN> \
    --auth-provider-arg=id-token=<ACCESS_TOKEN> \
    --auth-provider-arg=extra-scopes=groups

# Configure kubectl with the server
docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 config set-cluster kubernetes --server=https://192.168.76.60:6443 --insecure-skip-tls-verify=true

# Create a default context and enable it
docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 config set-context kubernetes --cluster=kubernetes --namespace=default --user=admin-oidc
docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 config use-context kubernetes

# Verify its working
docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 version
docker run -it --rm --name kubectl -v ~/.kube:/.kube bitnami/kubectl:1.21.2 get nodes
```

# Kubernetes Dashboard
```
# Non TLS version
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/alternative.yaml

# TLS version (requires a few extra steps, check https://github.com/kubernetes/dashboard)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml

# Overrides the installed ServiceAccount with one with admin credentials
kubectl delete -f dashboard/admin-rbac.yaml
kubectl apply -f dashboard/admin-rbac.yaml
```

You will now need to get the 'kubernetes-dashboard' service accounts token. This will let you login to the cluster.
```
kubectl get secrets -n kubernetes-dashboard -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='kubernetes-dashboard')].data.token}" | base64 --decode; echo
```

Proxy the dashboard to your local computer and login with the above token
```
kubectl proxy

# Non TLS version
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/

# TLS version
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

# Helm
A number of the examples below use and require Helm. It can be installed from here: https://github.com/helm/helm/releases

## Installing the helm binary
The ansible bootstrapping here will configure your ~/.kube/config file that allows cluster access!
If you're downloading onto the rpi directly to run, you'll need to compile it yourself or find a prebuilt ARMv7 binary.
See https://github.com/peterhuene/arm-charts/blob/master/README.md for context around building this yourself.

```
# Linux amd64
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.14.1-linux-amd64.tar.gz
tar xzf helm-v2.14.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
sudo mv linux-amd64/tiller /usr/local/bin/
rm -rf linux-amd64

# Mac amd64
brew install kubernetes-helm
```

## Installing helm onto the cluster
This is actually installing 'tiller' onto the Kubernetes cluster itself. This is what helm (the client binary) interacts with.
```
# This creates the RBAC ServiceAccount for tiller, binding it to the 'cluster-admin' role, giving it full permissions over the cluster
kubectl create -f helm/rbac-configuration.yaml

# This installs tiller into the kube-system namespace, using kubernetes secrets for config management and the 'tiller' ServiceAccount for RBAC
helm init --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' --service-account=tiller --tiller-image=jessestuart/tiller:v2.14.1
```

Note: The above 'helm init' command is pinned to v2.12.1 as per the above helm download and copy, once helm get off their butts and produce proper arm images we can remove the '--tiller-image' flag

A good example of a multiarch docker image build is https://github.com/jessestuart/tiller-multiarch/blob/master/.circleci/config.yml

## Setting up a Persistent Volume (PV)
We apply a PV for our NFS share we setup as part of the Ansible bootstrap, it needs to match the PVC request configuration for the PVC to be successful.
The below nfs-pv-mariadb.yaml applies a ReadWriteOnce PV with 8GB space, matching the expected PVC response.
```
# Apply the MariaDB specific PV
kubectl apply -f pv/nfs-pv-mariadb.yaml
```

## Setting up Dynamic Persistent Volumes through NFS
Followed https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client

### Clone the repo
```
git clone https://github.com/kubernetes-incubator/external-storage.git
cd external-storage/nfs-client/
```

### Deploy the RBAC account, role and bindings
```
# Deploy's into the 'default' namespace by default ;)
# Edit as you see fit
kubectl create -f deploy/rbac.yaml
```

### Update deploy/deployment-arm.yaml with your NFS settings
```
git diff deploy/deployment-arm.yaml
diff --git a/nfs-client/deploy/deployment-arm.yaml b/nfs-client/deploy/deployment-arm.yaml
index feef4efc..48d19876 100644
--- a/nfs-client/deploy/deployment-arm.yaml
+++ b/nfs-client/deploy/deployment-arm.yaml
@@ -25,13 +25,13 @@ spec:
               mountPath: /persistentvolumes
           env:
             - name: PROVISIONER_NAME
-              value: fuseim.pri/ifs
+              value: cluster-storage
             - name: NFS_SERVER
-              value: 10.10.10.60
+              value: 192.168.60.60
             - name: NFS_PATH
-              value: /ifs/kubernetes
+              value: /mnt/kube_default_pv
       volumes:
         - name: nfs-client-root
           nfs:
-            server: 10.10.10.60
-            path: /ifs/kubernetes
+            server: 192.168.60.60
+            path: /mnt/kube_default_pv

kubectl create -f deploy/deployment-arm.yaml
```

### Update deploy/class.yaml
```
git diff deploy/class.yaml
diff --git a/nfs-client/deploy/class.yaml b/nfs-client/deploy/class.yaml
index 4d3b4805..4415cc68 100644
--- a/nfs-client/deploy/class.yaml
+++ b/nfs-client/deploy/class.yaml
@@ -2,6 +2,6 @@ apiVersion: storage.k8s.io/v1
 kind: StorageClass
 metadata:
   name: managed-nfs-storage
-provisioner: fuseim.pri/ifs # or choose another name, must match deployment's env PROVISIONER_NAME'
+provisioner: cluster-storage
 parameters:
   archiveOnDelete: "false"

kubectl create -f deploy/class.yaml
```

### Test the dynamic PV with a PVC & Pod
Ensure you update below to support rpi's
```
git diff deploy/test-pod.yaml
diff --git a/nfs-client/deploy/test-pod.yaml b/nfs-client/deploy/test-pod.yaml
index e5e7b7fe..cbd29b90 100644
--- a/nfs-client/deploy/test-pod.yaml
+++ b/nfs-client/deploy/test-pod.yaml
@@ -5,7 +5,7 @@ metadata:
 spec:
   containers:
   - name: test-pod
-    image: gcr.io/google_containers/busybox:1.24
+    image: armhf/busybox:1.24
     command:
       - "/bin/sh"
     args:

kubectl create -f deploy/test-claim.yaml -f deploy/test-pod.yaml
```

### Verify a PV and PVC exist in the Dashboard OR on the CLI
```
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS
         REASON   AGE
pvc-90c04b0f-9edb-4d84-b41b-273a90b128ae   1Mi        RWX            Delete           Bound    default/test-claim   managed-nfs-storage            2m

$ kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
test-claim   Bound    pvc-90c04b0f-9edb-4d84-b41b-273a90b128ae   1Mi        RWX            managed-nfs-storage   99s
```

### Verify a Pod is created and the NFS server has the SUCCESS file written
```
$ kubectl get pod test-pod
NAME       READY   STATUS      RESTARTS   AGE
test-pod   0/1     Completed   0          2m22s

$ ls -l /mnt/kube_default_pv/default-test-claim-pvc-90c04b0f-9edb-4d84-b41b-273a90b128ae/
total 0
-rw-r--r-- 1 root root 0 Jul 28 15:02 SUCCESS

# Delete the Pod & PVC
kubectl delete -f deploy/test-claim.yaml -f deploy/test-pod.yaml

# Verify the PVC & PV are both deleted in the Dashboard OR on the CLI
$ kubectl get pvc
No resources found.

$ kubectl get pv
No resources found.
```

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

# Installing Istio
WARNING: Istio currently doesn't have any ARM images available

## Download and unzip istio
```
cd istio
wget https://github.com/istio/istio/releases/download/1.2.2/istio-1.2.2-linux.tar.gz
tar xzf istio-1.2.2-linux.tar.gz
cd istio-1.2.2
```

## Install istio
```
pushd install/kubernetes/helm/istio-init/files/
for i in *.yaml; do kubectl apply -f $i; done
popd

# The below should return a bunch of stuff
kubectl get crd

# Apply permissive demo
pushd install/kubernetes/
kubectl apply -f istio-demo.yaml
popd
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
