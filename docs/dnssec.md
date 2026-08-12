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
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE nyc3.snowy.com

# Key Signing Key (KSK)
dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE nyc3.snowy.com

ls -l /etc/bind/zones
# Copy the keys into ns1 (if generated on host)
# docker cp Knyc3.snowy.com.+008<key>.key ns1:/etc/bind/zones/
# docker cp Knyc3.snowy.com.+008<key>.private ns1:/etc/bind/zones/
 SALT=$(head -c 16 /dev/urandom | hexdump -e '1/1 "%02x"')
dnssec-signzone -3 $SALT -A -N keep -o nyc3.snowy.com db.nyc3.snowy.com

## his allows Bind9 to write:
##managed-keys.bind
##managed-keys.bind.jnl
ls -ld /var/cache/bind
chown -R bind:bind /var/cache/bind
chmod 775 /var/cache/bind
chown -R bind:bind /etc/bind
chmod -R 755 /etc/bind
/usr/sbin/named -u bind
/usr/sbin/named -g -u bind
named-checkconf && rndc reload
docker restart ns1

nano /etc/bind/zones/db.nyc3.snowy.com

## And your DNSSEC includes at the bottom of the file:
$INCLUDE "/etc/bind/zones/Knyc3.snowy.com.+008<key>.key"
$INCLUDE "/etc/bind/zones/Knyc3.snowy.com.+008<key>.key"




nano /etc/bind/named.conf.local
## Change: file "/etc/bind/zones/db.nyc3.snowy.com";
file "/etc/bind/zones/db.nyc3.snowy.com.signed";

systemctl restart bind9 #or service bind9 restart

named -g #runs the BIND DNS server in the foreground and outputs logs to stderr, which is useful for debugging and containerized environments.

ps aux | grep named # Confirm Bind9 is actually running
