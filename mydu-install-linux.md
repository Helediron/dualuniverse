# My install procedure for MyDU server

This installation guide uses a Linux virtual server to host the MyDU service publicly.

I'm using free Cloudflare account and have purchased (as an example) **example.com** domain name from there. You need ability to manage your public DNS domain to create new A and CNAME records.

My local network is using (as an example) address **10.10.10.0/24** . The server will be installed into address (as an example) **10.10.10.40** .

It does not matter what virtualization platform you use.

Having a VPN in your desktop is very helpful. With it you can "move" yourself out from your local network to test external access. Any VPN provider is ok.

## Create a Linux virtual machine

I'm using Ubuntu server 24.4 LTS. Feel free to use any favourite distro. Install SSH and Docker Server following your distro's guidance.

- set static IPV4 address to 10.10.10.40 . (Skipping IPV6 configuration. Disabling it is fine.)
- Select install SSH. You need terminal access. You also need SSH client like Putty to connect from desktop to the new server.
- In optional components, select Docker.
- When installation is ready, try logging in from your desktop with SSH client to 10.10.10.40 . Use the account you set up when installing the server. During the very first connection the SSH client probably asks if it's ok to connect to the server because it's an unknown server. Select OK.
- I suggest to shutdown the server and take now a snapshot or copy/backup the virtual disk. You can then easily return back to pristine state and retry installation.

## Route from client to service

Getting all addresses, ports and routes correctly is the trickiest part in MyDU installation.

Although MyDU uses multiple hostnames, they are all pointing into same, one machine. When offering the service to other players, the address is your public IP address. You also need to configure your router by adding port forwarding rules to send the traffic into your MyDU server. And further on, there is some routing inside the MyDU server.

Game client -> router public IP -> router port forwarding -> MyDU server -> container -> another container.

Only nginx and front containers bind to *external* network of the server, to 10.10.10.40 that is. All other containers bind to an *internal* Docker network using addresses 10.5.0.x . The nginx container acts as a reverse proxy, routing traffic coming in from external network into the internal network. The front container listens port 9210 for gRPC service (directly, without passing through the nginx container).

Assuming your public address is 1.2.3.4, your traffic has this route to travel:

- mydu.example.com points to 1.2.3.4 .
- All other hostnames are aliases, CNAME records pointing to mydu.example.com, thus resolving to 1.2.3.4 .
- Game client sends traffic to 1.2.3.4 to port 443.
- Your router has port forwarding rule saying to forward any traffic arriving to 443 to your internal network, to server 10.10.10.40, port 443.
- When traffic arrives to MyDU server, its nginx reverse proxy container is listening it. It looks at headers and finds e.g. hostname du-voxel.example.com. It then forwards the traffic to voxel container via docker-internal network 10.5.0.0 .
- One of the containers is an internal DNS server which defines ip addresses of each container. E.g. voxel host has ip address 10.5.0.16
- In docker-compose.yml is definition for voxel container and there it sets the container to use IP address 10.5.0.16 .
- In config/dual.yaml there are multiple places defining endpoints, e.g.

```yaml
  ...
  voxel_public_url: https://du-voxel.example.com
  ...
  voxel_service: http://voxel:8081
  ...
```

The *voxel_public_url* is the address that the game client uses. It resolves to 1.2.3.4 and *https* resolves to port 443. The *voxel_service* is the address another container is using when wanting to talk to voxel service and resolves to 10.5.0.16 inside Docker and port 8081 is explicit.

## Set up Cloudflare dynamic DNS

This step will create required DNS entries for MyDU.

Note that Cloudflare is the company and Cloudflared is a widely used tunnelling proxy. The idea is that the proxy connects from inside of your internal network to Cloudflare, and then Cloudflare finds where you are, and can route traffic from outside into your local network via that Cloudflared proxy.

There are multiple Cloudflared DDNS containers available. Just pick one which says it's doing DDNS. You can add the container into the same virtual you created, or elsewhere in you local network. The DDNS detects your public IP, and if it finds out that the address has changed, it sends the new address to Cloudflare API which updates the new address into mydu.example.com record.

Configure the DNS with Cloudflare Dashboard. Select your domain name and then DNS:

- Add **A** (type A that is - an IPv4 **A**ddress) record mydu.example.com and set this to point to some IP address. Your public IP is fine.
- Add **CNAME** records:
  - du-orleans.example.com -> mydu.example.com
  - du-queueing.example.com: not needed due to later change, which uses mydu hostname. If you skip the renaming (in config/domains.json), create the CNAME record -> mydu.example.com .
  - du-usercontent.example.com -> mydu.example.com
  - du-voxel.example.com -> mydu.example.com
  - du-backoffice.example.com: don't create if using Cloudflare tunnelling. If not using tunnelling, create the CNAME record -> mydu.example.com .
- Set up Cloudflare DDNS to update mydu.example.com .

## Set up Cloudflare tunnelling for backoffice

This is an optional step. If not doing it, make sure you create the CNAME for du-backoffice in previous chapter.

- Create a Zero Trust tunnel in Cloudflare dashboard. Select Docker. Save the token.
- In the tunnel configuration, public hostnames, set up proxied address du-backoffice.example.com to https, 10.10.10.40 . Turn on Additional Settings -> TLS -> "No TLS verify".
- Install Cloudflared Docker container (a plain version, not DDNS) in your local network and set the token to one you got for the tunnel.

Note that this is a minimum setup which already increases the security of the backoffice site. The tunnel effectively blocks direct connections to backoffice and forces traffic through Cloudflare firewall. You can further tighten security with Cloudflare tools.

## Set up MyDU service

- Open SSH terminal to the virtual server. Login with the admin user you configured during creating the virtual. Starting in your user's home directory is fine. But if you want to install mydu somewhere else, now create folder(s) and cd into right place.
- Folder "mydu" will be created in your current directory in next step and downloaded with installation stuff, about 2GB:

