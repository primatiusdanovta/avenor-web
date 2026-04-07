# Avenor Web

Panel admin dan aplikasi operasional Avenor berbasis Laravel + Inertia/Vue.

## Stack
- Laravel 12
- Vue 3 + Inertia
- MariaDB
- Playwright untuk browser regression

## Development
1. Copy `.env.example` atau `.env.prod` menjadi `.env`
2. Isi koneksi database
3. Install dependency:
   - `composer install`
   - `npm install`
4. Jalankan migrasi:
   - `php artisan migrate`
5. Jalankan aplikasi:
   - `php artisan serve`
   - `npm run dev`

## Production
Panduan instalasi production ada di [DEPLOY_PROD.md](/c:/Project/avenor-web/DEPLOY_PROD.md).

File penting untuk install production:
- [sql.tambahan.sql](/c:/Project/avenor-web/sql.tambahan.sql)
- [avenor-web.conf](/c:/Project/avenor-web/infra/nginx/avenor-web.conf)
- [INSTALL_UBUNTU.md](/c:/Project/avenor-web/infra/nginx/INSTALL_UBUNTU.md)

## Verifikasi
- `php artisan test`
- `npm run build`
- `npx playwright test`
