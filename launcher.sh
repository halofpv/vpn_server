#!/bin/bash

set -e

echo "Updating system"
apt update -y
apt install -y strongswan strongswan-pki libcharon-extra-plugins

echo "backuping previous config (/etc/ipsec.conf.bak & /etc/ipsec.secrets.bak"
[ -f /etc/ipsec.conf ] && cp /etc/ipsec.conf /etc/ipsec.conf.bak
[ -f /etc/ipsec.secrets ] && cp /etc/ipsec.secrets /etc/ipsec.secrets.bak

echo "Creating full-tunneling configuration /etc/ipsec.conf"
cat > /etc/ipsec.conf <<'EOF'
config setup
    charondebug="all"

conn test
    keyexchange=ikev2
    authby=secret
    ike=aes256-sha256-modp2048
    esp=aes256-sha256

    left=0.0.0.0
    leftsubnet=0.0.0.0/0
    leftfirewall=yes

    right=%any
    rightsourceip=10.10.10.0/24
    rightsubnet=0.0.0.0/0

    modeconfig = push
    leftdns = 8.8.8.8,1.1.1.1

    auto=add
EOF

echo "Creating PSK /etc/ipsec.secrets"
cat > /etc/ipsec.secrets <<'EOF'
: PSK "$PSK"
EOF

echo "Creating IP-forwarding..."
if ! grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
sysctl -p

echo "Configuring NAT..."
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o ens33 -j MASQUERADE

clear
echo "Loading system."
clear
echo "Loading system.."
clear
echo "Loading system..."
clear
systemctl restart strongswan-starter
systemctl enable strongswan-starter

echo "Server is deployed!"
echo "Use sudo ipsec statusall to recieve extended information" 
