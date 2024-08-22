#!/bin/bash
cd /home/server/mydu
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo"
  exit 1
fi

#./scripts/down.sh
docker compose --ansi never --progress plain down
exit 0
