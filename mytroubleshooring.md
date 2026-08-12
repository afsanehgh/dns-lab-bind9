

## Start the lab
docker compose up -d

## Enter servers

docker exec -it ns1 bash
docker exec -it ns2 bash
docker exec -it host1 bash
dig host1.nyc3.snowy.com
dig nyc3.snowy.com
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
dig @10.128.10.11 host1.nyc3.snowy.com

Reverse lookup:
dig -x 10.128.100.101

Zone transfer:
dig @10.128.20.12 nyc3.snowy.com AXFR


## logs ns1
docker exec ns1 date
docker compose logs ns2 --tail 50
docker logs ns1
docker compose logs ns1 > ns1.log


## on all of the clients that you have configured and are in the trusted ACL
nslookup host1

## Maintianing DNS records
sudo named-checkconf
sudo named-checkzone nyc3.snowy.com /etc/bind/zones/db.nyc3.snowy.com
sudo named-checkzone 128.10.in-addr.arpa /etc/bind/zones/db.10.128
sudo systemctl reload bind9

## Troubleshooting

docker exec -it host1 bash -c "dig host1.nyc3.snowy.com" //check if dns is up
docker exec -it ns2 bash -c "ss -tulnp | grep :53"
docker exec -it host1 bash -c "dig @10.128.20.12 host1.nyc3.snowy.com"
docker exec -it ns2 bash -c "ip addr show eth0"
docker exec -it ns1 bash -c "ip addr show eth0"
docker compose up -d --force-recreate ns2
docker exec -it ns2 bash -c "cat -A /config/bind/named.conf.options | grep listen-on"
docker exec -it ns2 bash -c "cat -A /etc/bind/named.conf.options | grep listen-on"
docker exec -it ns2 bash -c "ss -tulnp | grep :53"
named-checkconf -z
docker ps -a --filter name=ns2
docker compose logs ns2 --tail 50
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

After startup, test everything
Test ns1 is running
docker compose logs ns1 > ns1.log
docker exec -it ns1 bash
ps aux | grep named
Test ns2 pulled zones

docker exec -it ns2 bash
ls /var/cache/bind
You should see:


db.nyc3.snowy.com
db.10.128
Test DNS from host1

docker exec -it host1 bash
dig nyc3.snowy.com
dig host1.nyc3.snowy.com
dig -x 10.128.100.101
Test DNS from host2

docker exec -it host2 bash
dig google.com
dig host2.nyc3.snowy.com
dig -x 10.128.200.102
Test failover
Stop ns1:



docker stop ns1
Then test DNS again from host1:


dig google.com
dig host1.nyc3.snowy.com
ns2 should answer.

## ns1 regenrate keys when gone from /etc/bind/zones/
ls -la /etc/bind/zones/
cd /etc/bind/zones
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE nyc3.snowy.com
dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE nyc3.snowy.com
Check what the zone file currently references:

bash
grep INCLUDE db.nyc3.snowy.com

Then update those lines to match the newly generated key filenames:

bash
ls Knyc3.snowy.com.+008+*.key
docker cp .\ns1\bind\zones\db.nyc3.snowy.com ns1:/etc/bind/zones/db.nyc3.snowy.com
docker exec ns1 grep INCLUDE /etc/bind/zones/db.nyc3.snowy.com
docker exec -it ns1 bash
cd /etc/bind/zones
SALT=$(head -c 16 /dev/urandom | hexdump -e '1/1 "%02x"')
dnssec-signzone -3 $SALT -A -N keep -o nyc3.snowy.com db.nyc3.snowy.com
rndc reload

docker exec host1 dig "@10.128.10.11" nyc3.snowy.com NS
docker exec host1 dig "@10.128.10.11" host1.nyc3.snowy.com
docker exec host1 dig "@10.128.10.11" nyc3.snowy.com +dnssec
docker exec host1 dig "@10.128.10.11" nyc3.snowy.com DNSKEY +multiline


## after turning recursive off and make it iterative
Now that ns1/ns2 have recursion no;, here's how to actually demonstrate and test iterative behavior properly.

1. Confirm ns1 refuses to do recursive work for you (the negative test)
bash
docker exec host1 dig "@10.128.10.11" google.com

