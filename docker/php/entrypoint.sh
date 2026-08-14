#!/usr/bin/env sh
set -e

cd /var/www/html

# Copy .env from example on first boot inside a fresh volume.
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

# Generate an APP_KEY if one is not present. The key stays inside
# the container's .env file — nothing is written to the host.
if ! grep -qE '^APP_KEY=base64:' .env 2>/dev/null; then
  php artisan key:generate --force >/dev/null
fi

php artisan config:clear >/dev/null 2>&1 || true

exec "$@"
