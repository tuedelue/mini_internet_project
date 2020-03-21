#!/bin/bash
#
# creates an initial configuration for every router
# load configuration into router

set -o errexit
set -o pipefail
set -o nounset

DIRECTORY="$1"
source "${DIRECTORY}"/config/subnet_config.sh

NETFLOW_DIR="/home/netflow"
# One new file every 3600 secs
NETFLOW_ROTATE_INTERVAL="3600"
NETFLOW_SAMPLING="1"

# read configs
readarray groups < "${DIRECTORY}"/config/AS_config.txt
readarray extern_links < "${DIRECTORY}"/config/external_links_config.txt
readarray l2_switches < "${DIRECTORY}"/config/layer2_switches_config.txt
readarray l2_links < "${DIRECTORY}"/config/layer2_links_config.txt
readarray l2_hosts < "${DIRECTORY}"/config/layer2_hosts_config.txt

group_numbers=${#groups[@]}
n_extern_links=${#extern_links[@]}
n_l2_switches=${#l2_switches[@]}
n_l2_links=${#l2_links[@]}
n_l2_hosts=${#l2_hosts[@]}


# create initial configuration for each router
for ((k=0;k<group_numbers;k++));do
    group_k=(${groups[$k]})
    group_number="${group_k[0]}"
    group_as="${group_k[1]}"
    group_config="${group_k[2]}"
    group_router_config="${group_k[3]}"
    group_internal_links="${group_k[4]}"

    if [ "${group_as}" != "IXP" ];then

        readarray routers < "${DIRECTORY}"/config/$group_router_config
        readarray intern_links < "${DIRECTORY}"/config/$group_internal_links
        n_routers=${#routers[@]}

        for ((i=0;i<n_routers;i++)); do
            router_i=(${routers[$i]})
            rname="${router_i[0]}"

	    docker exec -ti "${group_number}"_"${rname}"router /usr/sbin/init-nf.sh "${group_number}"_"${rname}"router $NETFLOW_DIR $NETFLOW_ROTATE_INTERVAL $NETFLOW_SAMPLING
        done

    else # If IXP
	docker exec -ti "${group_number}"_IXP /usr/sbin/init-nf.sh "${group_number}"_IXP $NETFLOW_DIR $NETFLOW_ROTATE_INTERVAL $NETFLOW_SAMPLING
    fi
done

wait