Expect either REFUSED or the "recursion requested but not available" warning with an empty answer — ns1 should not chase down google.com for you, since that's outside its authority and recursion is off. This is the direct confirmation your config change worked.

2. Confirm ns1 still answers authoritatively for its own zone (sanity check)
bash
docker exec host1 dig "@10.128.10.11" host1.nyc3.snowy.com

Should return a clean answer — ns1 doesn't need recursion to answer for names it's authoritative for; recursion only matters for names outside its zone.

3. See the actual iterative process yourself with dig +trace

This is the real teaching tool — it makes your own dig client do the iterative walk manually, hop by hop, exactly the way a resolver would if it weren't allowed to just ask one recursive server:

bash
docker exec host1 dig +trace google.com

You'll see output like:

.                       ...  IN  NS  a.root-servers.net.
;; Received ... from 198.41.0.4#53(a.root-servers.net)

com.                    ...  IN  NS  a.gtld-servers.net.
;; Received ... from ...#53(a.gtld-servers.net)

google.com.             ...  IN  A   142.250.x.x
;; Received ... from ...#53(...)

Each block is one iterative "hop" — root → TLD → authoritative — exactly the referral-chasing behavior ns1 would now refuse to do on your behalf, because recursion is off.

Note: +trace needs actual internet access from inside host1 to reach the real root servers — if your container's outbound networking is restricted, this may itself time out; if so it's a container network issue, not a DNS config issue.

4. Trace against your own lab zone (fully self-contained, no internet needed)
bash
docker exec host1 dig +trace nyc3.snowy.com @10.128.10.11

This won't really "iterate" much since ns1 is authoritative for the whole zone in one hop, but it's worth trying to see how +trace behaves when there's no deeper delegation to walk.

5. Direct comparison — REFUSED (iterative-only) vs a working recursive resolver

To make the contrast obvious, compare ns1's refusal against a real recursive resolver like 8.8.8.8:

bash
docker exec host1 dig "@10.128.10.11" google.com     # REFUSED — no recursion
docker exec host1 dig "@8.8.8.8" google.com            # NOERROR — full recursive answer

Same query, two servers, two completely different postures — that side-by-side is the clearest possible demonstration of what recursion no; actually changes.

Run #1 first — that's the direct pass/fail test for your config change — and paste the output so we confirm ns1 is now correctly iterative-only.
## delv
<!-- Related flags, for context:

