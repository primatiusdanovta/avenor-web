# Production Deployment Checklist

## 1. Server Requirements
- PHP 8.2+
- Composer 2+
- Node.js 20+
- PostgreSQL 14+
- Nginx or Apache
- SSH access

## 2. Environment
1. Copy `.env.prod` to `.env`
2. Fill these values before deploy:
   - `APP_KEY`
   - `APP_URL`
   - `DB_HOST`
   - `DB_PORT`
   - `DB_DATABASE`
   - `DB_USERNAME`
   - `DB_PASSWORD`
   - mail settings
3. Generate key if needed:
   - `php artisan key:generate --force`

## 3. Database
Choose one approach:

### Option A - Laravel migration
- `php artisan migrate --force`

### Option B - PostgreSQL SQL import
- import file: `import.sql`
- command example:
  - `psql -U avenor_user -d avenor_web -f import.sql`

## 4. Install & Build
- `composer install --no-dev --optimize-autoloader`
- `npm install`
- `npm run build`

## 5. Storage & Optimization
- `php artisan storage:link`
- `php artisan config:cache`
- `php artisan route:cache`
- `php artisan view:cache`

## 6. Queue / Scheduler
If queue is used in production:
- run worker with supervisor/systemd
- schedule cron:
  - `* * * * * php /path/to/artisan schedule:run >> /dev/null 2>&1`

## 7. SSH Upload Bundle
Prepared files are in `deploy/production`:
- `release-package.zip`
- `ssh-upload-example.sh`
- `README.md`
- `import.sql`

## 8. Post Deploy Smoke Check
- login page opens
- dashboard loads for superadmin
- product landing page loads
- global settings save works
- landing page builder save works
- offline sale create works

## 9. Flutter Wrapper
Mobile wrapper source exists in `mobile/flutter_webview`.
Build APK on a machine with Flutter SDK:
- `cd mobile/flutter_webview`
- `flutter create . --platforms=android`
- `flutter pub get`
- `flutter build apk --release --dart-define=AVENOR_WEB_URL=https://avenorperfume.site/administrator`
