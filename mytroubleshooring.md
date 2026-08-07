

## Start the lab
docker compose up -d

## Enter servers

docker exec -it ns1 bash
docker exec -it ns2 bash
docker exec -it host1 bash
dig host1.nyc3.example.com
dig nyc3.example.com
dig -x 10.128.100.101
dig google.com
docker exec -it ns2 bash
ls /var/cache/bind
docker stop ns1
docker start ns1
docker compose logs -f ns1

docker exec -it host2 bash
# debugging

docker run --rm -it -v ./ns1/bind:/etc/bind ubuntu:24.04 bash
named-checkconf /etc/bind/named.conf
docker logs ns1
docker logs ns2
docker compose logs ns1
docker compose down
docker compose up -d
docker ps

## Test DNS

Forward lookup:
dig @10.128.10.11 host1.nyc3.example.com

Reverse lookup:
dig -x 10.128.100.101

Zone transfer:
dig @10.128.20.12 nyc3.example.com AXFR


## on all of the clients that you have configured and are in the trusted ACL
nslookup host1

## Maintianing DNS records
sudo named-checkconf
sudo named-checkzone nyc3.example.com /etc/bind/zones/db.nyc3.example.com
sudo named-checkzone 128.10.in-addr.arpa /etc/bind/zones/db.10.128
sudo systemctl reload bind9

## Troubleshooting
docker compose down
docker rm -f $(docker ps -aq)
docker volume prune -f
docker compose up -d
docker logs ns1

docker compose down --remove-orphans
docker compose up -d
docker compose logs -f ns1
docker ps
docker exec -it ns1 bash -c "ps aux | grep named"
docker exec -it ns1 bash -c "named-checkconf && echo OK" 
docker exec -it host1 bash -c "dig host1.nyc3.example.com"
docker exec -it ns1 bash -c "ps aux | grep named"
docker exec -it host1 bash -c "dig host1.nyc3.example.com"
docker exec -it host1 bash -c "dig -x 10.128.100.101"

After startup, test everything
Test ns1 is running
docker compose logs ns1 > ns1.log
docker exec -it ns1 bash
ps aux | grep named
Test ns2 pulled zones

docker exec -it ns2 bash
ls /var/cache/bind
You should see:


db.nyc3.example.com
db.10.128
Test DNS from host1

docker exec -it host1 bash
dig nyc3.example.com
dig host1.nyc3.example.com
dig -x 10.128.100.101
Test DNS from host2

docker exec -it host2 bash
dig google.com
dig host2.nyc3.example.com
dig -x 10.128.200.102
Test failover
Stop ns1:


docker stop ns1
Then test DNS again from host1:


dig google.com
dig host1.nyc3.example.com
ns2 should answer.


explain AXFR/IXFR DHCP network interface belongs to your private subnet. 
bridge driver → containers can talk to each other

IPAM config → assigns a private subnet
Defines a private DNS network
10.128.0.0/16