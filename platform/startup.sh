#!/bin/bash
#
# starts whole network

set -o errexit
set -o pipefail
set -o nounset


DIRECTORY=$(cd `dirname $0` && pwd)

echo "$(date +%Y-%m-%d_%H-%M-%S)"

echo "cleanup.sh: "
time ./cleanup/cleanup.sh "${DIRECTORY}"

echo ""
echo ""

# change size of ARP table necessary for large networks
sysctl net.ipv4.neigh.default.gc_thresh1=4096
sysctl net.ipv4.neigh.default.gc_thresh2=8192
sysctl net.ipv4.neigh.default.gc_thresh3=16384
sysctl -p

# Increase the max number of running processes
sysctl kernel.pid_max=4194304

echo "folder_setup.sh $(($(date +%s%N)/1000000))" > "${DIRECTORY}"/log.txt
echo "folder_setup.sh: "
time ./setup/folder_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "dns_config.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "dns_config.sh: "
time ./setup/dns_config.sh "${DIRECTORY}"

echo ""
echo ""

echo "vpn_config.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "vpn_config.sh: "
time ./setup/vpn_config.sh "${DIRECTORY}"

echo ""
echo ""

echo "goto_scripts.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "goto_scripts.sh: "
time ./setup/goto_scripts.sh "${DIRECTORY}"

echo ""
echo ""

echo "container_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "container_setup.sh: "
time ./setup/container_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"host links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "host_links_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "host_links_setup.sh: "
time ./setup/host_links_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"layer2 links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "layer2_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "layer2_setup.sh: "
time ./setup/layer2_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"internal links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "internal_links_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "internal_links_setup.sh: "
time ./setup/internal_links_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"external links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "external_links_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "external_links_setup.sh: "
time ./setup/external_links_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"measurement links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "measurement_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "measurement_setup.sh: "
time ./setup/measurement_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"shh links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "--cpus=1up.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "ssh_setup.sh: "
time ./setup/ssh_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"--cpus=1x links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "matrix_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
echo "matrix_setup.sh: "
time ./setup/matrix_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "--cpus=1g_scripts.sh: "
echo "create_ping_scripts.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./setup/create_ping_scripts.sh "${DIRECTORY}"

echo ""
echo ""

echo "echo \"dns links\"" >> "${DIRECTORY}"/groups/ip_setup.sh
echo "dns_setup.sh: "
echo "dns_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./setup/dns_setup.sh "${DIRECTORY}"

echo ""
echo ""

echo "add_bridges.sh: "
echo "add_bridges.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/add_bridges.sh

echo ""
echo ""

echo "add_ports.sh: "
echo "add_ports.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/add_ports.sh

echo ""
echo ""

echo "ip_setup.sh: "
echo "ip_setup.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/ip_setup.sh
sleep 10

echo ""
echo ""

echo "dns_routes"
echo "dns_routes $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/dns_routes.sh

echo ""
echo ""

echo "l2_init_switch.sh: "
echo "l2_init_switch.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/l2_init_switch.sh

echo ""
echo ""

echo "add_vpns.sh: "
echo "add_vpns.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/add_vpns.sh

echo ""
echo ""

echo "layer2_config.sh: "
echo "layer2_config.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./setup/layer2_config.sh "${DIRECTORY}"

echo ""
echo ""

echo "--cpus=1onfig.sh: "
echo "router_config.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./setup/router_config.sh "${DIRECTORY}"

echo ""
echo ""

echo "wait" >> "${DIRECTORY}"/groups/delay_throughput.sh
echo "delay_throughput.sh: "
echo "delay_throughput.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/delay_throughput.sh

echo ""
echo ""

echo "throughput.sh: "
echo "throughput.sh $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt
time ./groups/throughput.sh

echo "END $(($(date +%s%N)/1000000))" >> "${DIRECTORY}"/log.txt

echo ""
echo ""

# restart dns server with new configs
docker exec -d DNS service bind9 restart

echo "$(date +%Y-%m-%d_%H-%M-%S)"
