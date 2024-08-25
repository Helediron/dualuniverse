#!/bin/bash

function waitfor() {
  local attempt=0
  local secs="${3:-60}"
  echo -n "Waiting $1 "
  while ! nc -z $1 $2; do
    if [ $attempt -le $secs ]; then
      attempt=$(( $attempt + 1 ))
      echo -n "."
    else
      echo " Connection to $1 $2 unavailable."
      break
    fi
    sleep 1
  done
}

mkdir -p logs_old
rm logs_old/* 2>/dev/null
mv logs/* logs_old

docker-compose up -d kafka postgres mongo rabbitmq redis zookeeper smtp
sleep 5
waitfor kafka 9092
waitfor postgres 5432
waitfor rabbitmq 5672
waitfor mongo 27017
waitfor redis 6379
waitfor zookeeper 2181
waitfor smtp 25

docker-compose up -d voxel market constructs
sleep 5
waitfor voxel 8081
waitfor market 8080
waitfor constructs 12003

docker-compose up -d orleans queueing
sleep 5
waitfor orleans 10111
waitfor queueing 9630

docker-compose up -d node
sleep 2

docker-compose up -d front
sleep 2

docker-compose up -d backoffice nodemanager nginx prometheus logrotate
sleep 5
waitfor backoffice 12000
waitfor nodemanager 12005
waitfor nginx 443
waitfor prometheus 9090

echo "up done"

