# Flutter Sweetie App

Aplikasi Flutter native mobile untuk role `owner` dan `karyawan` Smoothies Sweetie. Project ini fokus untuk platform mobile (`android` dan `ios`) dan memakai endpoint `api/mobile/*` dari backend Laravel.

## Fitur Utama

- login token-based khusus owner dan karyawan
- dashboard KPI pribadi
- absensi check-in / check-out + lokasi GPS
- request pengambilan barang
- monitoring barang on hand
- request pengembalian barang
- input penjualan offline dengan bukti pembelian
- product knowledge
- mode demo untuk smoke test tanpa backend aktif

## Menjalankan App Native

```bash
cd mobile/flutter_sweetie_app
flutter pub get
flutter run -d android --dart-define=SWEETIE_API_BASE_URL=http://10.0.2.2:8000/api/mobile
```

Untuk production, ganti base URL:

```bash
flutter run -d android --dart-define=SWEETIE_API_BASE_URL=https://your-domain.com/api/mobile
```

## Build APK Release

Build standar:

```bash
cd mobile/flutter_sweetie_app
flutter build apk --release --dart-define=SWEETIE_API_BASE_URL=https://your-domain.com/api/mobile
```

Kalau di Windows muncul crash Flutter tool seperti `Could not start thread DartWorker: 22` saat `assembleRelease`, itu bisa berasal dari output animasi CLI ke console, bukan dari Gradle build-nya. Pakai helper ini agar log diarahkan ke file:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-sweetie-apk.ps1
```

Alternatif permanen di mesin lokal:

```bash
flutter config --no-cli-animations
```

## Maestro Mobile

Flow Maestro native disiapkan di `.maestro/mobile`:

- `01-demo-smoke.yaml`: buka app, masuk mode demo, lalu cek halaman Dashboard, Absensi, Inventory, Sales, dan Knowledge
- `02-demo-sales-submit.yaml`: submit penjualan demo dari form native

Contoh menjalankan Maestro pada emulator Android:

```bash
maestro test .maestro/mobile/01-demo-smoke.yaml
maestro test .maestro/mobile/02-demo-sales-submit.yaml
```

`appId` yang dipakai adalah `com.sweetie.flutter_sweetie_app`.

## Backend Production MariaDB

Backend Laravel sudah mendukung `mariadb` di `config/database.php`. Set `.env` production seperti ini:

```env
APP_ENV=production
APP_URL=https://your-domain.com
DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=avenor
DB_USERNAME=your_user
DB_PASSWORD=your_password
MOBILE_TOKEN_EXPIRES_DAYS=30
```

Lalu jalankan:

```bash
php artisan migrate --force
```

Migrasi mobile yang wajib ikut adalah tabel `mobile_access_tokens`.

## Catatan

- project web/desktop Flutter sudah dibersihkan agar fokus ke mobile native
- flow bisnis mengikuti backend store `smoothies_sweetie`, termasuk absensi sebelum penjualan dan mode mobile tanpa onhand/consign
- Maestro belum bisa dijalankan di environment ini karena belum ada emulator/device Android yang terdeteksi


