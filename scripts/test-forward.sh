#!/bin/bash
echo "Forward lookup (ns1):"
dig @10.128.10.11 host1.nyc3.example.com

echo
echo "Forward lookup (ns2):"
dig @10.128.20.12 host1.nyc3.example.com
