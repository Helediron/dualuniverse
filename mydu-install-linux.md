WIP!




My install procedure for MyDU server

- Create a Linux virtual machine, here i'm using Ubuntu server 24.4 LTS
    - set static IP address to (as an example) 10.10.10.40
    - 
- Set up dynamic DNS.
    - Add A record mydu.example.com, assuming you receive address 1.2.3.4 .
    - Add CNAME records:
    - 
- Set up Cloudflare tunnelling.
    - Set up proxied address du-backoffice.example.com to https, 10.10.10.40 . In connection settings, TLS, Turn on Disable SSL certificate verification.
