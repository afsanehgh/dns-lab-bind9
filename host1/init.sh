#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y sudo openssh-server nano dnsutils util-linux bsdmainutils iptables iproute2 net-tools traceroute iputils-ping curl

id -u cocoa &>/dev/null || useradd -m -s /bin/bash cocoa
echo "cocoa:cocoag" | chpasswd
usermod -aG sudo cocoa

iptables -A INPUT -p tcp --dport 22 -j ACCEPT || true

mkdir -p /var/run/sshd
/usr/sbin/sshd

# DNS configuration
echo "nameserver 10.128.10.11" > /etc/resolv.conf
echo "nameserver 10.128.10.12" >> /etc/resolv.conf

ip route add 10.128.10.0/24 via 10.128.20.1 2>/dev/null

tail -f /dev/null
