# RustFS (Docker) + Nginx Host + TLS (Let's Encrypt)

## Topology
- `https://s3.example.com` -> host nginx -> `127.0.0.1:9000` (RustFS S3 API)
- `https://console.example.com` -> host nginx -> `127.0.0.1:9001` (RustFS Console)

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

## 2) Start RustFS

```bash
docker compose up -d
docker compose ps
```

RustFS is bound to localhost only:
- `127.0.0.1:9000` (S3 API)
- `127.0.0.1:9001` (Console)

## 3) DNS
Point both domains to your server public IP:
- `A  s3.your-domain.com -> <server-ip>`
- `A  console.your-domain.com -> <server-ip>`

## 4) Host Nginx reverse proxy

Create `/etc/nginx/sites-available/rustfs.conf`:

```nginx
server {
    listen 80;
    server_name s3.example.com;

    client_max_body_size 0;

    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_pass http://127.0.0.1:9000;
    }
}

server {
    listen 80;
    server_name console.example.com;

    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:9001;
    }
}
```

Enable site:

```bash
sudo ln -sf /etc/nginx/sites-available/rustfs.conf /etc/nginx/sites-enabled/rustfs.conf
sudo nginx -t
sudo systemctl reload nginx
```

## 5) Issue TLS cert (host certbot)

```bash
sudo certbot --nginx -d s3.example.com -d console.example.com
```

## 6) Auto-renew certificate

Most distro packages auto-install renewal timer. Verify:

```bash
systemctl list-timers | grep certbot
```

## Notes
- RustFS data is persisted at `./rustfs/data`.
- For production, rotate `RUSTFS_SECRET_KEY` and keep 9000/9001 not publicly exposed.
