# Production Deployment Checklist

## 1. Server Requirements
- PHP 8.2+
- Composer 2+
- Node.js 20+
- MariaDB 10.6+
- Nginx or Apache

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

### Option B - MariaDB SQL import
- import file: `database/sql/mariadb_schema.sql`
- then seed initial app users if needed

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

## 7. Post Deploy Smoke Check
- login page opens
- dashboard loads for superadmin/admin/marketing
- product create/edit page loads
- HPP page loads and saves
- raw material restock works
- offline sale create works
- customer CRUD works
- content creator CRUD works

## 8. Current Verification State
Already verified in local/dev environment:
- `php artisan test` passes
- `npm.cmd run build` passes

## 9. Flutter Wrapper
Mobile wrapper source exists in `mobile/flutter_webview`.
Build APK on a machine with Flutter SDK:
- `cd mobile/flutter_webview`
- `flutter create . --platforms=android`
- `flutter pub get`
- `flutter build apk --release --dart-define=AVENOR_WEB_URL=https://your-production-domain.com`
