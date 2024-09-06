# Customized MyDU reverse proxy configuration.

These are modified versions of vanilla nginx reverse proxy in MyDU server.

## Caching

There is moderate, 24h caching of voxels, orleans. Usercontent is not cached being local static files, but it turns on client caching.

# Malware protection

The server rejects all other access except MyDU traffic. Rejected connections are rate-limited and disconnected.

- Any other hostname than DU server gets rejected.
- For API servers any URL outside /public gets rejected.
