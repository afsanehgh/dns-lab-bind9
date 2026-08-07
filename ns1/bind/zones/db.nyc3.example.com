$TTL    604800
@       IN      SOA     ns1.nyc3.example.com. admin.nyc3.example.com. (
                        3         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
; name servers - NS records
        IN      NS      ns1.nyc3.example.com.
        IN      NS      ns2.nyc3.example.com.

; name servers - A records
ns1.nyc3.example.com.    IN      A       10.128.10.11
ns2.nyc3.example.com.    IN      A       10.128.20.12

; 10.128.0.0/16 - A records
host1.nyc3.example.com.  IN      A       10.128.100.101
host2.nyc3.example.com.  IN      A       10.128.200.102
