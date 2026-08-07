#!/bin/bash
echo "Stopping ns1..."
docker stop ns1

echo "Testing failover (ns2):"
dig @10.128.20.12 host1.nyc3.example.com

echo "Starting ns1..."
docker start ns1

echo "Testing ns1 again:"
dig @10.128.10.11 host1.nyc3.example.com

echo "Starting ns1..."
docker start ns1
