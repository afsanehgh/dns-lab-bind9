# NSEC vs NSEC3 — Authenticated Denial of Existence in DNSSEC

DNSSEC must prove when a DNS name does *not* exist. This is called **authenticated denial of existence**.  
Two mechanisms provide this:

- **NSEC**
- **NSEC3**

They serve the same purpose but behave very differently in terms of privacy and security.

---

## 1. Why denial of existence is needed

When a resolver queries a name that does not exist, DNSSEC must return a **cryptographically signed proof** that:

- the name is not present in the zone  
- the server is not lying  
- the response has not been tampered with  

This proof is provided using NSEC or NSEC3.

---

## 2. NSEC — Simple but leaks zone contents

NSEC creates a chain of **real, un-hashed domain names** in sorted order.

Example:

```
host1.nyc3.example.com → host2.nyc3.example.com
```

If a name does not exist, the server returns:

```
host1.nyc3.example.com NSEC host2.nyc3.example.com
```

This means:

- `host1` exists  
- `host2` exists  
- everything between them does **not** exist  

### ❌ Problem: Zone Walking

Because NSEC reveals the next valid name, an attacker can enumerate the entire zone:

```
host1
host2
host3
host4
...
```

This is called **zone walking** and is a privacy leak.

---

## 3. NSEC3 — Hashed names to prevent zone walking

NSEC3 solves the privacy problem by hashing domain names.

Instead of:

```
host1 → host2
```

You get:

```
HASH1 → HASH2
```

Example:

```
3f2a9d... NSEC3 7c91b2...
```

Resolvers can still verify non‑existence, but attackers cannot easily reverse the hashes.

### ✔ Prevents zone enumeration  
### ✔ Protects internal hostnames  
### ✔ Recommended for production deployments  

---

## 4. Technical differences

| Feature | NSEC | NSEC3 |
|--------|------|--------|
| Prevents zone walking | ❌ No | ✔ Yes |
| Uses hashing | ❌ No | ✔ Yes |
| Reveals real domain names | ✔ Yes | ❌ No |
| Simpler | ✔ Yes | ❌ More complex |
| Recommended for production | ❌ No | ✔ Yes |

---

## 5. How to view NSEC3 records

Query a non‑existent name:

```bash
dig doesnotexist.nyc3.example.com +dnssec
```

You should see:

- `NSEC3`  
- `RRSIG`  
- hashed owner names  

This confirms that NSEC3 is active.

---

## 6. Why this lab uses NSEC3

This DNS lab uses NSEC3 because:

- it prevents zone enumeration  
- it matches modern DNSSEC deployments  
- it protects internal hostnames  
- Bind9 supports it cleanly with `dnssec-signzone -3`  

---

## 7. Summary

- **NSEC** is simple but leaks zone contents.  
- **NSEC3** hashes names and prevents zone walking.  
- Modern DNSSEC deployments use **NSEC3**.  
- This lab uses **NSEC3** for realistic, secure behavior.
