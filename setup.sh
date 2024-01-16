#!/bin/bash

# Get container id to use
read -r -p "Enter an unsued container id." CONTAINER_ID

# Get zerotier network id
read -r -p "Enter the zerotier network id." ZEROTIER_NETWORK

# Get debian template
TEMPLATE="/var/lib/vz/template/cache/$(ls /var/lib/vz/template/cache/ | grep debian | head -n 1)"

# Ask container password
read -r -s -p "Enter a password for the container." CONTAINER_PASSWORD

# Create container
pct create $CONTAINER_ID $TEMPLATE --ostype debian --hostname zerotier --memory 256 --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp --storage localblock --rootfs local-lvm:2 --cores 1 --start 1 --password $CONTAINER_PASSWORD

# Prepare config path
LXC_CONFIG="/etc/pve/lxc/$CONTAINER_ID.conf"

# Append to container config
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> $LXC_CONFIG
echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> $LXC_CONFIG

# Pull files from git
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_setup.sh -o container_setup.sh
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_startup.sh -o container_startup.sh
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_startup.service -o container_startup.service

# Push files to container
pct push $CONTAINER_ID container_setup.sh ~/setup.sh
pct push $CONTAINER_ID container_startup.sh /usr/local/bin/startup.sh
pct push $CONTAINER_ID container_startup.service /etc/systemd/system/startup.service

# Remove remnant files
rm container_startup.service container_startup.sh container_setup.sh

# Execute setup in container
lxc-attach -n $CONTAINER_ID -- chmod +x ~/setup.sh
lxc-attach -n $CONTAINER_ID -- ~/setup.sh "$ZEROTIER_NETWORK"
