# Install Nginx Untuk Production

Contoh ini untuk Ubuntu 22.04/24.04 dengan PHP-FPM 8.2.

## 1. Install paket
```bash
sudo apt update
sudo apt install -y nginx php8.2-fpm
```

## 2. Copy konfigurasi site
```bash
sudo cp infra/nginx/avenor-web.conf /etc/nginx/sites-available/avenor-web.conf
```

## 3. Sesuaikan konfigurasi
Ubah bagian berikut bila perlu:
- `server_name`
- `root`
- `fastcgi_pass`

Jika PHP-FPM Anda bukan `php8.2-fpm.sock`, cek socket aktif:
```bash
ls /run/php/
```

## 4. Aktifkan site
```bash
sudo ln -s /etc/nginx/sites-available/avenor-web.conf /etc/nginx/sites-enabled/avenor-web.conf
sudo rm -f /etc/nginx/sites-enabled/default
```

## 5. Test dan reload
```bash
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl enable php8.2-fpm
sudo systemctl restart php8.2-fpm
```

## 6. SSL
Jika domain sudah mengarah ke server:
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d avenorperfume.site -d www.avenorperfume.site
```

## 7. Setelah deploy code
```bash
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```
