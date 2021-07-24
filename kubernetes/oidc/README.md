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
$ kubectl version
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

Create some RBAC roles binding the OIDC groups above to roles on the cluster:
```
kubectl apply -f viewer-clusterrolebinding.yml
kubectl apply -f admin-clusterrolebinding.yml
```

## Configure the client
There is a helper script available `oidc/setup_client.sh` that can be called like this:
```bash
./setup_client.sh KEYCLOAK_DOMAIN KEYCLOAK_REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD
```

If you want to manually perform the steps here is how you can do it:
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
kubectl config set-credentials admin-oidc \
    --auth-provider=oidc \
    --auth-provider-arg=idp-issuer-url=https://<KEYCLOAK_DOMAIN>/auth/realms/rpi-cluster \
    --auth-provider-arg=client-id=kubernetes \
    --auth-provider-arg=client-secret=12345678-abcd-1234-abcd-123456789101 \
    --auth-provider-arg=refresh-token=<REFRESH_TOKEN> \
    --auth-provider-arg=id-token=<ACCESS_TOKEN> \
    --auth-provider-arg=extra-scopes=groups

# Configure kubectl with the server
kubectl config set-cluster kubernetes --server=https://192.168.76.60:6443 --insecure-skip-tls-verify=true

# Create a default context and enable it
kubectl config set-context kubernetes --cluster=kubernetes --namespace=default --user=admin-oidc
kubectl config use-context kubernetes

# Verify its working
kubectl version
kubectl get nodes
```
