#!/usr/bin/env sh
set -eu

if [ ! -f .env ]; then
  echo "Missing .env. Copy from .env.example first."
  exit 1
fi

# shellcheck disable=SC1091
. ./.env

: "${RUSTFS_S3_DOMAIN:?RUSTFS_S3_DOMAIN is required}"
: "${RUSTFS_CONSOLE_DOMAIN:?RUSTFS_CONSOLE_DOMAIN is required}"
: "${LETSENCRYPT_EMAIL:?LETSENCRYPT_EMAIL is required}"

render_conf() {
  src="$1"
  dst="$2"
  sed \
    -e "s|__S3_DOMAIN__|${RUSTFS_S3_DOMAIN}|g" \
    -e "s|__CONSOLE_DOMAIN__|${RUSTFS_CONSOLE_DOMAIN}|g" \
    "$src" > "$dst"
}

# Start stack with HTTP-only config so ACME challenge works.
render_conf nginx/conf.d/rustfs-http-only.conf nginx/conf.d/default.conf

docker compose up -d rustfs nginx

docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d "${RUSTFS_S3_DOMAIN}" \
  -d "${RUSTFS_CONSOLE_DOMAIN}" \
  --email "${LETSENCRYPT_EMAIL}" \
  --agree-tos --no-eff-email

# Enable TLS config after cert is issued.
render_conf nginx/conf.d/rustfs-tls.conf nginx/conf.d/default.conf

docker compose exec nginx nginx -s reload

echo "Certificate issued and TLS config enabled."
