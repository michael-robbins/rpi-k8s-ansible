# rpi-k8s-ansible
Raspberry PI's running Kubernetes deployed with Ansible

Master: rPi 3b+
Slaves: rPi 3b x4
CNI: Flannel (Weave support is there, but it crashes and reboot's the rPi's, see below)

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

## Updating cluster.yml to match your environment
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
With the below commands, you need to include the master node (node00) in all executions for the token to be set correctly.
```
# Bootstrap the master and all slaves
ansible-playbook -i cluster.yml site.yml

# Bootstrap a single slave (node05)
ansible-playbook -i cluster.yml site.yml -l node00,node05

# When running again, feel free to ignore the common tag as this will reboot the rpi's
ansible-playbook -i cluster.yml site.yml --skip-tags common
```

Using Weave as the k8s CNI resulted in quite a few kernel oops and the rPi's rebooting:
```
pi@node00:~ $ kubectl nodes get
 kernel:[  152.913108] Internal error: Oops: 80000007 [#1] SMP ARM
 kernel:[  152.928828] Process weaver (pid: 4515, stack limit = 0x90266210)
 kernel:[  152.929514] Stack: (0x902679f0 to 0x90268000)
 kernel:[  152.930180] 79e0:                                     00000000 00000000 3d3aa8c0 90267a88
 kernel:[  152.931470] 7a00: 0000801a 0000cbb6 a8b538d0 a8b53898 90267d2c 7f75ead0 00000001 90267a5c
```

See https://gist.github.com/alexellis/fdbc90de7691a1b9edb545c17da2d975 for more discussion.

Instead I've decided to move to Flannel, which is working nicely so far.

# Running stuff on the cluster!
## Example HA web service
This example will create a Service, Deployment and 3x Nginx pods that will print out the node name they are running on!
```
pi@node00:~ $ kubectl get pods
No resources found.
pi@node00:~ $ kubectl apply -f https://raw.githubusercontent.com/michael-robbins/rpi-k8s-ansible/master/pods/example_ha_website/web/service-deployment-web.yaml
service "webserver-service" created
deployment.apps "webserver-deployment" created
pi@node00:~ $ kubectl get pods
NAME                                    READY     STATUS              RESTARTS   AGE
webserver-deployment-7c7948b97f-q9bpk   0/1       ContainerCreating   0          5s
webserver-deployment-7c7948b97f-s95tp   0/1       ContainerCreating   0          5s
webserver-deployment-7c7948b97f-tls8n   0/1       ContainerCreating   0          5s
pi@node00:~ $ kubectl get pods
NAME                                    READY     STATUS    RESTARTS   AGE
webserver-deployment-7c7948b97f-q9bpk   1/1       Running   0          28s
webserver-deployment-7c7948b97f-s95tp   1/1       Running   0          28s
webserver-deployment-7c7948b97f-tls8n   1/1       Running   0          28s
```
