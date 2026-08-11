# ================================
# DNS Lab Makefile
# ================================

NS1_CONTAINER=ns1
NS2_CONTAINER=ns2
ZONE=nyc3.example.com
ZONE_DIR=bind/ns1/zones
ZONE_FILE=$(ZONE_DIR)/db.$(ZONE)
SIGNED_ZONE=$(ZONE_FILE).signed

# Random salt generator for NSEC3
SALT=$(shell head -c 16 /dev/urandom | hexdump -e '1/1 "%02x"')

# ================================
# Docker lifecycle
# ================================

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose down
	docker-compose up -d

# ================================
# Bind9 checks
# ================================

check:
	docker exec $(NS1_CONTAINER) named-checkconf
	docker exec $(NS1_CONTAINER) named-checkzone $(ZONE) /etc/bind/zones/db.$(ZONE)

# ================================
# DNSSEC key generation
# ================================

dnssec-keys:
	docker exec $(NS1_CONTAINER) bash -c "cd /etc/bind/zones && \
	    dnssec-keygen -a RSASHA256 -b 2048 -n ZONE $(ZONE)"
	docker exec $(NS1_CONTAINER) bash -c "cd /etc/bind/zones && \
	    dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE $(ZONE)"
	@echo "Keys generated. Add .key files to your zone file manually."

# ================================
# DNSSEC signing (NSEC3)
# ================================

sign:
	docker exec $(NS1_CONTAINER) bash -c "\
	    dnssec-signzone -3 $(SALT) -A -N keep \
	    -o $(ZONE) /etc/bind/zones/db.$(ZONE)"
	@echo "Signed zone created: $(SIGNED_ZONE)"

reload:
	docker exec $(NS1_CONTAINER) systemctl restart bind9
	docker exec $(NS2_CONTAINER) systemctl restart bind9

# ================================
# DNSSEC verification
# ================================

dnssec-test:
	docker exec host1 dig $(ZONE) +dnssec
	docker exec host1 dig doesnotexist.$(ZONE) +dnssec

# ================================
# Failover testing
# ================================

failover:
	docker stop $(NS1_CONTAINER)
	docker exec host1 dig @10.128.20.12 host1.$(ZONE)
	docker start $(NS1_CONTAINER)
	docker exec host1 dig @10.128.10.11 host1.$(ZONE)

# ================================
# Cleanup
# ================================

clean:
	rm -f $(ZONE_DIR)/*.signed
	rm -f $(ZONE_DIR)/*.jnl
	@echo "Cleaned signed and journal files."

# ================================
# Help
# ================================

help:
	@echo "DNS Lab Makefile Commands:"
	@echo "  make up            - Start lab"
	@echo "  make down          - Stop lab"
	@echo "  make restart       - Restart lab"
	@echo "  make check         - Validate Bind9 configs"
	@echo "  make dnssec-keys   - Generate DNSSEC keys"
	@echo "  make sign          - Sign zone with DNSSEC + NSEC3"
	@echo "  make reload        - Restart Bind9 on ns1/ns2"
	@echo "  make dnssec-test   - Test DNSSEC responses"
	@echo "  make failover      - Test ns1/ns2 failover"
	@echo "  make clean         - Remove signed/journal files"