+mtrace — message-level trace (raw query/response traffic)
+rtrace — resolver trace (recursion/delegation steps)
+vtrace — validation trace (DNSSEC-specific, what you're asking about)
-d <level>1/2/3 — general debug verbosity, which can overlap with and add to what +vtrace shows -->


delv @10.128.10.11 host1.nyc3.snowy.com
delv -i @10.128.10.11 host1.nyc3.snowy.com
delv -i @10.128.20.12 host2.nyc3.snowy.com
docker exec host1 delv -d 3 "@10.128.10.11" ns1.nyc3.snowy.com
docker exec host1 delv +vtrace  -d 3 "@10.128.10.11" ns1.nyc3.snowy.com

delv -a /tmp/trust-anchor.conf +root=nyc3.snowy.com -d 3 @10.128.10.11 host1.nyc3.snowy.com 2>&1 | head -60
root@ns1:/# prompt inside the container, run:
dig @10.128.10.11 nyc3.snowy.com DNSKEY +multiline

cat > /tmp/trust-anchor.conf << EOF
trust-anchors {
    nyc3.snowy.com static-key 257 3 8 "AwEAAeSsDlONjOWrpcl5X3HJKzGX8nCCD/pEcDm5/qe6ilosq2wd1hYMwkklkvrUMSO4/SS1WBo93Y7NB9KxbM5izX5AyikeLlv/m3hdtHywGS7DNxNN1K18cUVNwTwKwRCVVoBa5qONEyZYfnKdb1FCIcJhgULfGIfS+21E9rOt3vmsWQPMPILyBUrkoYiv4KT84ZNMksz3yYvqv8pJqF0W4h7T0rJQwzLqR3mS47JIAdvcPdn2QfXjAtDtBfaqnpq82QAmnJQFJrrWd3JSwgu20QwjnGVkdI0ESX7sgj8s0M4sfXj7GnSsRMg4cC2Phvkdrq+FQW592rM2Z6GEClZAsvuUPgwOlkdhzQCMIDD0gSNWc0sX5x8KS3k+mXbyOrl2kDLPFGkuTqKfzYQMLkcGZt53BezhZ2tX8JnGzAXEPz7zxzp6pBIPLIQ7oed8eZQRnd5pVYIDlhypustgwruQr5jO5OViw826Eqsd0pl6PvwZ3CMgEGr59YptdzOMWActllxzL7yE7t12y9MkW9u3bhXYyeonJdyyKuERe/ixVN97JsSfhISJwSRsGj+KH3Nw6Duz5hxjcuqQbqhgfaLHsfIYASVLQcz7LuAk3dYgk3z9p2AYhOmHnAYo7jzQubIeGjfAbtnmtH+y/tJ+vXx0qViWcP2iGSoACF9hYIEtScS7";
};
EOF

sed -i 's/static-key/initial-key/' /tmp/trust-anchor.conf


delv -a /tmp/trust-anchor.conf +root=nyc3.snowy.com @10.128.10.11 host1.nyc3.snowy.com
docker exec ns1 delv +vtrace -d 3 -a /tmp/trust-anchor.conf +root=nyc3.snowy.com "@10.128.10.11" ns1.nyc3.snowy.com
## docker copy
docker cp .\ns1\bind\zones\db.nyc3.snowy.com ns1:/etc/bind/zones/db.nyc3.snowy.com
## docker back up main files
docker exec ns1 cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
## to read A records
docker exec ns1 grep ns1.nyc3.snowy.com /etc/bind/zones/db.nyc3.snowy.com
Check the signed file directly for the A record:


## force ns2 to pull update immediately
docker exec ns2 rndc retransfer nyc3.snowy.com
##
## 3. NXDOMAIN


 Symptoms
```
status: NXDOMAIN
```


Causes
- Record does not exist
- NSEC3 proves non-existence


 Fix
Check zone file for missing A/PTR records.

bash
docker exec ns1 grep -A2 "ns1.nyc3.snowy.com" /etc/bind/zones/db.nyc3.snowy.com.signed

This tells us definitively: did dnssec-signzone actually process your edited source file, or did it somehow sign a different/cached version?

Also worth checking — is BIND's in-memory zone actually matching the file on disk, or is there a caching layer in front of it?

bash
docker exec ns1 rndc dumpdb -zones
docker exec ns1 cat /var/cache/bind/named_dump.db | grep -A3 "ns1.nyc3.snowy.com"

(path may vary — check directory setting in named.conf.options, which you showed earlier as /var/cache/bind)

And double check host1 itself isn't caching the old answer — even though you're querying ns1 directly, some dig setups or intermediate caching could theoretically interfere (less likely given aa flag is set, meaning authoritative answer, not cached):

bash
docker exec host1 dig "@10.128.10.11" ns1.nyc3.snowy.com A +noedns

This is the real answer, and it's a clean finding: the in-memory zone BIND is actually serving still has the A record:

ns1.nyc3.snowy.com.  604800 IN A  10.128.10.11
RRSIG A 8 4 604800 20260910035550 20260811035550 44454 nyc3.snowy.com. ...

This RRSIG's inception time is 20260811035550 = 03:55:50 today — which is earlier than your 08:02 signing run. So this dump is showing you a zone signed before your edit, meaning rndc reload didn't actually pick up the newly-signed 08:02 file into memory, even though dnssec-signzone itself ran successfully and updated the file on disk.

This is a known BIND gotcha: rndc reload doesn't always force a full re-read if BIND thinks the zone is already loaded/current — especially depending on serial number handling. Let's force it properly.

1. Check the actual SOA serial in the signed file vs what's loaded:

powershell
docker exec ns1 bash -c "grep -A1 'IN.*SOA' /etc/bind/zones/db.nyc3.snowy.com.signed | head -2"

If the serial is still 3 (unchanged from before your edit), that's likely why BIND isn't reloading — many nameservers treat an unchanged serial as "nothing changed, skip it," even though the actual record content differs.

2. Force a genuinely fresh reload of just this zone, not the whole server:

powershell
docker exec ns1 rndc reload nyc3.snowy.com

(reloading a specific zone by name is sometimes more reliable than a blanket rndc reload)

3. If that still doesn't work, bump the serial and re-sign — this is very likely the actual fix:

bash
docker exec -it ns1 bash
bash
cd /etc/bind/zones
sed -i 's/^\( *\)3\( *; Serial\)/\14\2/' db.nyc3.snowy.com
grep -A1 SOA db.nyc3.snowy.com
SALT=$(head -c 16 /dev/urandom | hexdump -e '1/1 "%02x"')
dnssec-signzone -3 $SALT -A -N keep -o nyc3.snowy.com db.nyc3.snowy.com
rndc reload
exit


## change serial 3 to 4 
docker exec -it ns1 bash
cd /etc/bind/zones
sed -i 's/^\( *\)3\( *; Serial\)/\14\2/' db.nyc3.snowy.com
grep -B1 -A1 Serial db.nyc3.snowy.com


## router changes test
docker compose down
docker network rm dns-lab_dnsnet
docker network rm dnsnet
docker network ls
docker ps -a
docker compose down --remove-orphans

docker network inspect bridge --format "{{json .IPAM.Config}}"
docker system info | findstr -i "pool"
docker network prune -f
docker network inspect bridge --format "{{json .IPAM}}"
type "$env:USERPROFILE\.docker\daemon.json" 2>$null

docker compose up -d
Cause: the router is the only service connected to both networks. It's very likely trying to grab 10.128.10.1 on net-dns and/or 10.128.20.1 on net-clients, but one of those addresses is already claimed — most likely by Docker's automatic gateway IP. When you define a subnet like 10.128.10.0/24 without explicitly setting a gateway:, Docker auto-assigns .1 as the network's own gateway address — which directly collides with your router's explicit ipv4_address: 10.128.10.1.

Fix — explicitly set the network's gateway to something else, freeing up .1 for your router, or just move the router off .1 to an address Docker won't auto-claim. The cleaner fix is the former, since .1 for a router is the more intuitive/conventional choice:
networks:
  net-dns:
    ipam:
      config:
        - subnet: 10.128.10.0/24
          gateway: 10.128.10.254
  net-clients:
    ipam:
      config:
        - subnet: 10.128.20.0/24
          gateway: 10.128.20.254
docker network inspect dns-lab_net-dns
docker network inspect dns-lab_net-clients

docker ps -a --filter name=router
docker inspect router --format "{{json .NetworkSettings.Networks}}"
docker logs router

docker exec host1 ip route add 10.128.10.0/24 via 10.128.20.1
docker exec host2 ip route add 10.128.10.0/24 via 10.128.20.1
docker exec ns1 ip route add 10.128.20.0/24 via 10.128.10.1
docker exec ns2 ip route add 10.128.20.0/24 via 10.128.10.1
docker compose up -d --force-recreate host1 host2
docker exec host1 ping -c 2 10.128.10.11

4. Re-sign the zone (fresh containers = fresh unsigned zone copied by entrypoint):

bash
docker exec -it ns1 bash
bash
cd /etc/bind/zones
named-checkzone nyc3.snowy.com db.nyc3.snowy.com

Confirm clean, then:

bash
SALT=$(head -c 16 /dev/urandom | hexdump -e '1/1 "%02x"')
dnssec-signzone -3 $SALT -A -N keep -o nyc3.snowy.com db.nyc3.snowy.com
named-checkzone nyc3.snowy.com db.nyc3.snowy.com.signed
rndc reload
exit

5. Verify routing and DNS end-to-end:

powershell
docker exec host1 ping -c 3 10.128.10.11
docker exec host1 traceroute 10.128.10.11
docker exec host1 dig "@10.128.10.11" host1.nyc3.snowy.com
## ########
netstat
delv

explain AXFR/IXFR DHCP network interface belongs to your private subnet. 
bridge driver → containers can talk to each other

IPAM config → assigns a private subnet
Defines a private DNS network
10.128.0.0/16