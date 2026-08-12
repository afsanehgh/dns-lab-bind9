#!/bin/bash
set -e

echo "[router] enabling IP forwarding"
docker exec router sysctl -w net.ipv4.ip_forward=1

echo "[ns1] adding route to net-clients"
docker exec ns1 ip route add 10.128.20.0/24 via 10.128.10.1 || true

echo "[ns2] adding route to net-clients"
docker exec ns2 ip route add 10.128.20.0/24 via 10.128.10.1 || true

echo "[host1] adding route to net-dns"
docker exec host1 ip route add 10.128.10.0/24 via 10.128.20.1 || true

echo "[host2] adding route to net-dns"
docker exec host2 ip route add 10.128.10.0/24 via 10.128.20.1 || true

# Optional NAT if you want internet access from containers:
# docker exec router iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Router setup complete."
chmod +x scripts/setup-router.sh
