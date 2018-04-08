# rpi-k8s-ansible

Raspberry PI's running Kubernetes deployed with Ansible

# Examples

## apt-get upgrade
`ansible -i cluster.yml upgrade.yml`

## rpi3b & rpi3bp overclocks
`ansible -i cluster.yml overclock-rpi3p.yml -l node00`
`ansible -i cluster.yml overclock-rpi3.yml -l node01`
`ansible -i cluster.yml overclock-rpi3.yml -l node02`
`ansible -i cluster.yml overclock-rpi3.yml -l node03`
`ansible -i cluster.yml overclock-rpi3.yml -l node04`

