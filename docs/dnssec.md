## 1. Overview

DNSSEC adds cryptographic signatures to DNS records. It protects against:

- Cache poisoning
- Spoofed DNS responses
- Man‑in‑the‑middle attacks

DNSSEC does **not** encrypt DNS; it only provides authenticity.

This lab uses:

- **RSASHA256** keys
- **ZSK** (Zone Signing Key)
- **KSK** (Key Signing Key)
- **NSEC3** for denial‑of‑existence

---

## 2. Generate DNSSEC Keys

Inside **ns1**:

```bash
cd /etc/bind/zones

# Zone Signing Key (ZSK)
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE nyc3.example.com

# Key Signing Key (KSK)
dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE nyc3.example.com
