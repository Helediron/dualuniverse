#!/bin/bash
cd /home/server/mydu

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo"
  exit 1
fi
date +"%Y-%m-%dT%H:%M:%S%:z" >> logs/startup.log
date +"%Y-%m-%dT%H:%M:%S%:z"


attempt=0
while [ $attempt -le 59 ]; do
    attempt=$(( $attempt + 1 ))
    echo "Waiting for server to be up (attempt: $attempt)..."
    rep=$(curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null)
    status=$?

    if [ "$status" == "0" ]; then
      echo "Docker is up!" >> logs/startup.log
      echo "Docker is up!"
      break
    fi
    sleep 2
done


#Stop before start
docker compose --ansi never --progress plain down
sleep 5

#./scripts/up.sh
docker-compose --ansi never --progress plain up -d kafka postgres mongo rabbitmq redis zookeeper smtp --detach 2>&1 | tee -a logs/startup.log
sleep 10

docker compose --ansi never --progress plain up -d voxel market constructs backoffice queueing --detach 2>&1 | tee -a logs/startup.log
sleep 10

docker compose --ansi never --progress plain up -d front node orleans --detach 2>&1 | tee -a logs/startup.log
sleep 10

sleep 10
docker-compose --ansi never --progress plain up -d nodemanager nginx prometheus logrotate --detach 2>&1 | tee -a logs/startup.log

sleep 10
exit 0
