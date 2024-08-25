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

./scripts/up.sh
exit 0
