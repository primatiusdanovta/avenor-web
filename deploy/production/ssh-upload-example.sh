#!/usr/bin/env bash
set -euo pipefail

SERVER_USER="your-user"
SERVER_HOST="your-server"
SERVER_PATH="/var/www/avenor-web"
DB_NAME="avenor_web"
DB_USER="avenor_user"

scp deploy/production/release-package.zip "$SERVER_USER@$SERVER_HOST:/tmp/avenor-release.zip"
scp deploy/production/import.sql "$SERVER_USER@$SERVER_HOST:/tmp/avenor-import.sql"
scp .env.prod "$SERVER_USER@$SERVER_HOST:/tmp/avenor.env.prod"

ssh "$SERVER_USER@$SERVER_HOST" <<'EOF'
set -euo pipefail
mkdir -p "$SERVER_PATH"
unzip -o /tmp/avenor-release.zip -d "$SERVER_PATH"
cp /tmp/avenor.env.prod "$SERVER_PATH/.env"
cd "$SERVER_PATH"
php artisan key:generate --force || true
php artisan storage:link || true
php artisan config:cache
php artisan route:cache
php artisan view:cache
psql -U "$DB_USER" -d "$DB_NAME" -f /tmp/avenor-import.sql
EOF
