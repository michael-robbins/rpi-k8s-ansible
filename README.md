# rpi-k8s-ansible
Raspberry PI's running Kubernetes deployed with Ansible

## Preparing an SD card
```
# Write the image to the SD card, please use at least 2018-04-18 if you want to use WiFi
$ sudo dd if=YYYY-MM-DD-raspbian-stretch-lite.img of=/dev/sdX bs=16M status=progress

# Provision wifi settings on first boot
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
```

```
Example flash and ssh/wifi:
sudo umount /media/<user>/boot
sudo umount /media/<user>/rootfs
sudo dd if=2018-04-18-raspbian-stretch-lite.img of=/dev/<disk> bs=16M status=progress
sync

# Unplug/replug SD card

cp wpa_supplicant.conf /media/<user>/boot/
touch /media/<user>/boot/ssh
sync
sudo umount /media/<user>/boot
sudo umount /media/<user>/rootfs

```

## Updating cluster.yml
This is where there individual rPi's are set to be a master or a slave.
I have not changed any passwords or configured SSH keys as this cannot be easily done with a headless rPi setup.
I am currently using DHCP static assignment to ensure each PI's MAC address is given the same IP address.
Update the file as required for your specific setup.

# Example Playbooks
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

## Install k8s
```
# Bootstrap the master and all slaves
ansible-playbook -i cluster.yml site.yml

# When running again, feel free to ignore the common tag as this will reboot the rpi's
ansible-playbook -i cluster.yml site.yml --skip-tags common
```
