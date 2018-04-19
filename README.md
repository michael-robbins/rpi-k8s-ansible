# rpi-k8s-ansible
Raspberry PI's running Kubernetes deployed with Ansible

## Preparing an SD card
```
# Write the image to the SD card
$ sudo dd if=YYYY-MM-DD-raspbian-stretch-lite.img of=/dev/sdX bs=16M status=progress

# Provision wifi settings
$ cat wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=AU

network={
    ssid=""
    psk=""
    key_mgmt=WPA-PSK
}

$ cp wpa_supplicant.conf /mnt/boot/

# Enable SSH on first boot
$ touch /mnt/boot/ssh

# Disable the Wifi country rfkill script (source: https://www.raspberrypi.org/forums/viewtopic.php?t=209226)
$ sudo mv /mnt/rootfs/usr/lib/raspberrypi-sys-mods/wifi-country /mnt/rootfs/usr/lib/raspberrypi-sys-mods/wifi-country+
```

# Examples
## apt-get upgrade
```
ansible-playbook -i cluster.yml playbooks/upgrade.yml
```

## rpi3b & rpi3bp overclocks
```
# Node 00 is an rpi3b+ for me
ansible-playbook -i cluster.yml playbooks/overclock-rpi3p.yml -l node00

# The rest of the nodes are all rpi3b's
ansible-playbook -i cluster.yml playbooks/overclock-rpi3.yml -l 'all:!node00'
```

## Bootstrap k8s master
```
ansible-playbook -i cluster.yml site.yml -l node00
```
