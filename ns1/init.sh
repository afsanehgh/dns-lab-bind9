#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  -o Dpkg::Options::="--force-confold" \
  -o Dpkg::Options::="--force-confdef" \
  sudo openssh-server bind9 bind9utils bind9-doc nano dnsutils util-linux bsdmainutils iptables iproute2 net-tools traceroute iputils-ping curl ethtool

# Create user
id -u cocoa &>/dev/null || useradd -m -s /bin/bash cocoa
echo "cocoa:cocoag" | chpasswd

# Add sudo privileges
usermod -aG sudo cocoa

# Minimal firewall (Docker-compatible)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT || true

# Enable SSH
mkdir -p /var/run/sshd
/usr/sbin/sshd
 
# Copy our config in AFTER bind9 has installed its own defaults, so the
# package's own named.conf is never blocked or fought over by the mount.
cp -f /config/bind/named.conf.local /etc/bind/named.conf.local
cp -f /config/bind/named.conf.options /etc/bind/named.conf.options
mkdir -p /etc/bind/zones
cp -f /config/bind/zones/* /etc/bind/zones/
 
# Validate and start BIND (Docker's policy-rc.d blocks auto-start on install,
# so we have to bring it up ourselves)
named-checkconf
ip route add 10.128.20.0/24 via 10.128.10.1>/dev/null
service bind9 start || /usr/sbin/named -u bind
 
tail -f /dev/null
 