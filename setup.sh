#!/bin/bash

# Prepare random prefix to prevent file overwriting
RPREFIX="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

# Get container id, network id and password
read -r -p "Enter an unsued container id: " CONTAINER_ID
read -r -p "Enter the zerotier network id: " ZEROTIER_NETWORK
read -r -s -p "Enter a password for the container: " CONTAINER_PASSWORD

# Input checks
if [ ${#ZEROTIER_NETWORK} != 16 ] ; then
    echo "The zerotier network id needs to be exactly 16 characters long!"
    exit 1
fi

if [[ ${#CONTAINER_PASSWORD} -lt 5 ]] ; then
    echo "The container password needs to be at least 5 characters long!"
    exit 1
fi

# Get debian template
TEMPLATE="/var/lib/vz/template/cache/$(ls /var/lib/vz/template/cache/ | grep debian-.*.standard | head -n 1)"

# Create container
pct create $CONTAINER_ID $TEMPLATE --ostype debian --hostname zerotier --memory 256 --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp --storage localblock --rootfs local-lvm:2 --cores 1 --start 1 --password $CONTAINER_PASSWORD

# Prepare config path
LXC_CONFIG="/etc/pve/lxc/$CONTAINER_ID.conf"

# Append to container config
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> $LXC_CONFIG
echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> $LXC_CONFIG

# Pull files from git
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_setup.sh -o $RPREFIX.container_setup.sh
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_startup.sh -o $RPREFIX.container_startup.sh
curl -s https://raw.githubusercontent.com/schattenphoenix/zerotier-setup/main/container_startup.service -o $RPREFIX.container_startup.service

# Push files to container
pct push $CONTAINER_ID $RPREFIX.container_setup.sh ~/setup.sh

# Startup service to enable ipv4 forwarding - seems broken in container otherwise!
pct push $CONTAINER_ID $RPREFIX.container_startup.sh /usr/local/bin/startup.sh
pct push $CONTAINER_ID $RPREFIX.container_startup.service /etc/systemd/system/startup.service

# Remove remnant files
rm $RPREFIX.container_startup.service $RPREFIX.container_startup.sh $RPREFIX.container_setup.sh

# Execute setup in container
lxc-attach -n $CONTAINER_ID -- chmod +x ~/setup.sh
lxc-attach -n $CONTAINER_ID -- ~/setup.sh "$ZEROTIER_NETWORK"
