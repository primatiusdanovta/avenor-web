# Production Deployment Checklist

## 1. Server Requirements
- PHP 8.2+
- Composer 2+
- Node.js 20+
- MariaDB 10.6+ atau MySQL-compatible server
- Nginx or Apache
- SSH access

## 2. Environment
1. Copy `.env.prod` to `.env`
2. Fill these values before deploy:
   - `APP_KEY`
   - `APP_URL`
   - `ADMIN_ROUTE_PREFIX`
   - `DB_CONNECTION`
   - `DB_HOST`
   - `DB_PORT`
   - `DB_DATABASE`
   - `DB_USERNAME`
   - `DB_PASSWORD`
   - `MOBILE_TOKEN_EXPIRES_DAYS`
   - mail settings
3. Generate key if needed:
   - `php artisan key:generate --force`

## 3. Database
Gunakan MariaDB dengan konfigurasi `.env.prod` berikut:

- `APP_URL=https://avenorperfume.site`
- `ADMIN_ROUTE_PREFIX=administrator`
- `DB_CONNECTION=mariadb`
- `DB_PORT=3306`

Choose one approach:

### Option A - Laravel migration
- `php artisan migrate --force`
- lanjutkan dengan seed master bila dibutuhkan:
  - `php artisan db:seed --class=DatabaseSeeder --force`

### Option B - SQL import
- import schema/data MariaDB dari file yang Anda siapkan sendiri
- command example:
  - `mysql -u avenor_user -p avenor_web < import.sql`
- jalankan patch MariaDB tambahan setelah import:
  - `mysql -u avenor_user -p avenor_web < sql.tambahan.sql`

Catatan:
- `sql.tambahan.sql` merapikan migrasi role `reseller -> sales_field_executive` dan target field team lama
- jika server production benar-benar baru, Option A biasanya lebih aman daripada import dump historis

## 4. Install & Build
- `composer install --no-dev --optimize-autoloader`
- `npm install`
- `npm run build`
- deploy code ke server via git sesuai flow operasional Anda

## 5. Nginx
- contoh konfigurasi ada di `infra/nginx/avenor-web.conf`
- langkah install Ubuntu ada di `infra/nginx/INSTALL_UBUNTU.md`
- pastikan document root mengarah ke folder `public`
- arahkan PHP ke socket atau host `php-fpm` yang sesuai versi server Anda

## 6. Storage & Optimization
- `php artisan storage:link`
- jika memakai session/cache/queue database dan tabel belum ada:
  - `php artisan session:table`
  - `php artisan cache:table`
  - `php artisan queue:table`
  - `php artisan migrate --force`
- `php artisan config:cache`
- `php artisan route:cache`
- `php artisan view:cache`

## 7. Queue / Scheduler
If queue is used in production:
- run worker with supervisor/systemd
- schedule cron:
  - `* * * * * php /path/to/artisan schedule:run >> /dev/null 2>&1`

## 8. Post Deploy Smoke Check
- login page opens
- dashboard loads for superadmin
- `/administrator/field-team` loads
- role switch `Marketing / Sales Field Executive` works
- `Kelola Onhand` modal opens from `/administrator/product-onhands`
- product landing page loads
- global settings save works
- landing page builder save works
- offline sale create works
- proof URL mobile mengarah ke `https://avenorperfume.site/...`

## 9. Flutter Wrapper
Mobile wrapper source exists in `mobile/flutter_webview`.
Build APK on a machine with Flutter SDK:
- `cd mobile/flutter_webview`
- `flutter create . --platforms=android`
- `flutter pub get`
- `flutter build apk --release --dart-define=AVENOR_WEB_URL=https://avenorperfume.site/administrator`

## 10. Flutter Marketing App Endpoint
Untuk app native `mobile/flutter_marketing_app`, endpoint tidak disimpan satu per satu di env. App hanya butuh satu base URL:

- `AVENOR_API_BASE_URL=https://avenorperfume.site/api/mobile`

Semua request mobile diturunkan dari base URL ini:

- `/auth/login`
- `/auth/me`
- `/auth/logout`
- `/dashboard`
- `/attendance`
- `/attendance/check-in`
- `/attendance/check-out`
- `/attendance/location`
- `/products`
- `/products/take`
- `/products/onhand/{onhand}/return`
- `/product-knowledge`
- `/offline-sales`
- `/offline-sales/{sale}/proof`
