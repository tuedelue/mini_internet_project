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

	#uplaod
	if [ "${group_as}" == "IXP" ];then
	    rsync -a groups/g"${group_number}"/netflow/* groups/webserver/netflow/G$group_number/ || true
	    find groups/g"${group_number}"/netflow -type f -mtime +1 -delete
	else
	    readarray routers < config/$group_router_config
            n_routers=${#routers[@]}

            for ((i=0;i<n_routers;i++)); do
                router_i=(${routers[$i]})
                rname="${router_i[0]}"
		location=groups/g"${group_number}"/"${rname}"

    		rsync -a "${location}"/netflow/*  groups/webserver/netflow/G"${group_number}"/"${rname}"/ || true
		find "${location}"/netflow/ -type f -mtime +1 -delete
            done
	fi

	#process
        for file in $(find groups/webserver/netflow/G"${group_number}"/ -type f ! -name "*.txt" ! -name "*.gz" -name "*current*"); do
                echo $file
                if [ ! -f "${file}".txt ]; then
                        nfdump -r "${file}" -o csv | gzip -9 > "${file}".csv.gz &
                        nfdump -r "${file}" -o line > "${file}".txt &
                fi
        done
        wait

        echo $group_number done
    done
    chmod ugo+r -R groups/webserver/netflow/
    sleep 60
done
