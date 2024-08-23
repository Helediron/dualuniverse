# Autostart MyDU in Linux server boot

- This guide assumes you used a username "server". If you used something else, repllace all paths in files  /user/server with /user/\<youruserid\> .
- Pick file mydu.service. Edit the file and verify the paths. Copy it to /etc/systemd/system .

```sh
cd
wget https://raw.githubusercontent.com/Helediron/dualuniverse/master/MyDU-Autostart/mydu.service
nano mydu.service
sudo mv mydu.service /etc/systemd/system
```

- Pick files start_mydu.sh and stop_mydu.sh and place them into folder where your mydu folder is. If you installed mydu into /home/server, then place the files there.

```sh
cd
wget https://raw.githubusercontent.com/Helediron/dualuniverse/master/MyDU-Autostart/start_mydu.sh
wget https://raw.githubusercontent.com/Helediron/dualuniverse/master/MyDU-Autostart/stop_mydu.sh
chmod +x *mydu.sh
```

- Make systemd to recognize the new service:

```sh
sudo systemctl daemon-reload
sudo systemctl enable mydu
```

- Test the start/stop functionality:

```sh
sudo systemctl start mydu
sudo systemctl stop mydu
```

The scripts test that you are root or using sudo. The startup waits few minutes Docker to start. The startup stops all containers before starting, so it acts also as a restart.
