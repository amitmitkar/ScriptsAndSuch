#!/bin/bash
ipaddr=`ip addr show | grep inet | grep global | awk '{print $2}' | cut -d / -f1`
hostname=`hostname`

if [[ "${hostname}" =~ "localhost.*" ]]
then
    echo "Please set your hostname(${hostname}) to something other than localhost"
    exit 2
fi

echo "Detected ip address as ${ipaddr}"

cat nsupdate.conf | sed  -e "s,IPADDR,${ipaddr},g"  -e "s,HOSTNAME,${hostname}," | nsupdate

