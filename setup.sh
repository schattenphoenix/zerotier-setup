#!/bin/bash

# Test for id entered
if [[ -z "$1" ]]; then
    echo "Please add the container id as first parameter."
    exit 1
fi

# Test for network entered
if [[ -z "$2" ]]; then
    echo "Please enter the network ID as the second parameter."
    exit 1
fi

# Get debian template
TEMPLATE="/var/lib/vz/template/cache/$(ls /var/lib/vz/template/cache/ | grep debian | head -n 1)"

# Create container
pct create $1 $TEMPLATE --ostype debian --hostname zerotier --memory 256 --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp --storage localblock --rootfs local-lvm:2 --cores 1 --start 1

# Prepare config path
LXC_CONFIG="/etc/pve/lxc/$1.conf"
# LXC_CONFIG="./Test$1.conf"

# Append to container config
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> $LXC_CONFIG
echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> $LXC_CONFIG

# Pull files from git
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_setup.sh -o container_setup.sh
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_startup.sh -o container_startup.sh
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_startup.service -o container_startup.service

# Push files to container
pct push $1 container_setup.sh ~/setup.sh
pct push $1 container_startup.sh /usr/local/bin/startup.sh
pct push $1 container_startup.service /etc/systemd/system/startup.service

# Remove remnant files
rm container_startup.service container_startup.sh container_setup.sh

# Execute setup in container
lxc-attach -n $1 -- chmod +x ~/setup.sh
lxc-attach -n $1 -- ~/setup.sh "$2"
