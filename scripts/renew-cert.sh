#!/usr/bin/env sh
set -eu

docker compose run --rm certbot renew --webroot -w /var/www/certbot
docker compose exec nginx nginx -s reload

echo "Renew done and nginx reloaded."
