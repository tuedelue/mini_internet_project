#!/bin/bash
ROUTERNAME=$1
NETFLOW_DIR=$2
NETFLOW_ROTATE_INTERVAL=$3
NETFLOW_SAMPLING=$4

# Base port
PORT_NUM=2000

# Start the fprobe netflow collector on every interface but
# lo (netflow traffic)
# ssh (student activity)
INTERFACES=$(ls /sys/class/net/ | grep -v lo | grep -v ssh)
for iface in $INTERFACES; do

	# One netflow dir per interface since fprobe sadly doesn't log
	# SNMP interface ID's. This also carries the human-readable
	# interface names over to the directory names.
	OUTDIR="${NETFLOW_DIR}/port-${iface}"

	if [ ! -d $OUTDIR ]; then	
		mkdir -p $OUTDIR
	fi
	ifconfig $iface > $OUTDIR/ifconfig.txt

	# Start netflow capture to collect netflow sent by the fprobes
	nfcapd -T +1,+4,+5,+10,+11,+13 -p ${PORT_NUM} -I "${ROUTERNAME}-port-${iface}" -l $OUTDIR -s $NETFLOW_SAMPLING -S 1 -D -t $NETFLOW_ROTATE_INTERVAL -P /var/run/nfcapd-$PORT_NUM.pid

	# fprobe cannot even mark the packet direction (in/out)
	# fix: filter by interface mac and tag with -x
	iface_mac=$(cat /sys/class/net/$iface/address)
	# outgoing traffic
	fprobe -x1:2 -i $iface -f "ether src ${iface_mac}" localhost:$PORT_NUM
	# incoming traffic
	fprobe -x2:1 -i $iface -f "ether dst ${iface_mac}" localhost:$PORT_NUM

	PORT_NUM=$((PORT_NUM+1))
done
