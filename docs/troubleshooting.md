
# Troubleshooting Guide — Bind9 DNS Lab

This guide covers common issues encountered when running Bind9 in a primary/secondary DNS lab.

---

## 1. SERVFAIL

### Symptoms
```
dig nyc3.example.com
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL
```

### Causes
- Zone file syntax error
- DNSSEC signature expired
- ns2 cannot AXFR from ns1
- Incorrect file permissions

### Fix
Check zone syntax:

```bash
named-checkzone nyc3.example.com /etc/bind/zones/db.nyc3.example.com
```

Check config:

```bash
named-checkconf
```

Restart Bind9:

```bash
systemctl restart bind9
```

---

## 2. REFUSED

### Symptoms
```
status: REFUSED
```

### Causes
- Querying a non-authoritative server
- ACLs blocking the request
- AXFR not allowed

### Fix
Ensure:

```
allow-transfer { 10.128.20.12; };
allow-query { any; };
```

---

## 3. NXDOMAIN

### Symptoms
```
status: NXDOMAIN
```

### Causes
- Record does not exist
- NSEC3 proves non-existence

### Fix
Check zone file for missing A/PTR records.

---

## 4. No OPT PSEUDOSECTION

### Symptoms
EDNS missing:

```
;; OPT PSEUDOSECTION: (not present)
```

### Causes
- EDNS disabled
- Firewall blocking UDP fragments

### Fix
Ensure:

```
edns yes;
```

in `named.conf.options`.

---

## 5. AXFR Fails

### Symptoms
```
transfer failed
```

### Causes
- ns1 not reachable
- ACL missing
- Serial number not incremented

### Fix
Increment SOA serial:

```
3 → 4
```

Restart ns1.

---

## 6. DNSSEC Issues

### Symptoms
- Missing RRSIG
- Missing DNSKEY
- No NSEC3 records

### Fix
Re-sign zone:

```bash
dnssec-signzone -3 <salt> -A -N keep -o nyc3.example.com db.nyc3.example.com
```

Reload:

```bash
systemctl restart bind9
```
```

---

# **📄 Dockerfile.ns**

```dockerfile
FROM ubuntu:24.04

RUN apt update && \
    apt install -y bind9 bind9utils bind9-doc dnsutils nano iptables && \
    rm -rf /var/lib/apt/lists/*

# Bind9 runs as a service inside the container
CMD ["/usr/sbin/named", "-g"]
```

This runs Bind9 in the foreground (`-g`) so Docker can manage the process.

---

# **📄 Architecture Diagrams (ASCII)**

## **Network Topology**

```
                +------------------+
                |     Internet     |
                +------------------+
                         |
                         |
                +------------------+
                |   host1/host2    |
                |  (clients)       |
                +------------------+
                         |
                10.128.0.0/16 network
                         |
        -----------------------------------------
        |                                       |
+------------------+                 +------------------+
|      ns1         |                 |      ns2         |
| 10.128.10.11     |                 | 10.128.20.12     |
| Primary DNS      |                 | Secondary DNS    |
| Bind9            |                 | Bind9            |
+------------------+                 +------------------+
```

---

## **DNS Query Flow**

```
host1 → ns1 → answer
host1 → ns2 → answer (failover)
```

---

## **AXFR Flow**

```
ns1 (master)
   |
   |--- AXFR ---> ns2 (slave)
```

---

## **DNSSEC Signing Flow**

```
Zone file
   |
   |--- ZSK/KSK keys
   |
   |--- dnssec-signzone (NSEC3)
   |
Signed zone (.signed)
   |
Bind9 loads signed zone
```


