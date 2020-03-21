#!/bin/sh
ROUTERNAME=$1
NETFLOW_DIR=$2
NETFLOW_ROTATE_INTERVAL=$3
NETFLOW_SAMPLING=$4

# Start netflow capture to collect netflow sent by the fprobes
#nfcapd -p 2089 -I "$ROUTERNAME" -l $NETFLOW_DIR -s $NETFLOW_SAMPLING -S 1 -D -x "/usr/sbin/nfpostprocess.sh %f %d %t $ROUTERNAME" -t $NETFLOW_ROTATE_INTERVAL
nfcapd -p 2089 -I "$ROUTERNAME" -l $NETFLOW_DIR -s $NETFLOW_SAMPLING -S 1 -D -t $NETFLOW_ROTATE_INTERVAL

# Start the fprobe netflow collector on every interface but
# lo (netflow traffic)
# ssh (student activity)
INTERFACES=$(ls /sys/class/net/ | grep -v lo | grep -v ssh)
for iface in $INTERFACES; do
	fprobe -i $iface localhost:2089
done
