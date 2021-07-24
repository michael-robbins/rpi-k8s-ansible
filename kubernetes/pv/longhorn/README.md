# Longhorn Persistent Volume Provider

## Install
Only support arm64 so you need to be running the RaspiOS 64bit release (linux/arm64)

### Helm
```
helm repo add longhorn https://charts.longhorn.io
helm repo update

kubectl create namespace longhorn-system
helm install longhorn longhorn/longhorn --namespace longhorn-system
```

Confirm if it's working:
```
kubectl -n longhorn-system get pods
```

It will 'settle down' after some minutes, you'll see a bunch of pods called 'csi-xyz' all get created.

## Configure UI
We assume you've setup MetalLB or similar here.

Create the nginx ingress controller, we use 'cloud' because it uses a LoadBalancer type of Service and not NodePort.

LoadBalancer Service will interact with MetalLB and be given an external IP to use!

See https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#a-pure-software-solution-metallb for some context about this
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/cloud/deploy.yaml
```

Create the login details:
```bash
$ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
$ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
```

Apply the Ingress
```bash
# Create the ingress
kubectl -n longhorn-system apply -f longhorn-ingress.yaml

# Verify its 'Address' shows an External IP
kubectl -n longhorn-system get ingress
```

You can then navigate to `http://<external ip>` and you should get a Basic Auth prompt, enter your credentials from above and you will get the Longhorn UI
