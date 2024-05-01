#!/bin/bash
#set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR"

docker run -t \
           --expose=21161 \
           --expose=21162 \
           --expose=21163 \
           --expose=21164/udp \
           --expose=21165 \
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
           --relay=true > log1.txt &

WAKU1_CONTAINER=""
while [[ -z "$WAKU1_CONTAINER" ]]; do
  WAKU1_CONTAINER=$(docker ps | grep "wakuorg/nwaku:v0.24.0" | awk '{ print $1 }')
  sleep 1
done
echo "Waku 1 container: $WAKU1_CONTAINER"

BOOTSTRAP_ENR=""
while [[ -z "$BOOTSTRAP_ENR" ]]; do
  BOOTSTRAP_ENR=$(cat log1.txt | grep -oe "enr:-[-_a-zA-Z0-9]*" | uniq | tr -d '\n')
  sleep 1
done
echo "Found bootstrap ENR: $BOOTSTRAP_ENR"

docker run -t \
           --expose=21161 \
           --expose=21162 \
           --expose=21163 \
           --expose=21164/udp \
           --expose=21165 \
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
           --nat=extip:172.18.0.3 \
           --peer-exchange=true \
           --discv5-discovery=true \
           --discv5-bootstrap-node="$BOOTSTRAP_ENR" \
           --relay=true > log2.txt &

WAKU2_CONTAINER=""
while [[ -z "$WAKU2_CONTAINER" ]]; do
  WAKU2_CONTAINER=$(docker ps | grep -v "$WAKU1_CONTAINER" | grep "wakuorg/nwaku:v0.24.0" | awk '{ print $1 }')
  sleep 1
done
echo "Waku 2 container: $WAKU2_CONTAINER"

docker network create --driver bridge --subnet 172.18.0.0/16 --gateway 172.18.0.1 waku
docker network connect waku "$WAKU1_CONTAINER"
docker network connect waku "$WAKU2_CONTAINER"

docker build -t test_suite_2 .
docker run --network waku test_suite_2

docker stop "$WAKU1_CONTAINER"
docker stop "$WAKU2_CONTAINER"
docker network rm waku

