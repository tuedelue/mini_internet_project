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

# create web files
mkdir -p "${DIRECTORY}"/groups/webserver/
echo '<html>' \
	'  <head>' \
	'    <title>Mini Internet</title>' \
	'  </head>' \
	'  <body>' \
	'    <h1>Mini Internet</h1>' \
	'    <ul>' \
	'      <li><a href="matrix">connectivity matrix</a></li>' \
	'      <li><a href="looking_glass">looking glass</a></li>' \
	'    </ul>' \
	'  </body>' \
	'</html>' > "${DIRECTORY}"/groups/webserver/index.html
mkdir -p "${DIRECTORY}"/groups/webserver/looking_glass
mkdir -p "${DIRECTORY}"/groups/webserver/matrix
mkdir -p "${DIRECTORY}"/groups/webserver/matrix/css
cp "${DIRECTORY}"/docker_images/webserver/*.css "${DIRECTORY}"/groups/webserver/matrix/css 

for ((k=0;k<group_numbers;k++)); do
    group_k=(${groups[$k]})
    group_number="${group_k[0]}"
    group_as="${group_k[1]}"
    group_config="${group_k[2]}"
    group_router_config="${group_k[3]}"

    mkdir "${DIRECTORY}"/groups/webserver/looking_glass/G"${group_number}" || true
done


# start webserver container
docker run -itd --name="WEBSERVER" --hostname="webserver" -p 80:80 --cpus=4 --pids-limit 500 \
	-v "${DIRECTORY}"/groups/webserver/:/var/www/html/ \
	--privileged d_webserver

