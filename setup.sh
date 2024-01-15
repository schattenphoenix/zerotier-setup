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

# Prepare config path
LXC_CONFIG="/etc/pve/lxc/$1.conf"
# LXC_CONFIG="./Test$1.conf"

# Append to container config
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> $LXC_CONFIG
echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> $LXC_CONFIG

# Push files
pct push $1 container_setup.sh ~/setup.sh
pct push $1 container_startup.sh /usr/local/bin/startup.sh
pct push $1 container_startup.service /etc/systemd/system/startup.service

# Execute setup in container
lxc-attach -n $1 -- chmod +x ~/setup.sh
lxc-attach -n $1 -- ~/setup.sh "$2"