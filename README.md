# rpi-k8s-ansible
Raspberry PI's running Kubernetes deployed with Ansible

# Examples

## apt-get upgrade
```
ansible-playbook -i cluster.yml upgrade.yml
```

## rpi3b & rpi3bp overclocks
```
ansible-playbook -i cluster.yml overclock-rpi3p.yml -l node00
ansible-playbook -i cluster.yml overclock-rpi3.yml -l node01
ansible-playbook -i cluster.yml overclock-rpi3.yml -l node02
ansible-playbook -i cluster.yml overclock-rpi3.yml -l node03
ansible-playbook -i cluster.yml overclock-rpi3.yml -l node04
```

## Bootstrap k8s master
```
ansible-playbook -i cluster.yml site.yml -l node00
```
