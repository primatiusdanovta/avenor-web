# Install Nginx Dari Terminal CPanel

Panduan ini ditulis untuk terminal SSH di CPanel atau terminal server Linux biasa, bukan Git Bash lokal Windows.

## 1. Login ke terminal server
Masuk lewat Terminal di CPanel atau SSH biasa:

```bash
ssh user@host
```

## 2. Install paket yang dibutuhkan
Contoh untuk Ubuntu 22.04/24.04 dengan PHP-FPM 8.2:

```bash
sudo apt update
sudo apt install -y nginx php8.2-fpm
```

## 3. Masuk ke folder project
Sesuaikan dengan lokasi aplikasi di server:

```bash
cd /var/www/avenor-web
```

## 4. Copy konfigurasi Nginx
Karena file config ada di repo, copy dari project langsung:

```bash
sudo cp infra/nginx/avenor-web.conf /etc/nginx/sites-available/avenor-web.conf
```

## 5. Sesuaikan konfigurasi bila perlu
Cek file config:

```bash
sudo nano /etc/nginx/sites-available/avenor-web.conf
```

Bagian yang biasanya perlu dicek:
- `server_name`
- `root`
- `fastcgi_pass`

Jika socket PHP-FPM berbeda, cek dengan:

```bash
ls /run/php/
```

## 6. Aktifkan site
```bash
sudo ln -sf /etc/nginx/sites-available/avenor-web.conf /etc/nginx/sites-enabled/avenor-web.conf
sudo rm -f /etc/nginx/sites-enabled/default
```

## 7. Test konfigurasi dan restart service
```bash
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl enable php8.2-fpm
sudo systemctl restart php8.2-fpm
```

## 8. Pasang SSL
Jika domain sudah mengarah ke server:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d avenorperfume.site -d www.avenorperfume.site
```

## 9. Setelah deploy code via git
Jalankan dari folder project:

```bash
cd /var/www/avenor-web
composer install --no-dev --optimize-autoloader
npm install
npm run build
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## 10. Catatan CPanel
- Jika hosting CPanel Anda shared hosting biasa, sering kali Anda tidak punya akses install `nginx` atau `systemctl`
- Panduan ini cocok untuk VPS atau dedicated server yang kebetulan memakai CPanel
- Jika server dikelola penuh oleh provider, bagian install service mungkin perlu dijalankan oleh admin server
