#!/bin/bash
set -euo pipefail
cd /etc/bind/zones

rm -f Knyc3.*.key Knyc3.*.private dsset-*
sed -i '/\$INCLUDE/d' "db.${1}"

ZSK=$(dnssec-keygen -a RSASHA256 -b 2048 -n ZONE "${1}")
KSK=$(dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE "${1}")

echo "\$INCLUDE \"/etc/bind/zones/${ZSK}.key\"" >> "db.${1}"
echo "\$INCLUDE \"/etc/bind/zones/${KSK}.key\"" >> "db.${1}"

echo "Keys generated and \$INCLUDE lines updated:"
tail -3 "db.${1}"

