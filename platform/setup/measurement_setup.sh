#!/bin/bash
#
# start MEASUREMENT container
# setup links between groups and measurement container

set -o errexit
set -o pipefail
set -o nounset

DIRECTORY="$1"
source "${DIRECTORY}"/config/subnet_config.sh

# read configs
readarray groups < "${DIRECTORY}"/config/AS_config.txt
group_numbers=${#groups[@]}

# start measurement container
subnet_dns="$(subnet_router_DNS -1 "dns")"
docker run -itd --net='none' --dns="${subnet_dns%/*}" \
	--name="MEASUREMENT" --cpus=2 --pids-limit 100 --privileged d_measurement

passwd="$(openssl rand -hex 8)"
echo "${passwd}" >> "${DIRECTORY}"/groups/ssh_measurement.txt
echo -e ""${passwd}"\n"${passwd}"" | docker exec -i MEASUREMENT passwd root

subnet_ssh_measurement="$(subnet_ext_sshContainer -1 "MEASUREMENT")"
./setup/ovs-docker.sh add-port ssh_to_group ssh_in MEASUREMENT --ipaddress="${subnet_ssh_measurement}"

echo -n "-- add-br measurement " >> "${DIRECTORY}"/groups/add_bridges.sh
echo "ifconfig measurement 0.0.0.0 up" >> "${DIRECTORY}"/groups/ip_setup.sh


for ((k=0;k<group_numbers;k++)); do
    group_k=(${groups[$k]})
    group_number="${group_k[0]}"
    group_as="${group_k[1]}"
    group_config="${group_k[2]}"
    group_router_config="${group_k[3]}"

    if [ "${group_as}" != "IXP" ];then

        readarray routers < "${DIRECTORY}"/config/$group_router_config
        n_routers=${#routers[@]}

        for ((i=0;i<n_routers;i++)); do
            router_i=(${routers[$i]})
            rname="${router_i[0]}"
            property1="${router_i[1]}"

            if [ "${property1}" = "MEASUREMENT"  ];then
                subnet_bridge="$(subnet_router_MEASUREMENT "${group_number}" "bridge")"
                subnet_measurement="$(subnet_router_MEASUREMENT "${group_number}" "measurement")"
                subnet_group="$(subnet_router_MEASUREMENT "${group_number}" "group")"

                ./setup/ovs-docker.sh add-port measurement group_"${group_number}"  \
                MEASUREMENT --ipaddress="${subnet_measurement}"

                mod=$((${group_number} % 100))
                div=$((${group_number} / 100))

                if [ $mod -lt 10 ];then
                    mod="0"$mod
                fi
                if [ $div -lt 10 ];then
                    div="0"$div
                fi

                ./setup/ovs-docker.sh add-port measurement measurement_"${group_number}" \
                "${group_number}"_"${rname}"router --ipaddress="${subnet_group}" \
                --macaddress="aa:22:22:22:"$div":"$mod

                ./setup/ovs-docker.sh connect-ports measurement \
                group_"${group_number}" MEASUREMENT \
                measurement_"${group_number}" "${group_number}"_"${rname}"router
            fi
        done
    fi
done
