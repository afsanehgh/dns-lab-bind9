# **DNS Lab — Bind9, AXFR, Failover, DNSSEC, NSEC3**

This project is a fully containerized DNS lab built using **Bind9**, designed for engineers who want a reproducible environment to explore:

- Authoritative DNS  
- Forward and reverse lookups  
- Primary/secondary zone transfers (AXFR)  
- DNS failover behavior  
- EDNS  
- DNSSEC (ZSK/KSK, RRSIG, DNSKEY)  
- NSEC3 denial‑of‑existence  

The lab runs entirely inside Docker and is safe to experiment with.

---

## **Architecture**

### **Components**
- **ns1** — Primary authoritative DNS server  
- **ns2** — Secondary authoritative DNS server  
- **host1 / host2** — Client machines for testing  
- **10.128.0.0/16** — Internal lab network  

### **Flow**
- ns1 serves the zone `nyc3.snowy.com`  
- ns2 receives zone updates via AXFR  
- host1/host2 query ns1 and ns2 directly  
- DNSSEC (optional) is enabled on ns1 and replicated to ns2  

---

## **Features**

### **Forward DNS**
```
dig @10.128.10.11 host1.nyc3.snowy.com
```

### **Reverse DNS**
```
dig -x 10.128.100.101
```

### **Zone Transfers (AXFR)**
```
dig @10.128.20.12 nyc3.snowy.com AXFR
```

### **Failover Testing**
Stop ns1:

```
docker stop ns1
```

Query ns2:

```
dig @10.128.20.12 host1.nyc3.snowy.com
```

Start ns1 again:

```
docker start ns1
```

### **EDNS**
```
dig nyc3.snowy.com +dnssec
```

Shows:

```
;; OPT PSEUDOSECTION:
; EDNS: version: 0, udp: 1232
```

### **DNSSEC (Optional)**
Includes:

- ZSK/KSK key generation  
- Zone signing  
- NSEC3 hashing  
- RRSIG, DNSKEY, NSEC3 records  

---

## **Project Structure**

```
dns-lab/
├── README.md
├── Makefile
├── architecture/
│   ├── network-diagram.png
│   └── dns-flow.png
├── bind/
│   ├── ns1/
│   │   ├── named.conf
│   │   ├── named.conf.options
│   │   ├── named.conf.local
│   │   └── zones/
│   │       ├── db.nyc3.snowy.com
│   │       ├── db.10.128
│   └── ns2/
│       ├── named.conf
│       ├── named.conf.options
│       ├── named.conf.local
│       └── zones/
├── docker/
│   ├── docker-compose.yml
│   └── Dockerfile.ns
├── scripts/
│   ├── test-forward.sh
│   ├── test-reverse.sh
│   └── test-failover.sh
└── docs/
    ├── dnssec.md
    ├── nsec-vs-nsec3.md
    └── troubleshooting.md
```

---

## **Running the Lab**

Start everything:

```
make up
```

Stop everything:

```
make down
```

Restart:

```
make restart
```

---

## **DNSSEC Setup (Optional)**

### **1. Generate keys**
Inside ns1:

```
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE nyc3.snowy.com
dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE nyc3.snowy.com
```

### **2. Add DNSKEYs to the zone**
In `db.nyc3.snowy.com`:

```
$INCLUDE "/etc/bind/zones/Knyc3.snowy.com.+008+<ZSK>.key"
$INCLUDE "/etc/bind/zones/Knyc3.snowy.com.+008+<KSK>.key"
```

### **3. Sign the zone with NSEC3**
```
make sign
```

### **4. Reload Bind9**
```
make reload
```

### **5. Test DNSSEC**
```
make dnssec-test
```

You should see:

- DNSKEY  
- RRSIG  
- NSEC3  

---

## **Failover Testing**

```
make failover
```

This:

1. Stops ns1  
2. Queries ns2  
3. Starts ns1  
4. Queries ns1 again  

---

## **Security Notes**

Add to `.gitignore`:

```
*.private
*.signed
*.jnl
```

Never publish DNSSEC private keys.

---

## **Troubleshooting**

See `docs/troubleshooting.md` for:

- SERVFAIL  
- REFUSED  
- NXDOMAIN  
- AXFR failures  
- DNSSEC signature issues  
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
docker exec -it host1 bash -c "dig host1.nyc3.snowy.com"
docker exec -it ns1 bash -c "ps aux | grep named"
docker exec -it host1 bash -c "dig host1.nyc3.snowy.com"
docker exec -it host1 bash -c "dig -x 10.128.100.101"


## **Router Architecture**
The lab uses a dedicated router container to connect two Docker networks:

Network Layout
Network	CIDR	Gateway	Router IP
net-dns	10.128.10.0/24	10.128.10.254	10.128.10.1
net-clients	10.128.20.0/24	10.128.20.254	10.128.20.1

Why a Router Is Needed
Docker does not forward traffic between user‑defined networks.
Each network has its own virtual gateway, and containers cannot reach other networks unless:

a router forwards packets

containers have static routes pointing to the router

Static Routes
Containers in net-dns must route to net-clients via:

Code
ip route add 10.128.20.0/24 via 10.128.10.1
Containers in net-clients must route to net-dns via:

Code
ip route add 10.128.10.0/24 via 10.128.20.1
Router Setup Script
Run:

Code
make router-setup
This configures:

IP forwarding on the router

static routes on ns1, ns2, host1, host2

optional NAT (disabled by default)
4. Optional: Add automatic routing inside each init.sh
If you prefer containers to configure themselves:

ns1/init.sh
Code
ip route add 10.128.20.0/24 via 10.128.10.1
host1/init.sh
Code
ip route add 10.128.10.0/24 via 10.128.20.1
This removes the need for the router script entirely.

5. Optional: Add a Makefile test target
Code
test-routing:
    docker exec host1 ping -c 2 10.128.10.11
    docker exec ns1 ping -c 2 10.128.20.101
Run:

Code
make test-routing
If both pings succeed, routing is correct.