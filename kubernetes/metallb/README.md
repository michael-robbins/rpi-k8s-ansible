Pretty much followed the tutorial at: https://metallb.universe.tf/tutorial/layer2/

```
# Enable promiscuous mode on all wlan interfaces
# Otherwise the routers ARP requests will not make it through to MetalLB's ARP responder
# See: https://github.com/google/metallb/issues/253

ansible-playbook -i cluster.yml playbooks/wlan-promisc.yml


# Apply the configs

kubectl apply -f https://raw.githubusercontent.com/danderson/metallb/v0.8.1/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/michael-robbins/rpi-k8s-ansible/master/kubernetes/metallb/layer2-config.yaml
kubectl apply -f https://raw.githubusercontent.com/michael-robbins/rpi-k8s-ansible/master/kubernetes/metallb/nginx-lb.yaml
```

Only tweaks were:
1. Updating layer2-config.yml with my local LAN range allocated to MetalLB
2. Debugging the above wlan promiscuous mode stuff, local ARP resolution on the rpi cluster was fine, but from the local LAN it wasn't working
