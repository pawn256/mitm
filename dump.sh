#!/bin/bash

if [ $# -ne 2 ];then
	echo $0 interface_name exclude_ip
	exit 1
fi
ofname=$(date +%Y%m%d%H%M%S).dump
iface=$1 # e.g eth0
exclIP=$2 
echo $iface
echo $exclIP
tcpdump -i $iface -vvv -x -X \(port 53 or 80\) and \(not host $exclIP\) -w $ofname

