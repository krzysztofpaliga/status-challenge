#!/bin/bash
#set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR"

docker run -t \
           -p 21161:21161 \
           -p 21162:21162 \
           -p 21163:21163 \
           -p 21164:21164 \
           -p 21165:21165 \
           wakuorg/nwaku:v0.24.0 \
           --listen-address=0.0.0.0 \
           --rest=true \
           --rest-admin=true \
           --websocket-support=true \
           --log-level=TRACE \
           --rest-relay-cache-capacity=100 \
           --websocket-port=21163 \
           --rest-port=21161 \
           --tcp-port=21162 \
           --discv5-udp-port=21164 \
           --rest-address=0.0.0.0 \
           --nat=extip:172.18.0.2 \
           --peer-exchange=true \
           --discv5-discovery=true \
           --relay=true > log.txt &

docker build -t test_suite_1 .
docker run --add-host=host.docker.internal:host-gateway test_suite_1

docker ps | grep wakuorg/nwaku | awk '{ print $1}' | xargs docker stop

