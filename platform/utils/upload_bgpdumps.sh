#!/bin/bash
#
# Upload the looking glass on a web server

# REQUIREMENT: make sure to upload you public in the remote server where you
# want to upload the looking glass. And change the username when doing the scp.

set -o errexit
set -o pipefail
set -o nounset

# read configs
readarray groups < config/AS_config.txt
group_numbers=${#groups[@]}

while true
do
    for ((k=0;k<group_numbers;k++)); do
        group_k=(${groups[$k]})
        group_number="${group_k[0]}"
        group_as="${group_k[1]}"
        group_config="${group_k[2]}"
        group_router_config="${group_k[3]}"

        if [ "${group_as}" == "IXP" ];then
	    cp -R groups/g${group_number}/bgpdump groups/webserver/looking_glass/G$group_number/
	    chmod ugo+r -R groups/webserver/looking_glass/G${group_number}/bgpdump
            echo $group_number done
        fi
    done
    sleep 60
done
