#!/bin/bash
echo "Reverse lookup (ns1):"
dig @10.128.10.11 -x 10.128.100.101

echo
echo "Reverse lookup (ns2):"
dig @10.128.20.12 -x 10.128.100.101
