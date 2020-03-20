#!/bin/bash
#
# enable portforwarding
# before executing this script make sure to set
# the following options in  /etc/ssh/sshd_config:
#   GatewayPorts yes
#   PasswordAuthentication yes
#   AllowTcpForwarding yes
# then restart ssh: service ssh restart

DIRECTORY=$(cd `dirname $0` && pwd)
source "${DIRECTORY}"/config/subnet_config.sh

readarray groups < "${DIRECTORY}"/config/AS_config.txt
group_numbers=${#groups[@]}

for ((k=0;k<group_numbers;k++)); do
    group_k=(${groups[$k]})
    group_number="${group_k[0]}"
    group_as="${group_k[1]}"

    if [ "${group_as}" != "IXP" ];then
        ufw allow "$((group_number+2000))"
        subnet=$(subnet_ext_sshContainer "${group_number}" "sshContainer")
        ssh -i groups/id_rsa -o "StrictHostKeyChecking no" -f -N -L 0.0.0.0:"$((group_number+2000))":"${subnet%/*}":22 root@${subnet%/*}
    fi
done

# measurement
ufw allow 2099
subnet=$(subnet_ext_sshContainer "${group_number}" "MEASUREMENT")
ssh -i groups/id_rsa -o "StrictHostKeyChecking no" -f -N -L 0.0.0.0:2099:"${subnet%/*}":22 root@${subnet%/*}

#webserver
ufw allow 80
