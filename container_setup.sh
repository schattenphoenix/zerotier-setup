#!/bin/bash

# Install base tools
apt update -y && apt upgrade -y && apt install curl iptables iptables-persistent -y

# Install zerotier
curl -s https://install.zerotier.com | bash

# Join network
zerotier-cli join $1

# Setup iptables rules
PHY_IFACE=eth0; ZT_IFACE=zt7nnig26

iptables p-t nat -A POSTROUTING -o $PHY_IFACE -j MASQUERADE
iptables -A FORWARD -i $PHY_IFACE -o $ZT_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $ZT_IFACE -o $PHY_IFACE -j ACCEPT

# Save iptables rules
bash -c iptables-save > /etc/iptables/rules.v4

chmod +x /usr/local/bin/startup.sh
bash /usr/local/bin/startup.sh