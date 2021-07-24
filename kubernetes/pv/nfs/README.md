# NFS Persistent Volume Provider
Followed https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

## Install through helm
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

# node00 (192.168.76.60) is the 'nfs server' as per the ansible configuration
# '/mnt/kube_default_pv' is the folder that all mounts will come from
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=192.168.76.60 \
  --set nfs.path=/mnt/kube_default_pv
```

## Installing Manually
### Clone the repo
```bash
$ git clone https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
$ cd nfs-subdir-external-provisioner/deploy/
```

### Deploy the RBAC account, role and bindings
```bash
# Deploy's into the 'default' namespace by default, change this if you want to target another NS
$ kubectl create -f rbac.yaml
```

### Update deployment.yaml with your NFS server and path
```bash
$ git diff deployment.yaml
diff --git a/deploy/deployment.yaml b/deploy/deployment.yaml
index 26d2a23..bd3e8a2 100644
--- a/deploy/deployment.yaml
+++ b/deploy/deployment.yaml
@@ -29,11 +29,11 @@ spec:
             - name: PROVISIONER_NAME
               value: k8s-sigs.io/nfs-subdir-external-provisioner
             - name: NFS_SERVER
-              value: 10.3.243.101
+              value: 192.168.76.60
             - name: NFS_PATH
-              value: /ifs/kubernetes
+              value: /mnt/kube_default_pv
       volumes:
         - name: nfs-client-root
           nfs:
-            server: 10.3.243.101
-            path: /ifs/kubernetes
+            server: 192.168.76.60
+            path: /mnt/kube_default_pv

$ kubectl create -f deployment.yaml
```

### Deploy class.yaml
This deploys a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) onto the cluster
```bash
$ kubectl create -f class.yaml
```

## Testing out Dynamic Persistant Volumes
### Create an example Claim and Pod to write to the Persistant Volume
The Claim will create a Persistant Volume Claim, which the deployed NFS integration will listen to and create a Dynamic Persistant Volume able to be used by the Pod
The Pod will wait until the Persistant Volume in its configuration is available to be used, write a success file, then exit
```bash
# This change was because the Helm Chart version sets the storage class name to 'nfs-client'
# The manually installed version retains the 'managed-nfs-storage' name
git diff test-claim.yaml
diff --git a/deploy/test-claim.yaml b/deploy/test-claim.yaml
index 72218eb..4715972 100644
--- a/deploy/test-claim.yaml
+++ b/deploy/test-claim.yaml
@@ -3,7 +3,7 @@ apiVersion: v1
 metadata:
   name: test-claim
 spec:
-  storageClassName: managed-nfs-storage
+  storageClassName: nfs-client
   accessModes:
     - ReadWriteMany
   resources:

# We need to make the below tweak as the default busybox image doesn't support ARM
git diff test-pod.yaml
diff --git a/deploy/test-pod.yaml b/deploy/test-pod.yaml
index e5e7b7f..69f558f 100644
--- a/deploy/test-pod.yaml
+++ b/deploy/test-pod.yaml
@@ -5,7 +5,7 @@ metadata:
 spec:
   containers:
   - name: test-pod
-    image: gcr.io/google_containers/busybox:1.24
+    image: library/busybox:1.33
     command:
       - "/bin/sh"
     args:

# Apply both the above files
kubectl create -f test-claim.yaml -f test-pod.yaml
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

# You will need to either SSH into node00 or the node the Pod was allocated to
$ ls -l /mnt/kube_default_pv/default-test-claim-pvc-90c04b0f-9edb-4d84-b41b-273a90b128ae/
total 0
-rw-r--r-- 1 root root 0 Jul 28 15:02 SUCCESS

# Delete the Pod & PVC
$ kubectl delete -f deploy/test-claim.yaml -f deploy/test-pod.yaml
persistentvolumeclaim "test-claim" deleted
pod "test-pod" deleted

# Verify the PVC & PV are both deleted in the Dashboard OR on the CLI
$ kubectl get pvc
No resources found.

$ kubectl get pv
No resources found.

# Verify the PV has been 'archived' on the NFS Server (node00)
# Note how it is prefixed with 'archived' now
$ ls -l /mnt/kube_default_pv
total 4
drwxrwxrwx 2 root root 4096 Jul 10 07:24 archived-default-test-claim-pvc-90c04b0f-9edb-4d84-b41b-273a90b128ae
```
