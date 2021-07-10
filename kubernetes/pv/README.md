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
