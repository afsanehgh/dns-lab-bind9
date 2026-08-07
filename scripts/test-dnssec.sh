#!/bin/bash
echo "DNSSEC test:"
dig nyc3.example.com +dnssec

echo
echo "NSEC3 denial-of-existence test:"
dig doesnotexist.nyc3.example.com +dnssec