```sh
sudo docker run --rm -it -v ./mydu:/output novaquark/dual-server-fastinstall:latest
```

- Configuration:

```sh
sudo chown -R $USER:$USER mydu 
cd mydu
cp config/dual.yaml config/dual.yaml.ori
python3 scripts/config-set-domain.py config/dual.yaml http://mydu.example.com 10.10.10.40
mkdir prometheus-data && sudo chmod a+w prometheus-data
```

Note the "cd mydu" command. All the rest of the commands assume you are inside the mydu folder.

- First time download and start of containers:

```sh
sudo ./scripts/up.sh
```

This will take first time a long time. It downloads all container images adding about 20GB data. You may have to wait few minutes after everything has started before the service is really accessible.

You can check container status with this:

```sh
sudo docker ps
```

All containers should be running steadily. In first few minutes you may see some restarting but it should settle soon. If not, check logfiles under ./logs folder.

- Set admin password to admin:

```sh
sudo scripts/admin-set-password.sh admin admin
```

You can change the password later to a longer one via backoffice website.

- Shut down the server to continue configuration:

```sh
sudo ./scripts/down.sh
```

## Configure https certificates

- Edit config/domains.json:

```sh
nano config/domains.json
```

In nano, Ctrl+W and Enter saves the file. Ctrl+X closes the editor.

Content:

```json
{
  "tld": "example.com",
  "prefix": "du-",
  "services": {
      "queueing": "mydu"
  }
}
```

This defines the top-level domain name, handles all du-something hostnames, except name "du-queueing" will be replaced with "mydu" for queueing service. This makes the connection URL look nicer. If you decide not to rename, then use this:

```json
{
  "tld": "example.com",
  "prefix": "du-"
}
```

- In your router, add port forwardings: 80 and 443 to same ports, to 10.10.10.40 .
Note that the port 80 forwarding is temporary, needed only during the certificate generation.
- Run SSL certification generation:

```sh
sudo ./scripts/ssl.sh --create-certs
```

Answer the questions and make sure certificates get generated successfully. The script starts a temporary webserver and the certificate authority will try to connect to your server to verify your domain is valid. If this fails, make sure you did have port 80 correctly forwarded to your server.

- Continue SSL configuration:

```sh
sudo ./scripts/ssl.sh --config-dual 10.10.10.40
sudo ./scripts/ssl.sh --config-nginx
```

- Edit file docker-compose.yml and change nginx reverse proxy external ports. All services will use same https incoming port 443. (Note: the reverse proxy combines the services into one incoming port. It sorts out the services by looking server name in http headers.)

```sh
nano docker-compose.yml
```

Find section with line "nginx:", then section "ports:" under it and make it look like this:

```yaml
...
    nginx:
        image: nginx
        volumes:
          - ./nginx:/etc/nginx
          - ./data:/data   # need access to user_content
          - ./letsencrypt:/etc/letsencrypt
        ports:
          #- "9630:9630"   # queueing service
          #- "10111:10111" # orleans (construct elements)
          #- "8081:8081"   # voxels
          #- "12000:12000" # backoffice
          #- "10000:10000" # servers user_content
          - "443:443"     # <-- enable this for SSL mode
...
```

Comment out current port mappings and uncomment the last, 443 line.

Note: certificates expire after every three months. Run this command then to renew them:

```sh
# AFTER three months:
./scripts/ssl.sh --update-certs
```

## https port forwarding

Note: using alternative port is optional but it reduces alot of intrusion attempts. When you open port 80 and/or 443 into your home network, all bots see that your IP is a web server and start poking around.

The port 9210 is gRPC service in mydu. It's not http traffic and challenging to get proxied.

### Stay on default https port 443

If you decide NOT to change default port, add these port forwarders and skip the rest of this chapter:

- In your router change port forwardings:
  - Port 443 to 443 in 10.10.10.40
  - Port 9210 to 9210 in 10.10.10.40
  - Remove all other port forwarders (like port 80).

### Move away from default https port 443

If you decide to move away from default, add these port forwarders:

- In your router change port forwardings (port 44443 is an example):
  - Port 44443 to 443 in 10.10.10.40
  - Port 9210 to 9210 in 10.10.10.40
  - Remove all other port forwarders.

- Edit file config/dual.yaml and change all public URLs by adding :44443 after each hostname EXCEPT don't change the backoffice URL. Search all example.com in the file:

```sh
nano config/dual.yaml
```

- After editing check the results:

```sh
grep example.com config/dual.yaml
```

The output should look like this:

```txt
  public_url: https://du-backoffice.example.com
  item_bank_url: https://mydu.example.com:44443/public/itembank/serialized
  orleans_public_url: https://du-orleans.example.com:44443
  user_content_cdn: https://du-usercontent.example.com:44443
  voxel_public_url: https://du-voxel.example.com:44443
  public_url: https://du-voxel.example.com:44443
```

## Test the server

- Start the service:

```sh
sudo ./scripts/up.sh
```

Note that starting of the service might take few minutes.

- Try the backoffice. If you have VPN, turn it on to "move" yourself out from home network. You might test also with phone by turning first WiFi off. Navigate in browser to <https://du-backoffice.example.com/> . Login as admin/admin. Now is great time to change the password for user "admin" . Click Users on left, enter new password for admin and click Update Password.

## Test the game

- In backoffice, create a new user.
- Start the game client.
- Log in with your **Novaquark** credentials.
- On the next, MYDU SERVERS screen enter
  - Server URL: <https://mydu.example.com:44443> (drop :44443 away if using default port.)
  - Login: username you just created
  - Password: password you just created for the user.
- Click JOIN.
