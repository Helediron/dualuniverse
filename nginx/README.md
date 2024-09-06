# Customized MyDU reverse proxy configuration.

These are modified versions of vanilla nginx reverse proxy in MyDU server. Log format is also modified, including request body.

## Logging

The server access log goes out of container, into MyDU ./logs/nginx-access.log

## Caching

There is moderate, 24h caching of voxels and orleans. Usercontent is not cached being local static files, but it turns on client caching. Not-changed (304) responses are cached five minuts, and not-found (404) are cached one minute. Access of elements *should* be versioned, but if element show no updating, that should clear in five minutes with these settings.

# Malware protection

The server rejects all other access except MyDU traffic. Rejected connections are rate-limited and disconnected.

- Any other hostname than DU server gets rejected.
- For API servers any URL outside /public gets rejected.
