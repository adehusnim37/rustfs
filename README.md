# RustFS + Nginx + TLS (Let's Encrypt)

## Topology
- `https://s3.example.com` -> RustFS S3 API (`rustfs:9000`)
- `https://console.example.com` -> RustFS Console (`rustfs:9001`)

## 1) Prepare env

```bash
cd /Users/adehusnim/Programming/GO/rustfs-nginx-tls
cp .env.example .env
```

Edit `.env`:
- `RUSTFS_ACCESS_KEY`
- `RUSTFS_SECRET_KEY`
- `RUSTFS_S3_DOMAIN`
- `RUSTFS_CONSOLE_DOMAIN`
- `LETSENCRYPT_EMAIL`

## 2) DNS
Point both domains to your server public IP:
- `A  s3.your-domain.com -> <server-ip>`
- `A  console.your-domain.com -> <server-ip>`

## 3) Issue first certificate

```bash
./scripts/issue-cert.sh
```

What script does:
1. Enable HTTP-only Nginx config (`nginx/conf.d/default.conf`)
2. Start `rustfs` and `nginx`
3. Run certbot webroot challenge
4. Switch to TLS Nginx config
5. Reload nginx

## 4) Check services

```bash
docker compose ps
```

Open:
- `https://$RUSTFS_S3_DOMAIN`
- `https://$RUSTFS_CONSOLE_DOMAIN`

## 5) Auto-renew certificate
Add cron on host:

```bash
0 3 * * * cd /Users/adehusnim/Programming/GO/rustfs-nginx-tls && ./scripts/renew-cert.sh >> /var/log/rustfs-cert-renew.log 2>&1
```

## Notes
- Nginx must keep port `80` open for ACME challenge renewals.
- RustFS data is persisted at `./rustfs/data`.
- For production, rotate `RUSTFS_SECRET_KEY` and lock firewall to only 80/443.
