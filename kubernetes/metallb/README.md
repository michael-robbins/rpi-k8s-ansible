# MetalLB
Provides a LoadBalancer type in Kubernetes emulating similar Cloud offerings like NLB's within AWS

We setup MetalLB in 'layer 2 mode' for simplicity, but the only concern here is all traffic will flow through the single ingress node, this isn't *really* an issue given we're talking about Raspberry Pi's here.

## Prerequisites
```bash
# Enable promiscuous mode on all wlan interfaces
# Otherwise the routers ARP requests will not make it through to MetalLB's ARP responder
# See: https://github.com/metallb/metallb/issues/253

ansible-playbook -i cluster.yml playbooks/wlan-promisc.yml
```

## Installation
Pretty much followed the guide at https://metallb.universe.tf/installation/

### kubectl
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
kubectl apply -f kubectl-configmap.yaml
```

### Helm
```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -f helm-configmap.yaml
```

## Testing
Deploy an nginx ingress controller
```bash
kubectl apply -f nginx-ingress.yaml
```
