#!/bin/bash

cd mydu

if [ "$EUID" -ne "0" ]
  then echo "Please run as root or sudo"
  exit 1
fi

# Replace the hostname mydu.example.com with your own.
host="mydu.example.com"
goodip="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
extip=$(dig +short $host)
status=$?
if [ "$status" -gt 0 ]; then
  echo "Failed to get hostname $host"
  exit 2
fi
if [[ "$extip" =~ $goodip ]]; then
  echo "Good external IP: $extip ."
else
  echo "Host $host got invalid IP $extip."
  exit 2
fi

myip=$(grep external_host config/dual.yaml | sed -e 's/\s*external_host:\s*//g')
status=$?
if [ "$status" -gt 0 ]; then
  echo "Failed to extract current IP from config/dual.yaml"
fi
if [[ "$myip" =~ $goodip ]]; then
  echo "Good config IP: $myip ."
else
  echo "Config file invalid IP $myip."
fi

if [ "$extip" == "$myip" ]; then
  echo "Public IP unchanged $myip ."
else
  echo "Changing public ip from $myip to $extip ."
  sed -i -e "s/external_host:.*/external_host: $extip/g" config/dual.yaml

  # Restart the service. But test first...
  #./scripts/down.sh
  #./scripts/up.sh
fi

