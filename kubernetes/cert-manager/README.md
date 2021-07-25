# cert-manager
Provisions HTTPS certs on the cluster for Ingress Controller to use.

Configured through Ingress records and their host value(s).

## Install
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

# modify acme-issuer-crd.yaml to your liking
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace -f cert-manager-values.yaml

# create your aws dns challenge creds
cp acme-issuer-aws-creds.yaml.template acme-issuer-aws-creds.yaml
kubectl apply -f acme-issuer-aws-creds.yaml --namespace cert-manager

# create the CRD configuration for the Cert Issuer with correct challenge type (eg. DNS01 + AWS Route53)
cp acme-issuer-crd.yaml.template acme-issuer-crd.yaml
kubectl apply -f acme-issuer-crd.yaml
```
