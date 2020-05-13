#!/bin/bash

input1="./iocips_no_cr.txt"
input2="./iocdomains_no_cr.txt"
sid=1000003

echo "# Test rules"
# Echo out the ICMP test rule
echo "alert icmp any any <> any any (msg:\"ICMP Test\"; sid: 1000001;)"
echo ""

# Echo out the known bad IP rule
echo "# IP addresses - APT1 IOCs"
bad_ip=""
while read -r line
do
	bad_ip="$line,$bad_ip"
done < "$input1"

# Trim last comma that is not required
bad_ip=${bad_ip::-1}
echo "alert ip [$bad_ip] any -> any any (msg:\"BADNESS - Detected IOC traffic for APT1\"; sid: 1000002;)"
echo ""

# Generate the domain alerts
echo "# Domains - APT1 IOCs"
while read -r line
do
	echo "alert udp any any -> any any (msg:\"BADNESS - Detected APT IOC domain DNS request - $line\"; content:\"$line\"; sid: $sid;)"
	let "sid = sid + 1"
done < "$input2"
