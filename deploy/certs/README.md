# TLS certificates

Production Nginx expects `server.crt` and `server.key` in this directory. Certificate files are intentionally ignored by Git.

For local testing, generate a self-signed certificate from the repository root:

```bash
openssl req -x509 -newkey rsa:4096 -nodes -days 365 \
  -keyout deploy/certs/server.key \
  -out deploy/certs/server.crt \
  -subj "/CN=localhost"
```

Use a certificate issued for your real domain in production.
