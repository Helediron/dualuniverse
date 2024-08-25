#!/bin/bash
cd /home/server/mydu
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo"
  exit 1
fi

./scripts/down.sh
exit 0
