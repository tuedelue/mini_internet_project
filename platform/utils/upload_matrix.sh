#!/bin/bash

while true
do
    cp groups/matrix/matrix.html groups/webserver/matrix/index.html
    time=$(ls -lisa groups/webserver/matrix/index.html | awk '{print $8 " " $9 " " $10}')
    sed -i "s/updated\./updated. <b>${time}<\/b>./g" groups/webserver/matrix/index.html
    echo 'matrix sent'
    sleep 1
done
