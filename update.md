# Update Proyek Avenor Web

## Ringkasan Stack

- Laravel 12
- PostgreSQL
- Inertia.js + Vue 3
- Vite
- AdminLTE

## Konfigurasi Database

Project sudah diarahkan ke PostgreSQL dengan konfigurasi berikut:

- Database: `avenor_web`
- Username: `pgsql`
- Password: `root`
- Host: `127.0.0.1`
- Port: `5432`

## Modul Yang Sudah Dibuat

### 1. Autentikasi dan Keamanan

- Login menggunakan `nama` sebagai username
- Password menggunakan hash bawaan Laravel
- Session auth memakai Laravel Auth
- Session di-regenerate setelah login
- Logout menghapus session dengan aman
- Proteksi CSRF aktif
- Rate limit login aktif
- Hanya user dengan status `aktif` yang dapat login
- Redirect setelah login langsung ke dashboard utama

### 2. Tampilan AdminLTE

- Halaman login menggunakan layout AdminLTE
- Dashboard menggunakan layout AdminLTE
- Logo login dan sidebar memakai `resources/img/primatama.png`
- Navigasi sidebar menyesuaikan role user

### 3. Struktur User dan Role

Tabel `users` menggunakan struktur berikut:

- `id_user`
- `nama`
- `status`
- `password`
- `role`
- `created_at`

Role yang aktif di sistem:

- `superadmin`
- `admin`
- `marketing`
- `reseller`

### 4. Dashboard Berbasis Role

- Dashboard utama berbasis Inertia SPA
- Deferred props digunakan untuk data statistik
- `WhenVisible` digunakan untuk lazy loading data tertentu
- Quick action berbeda untuk tiap role
- Ringkasan inventory dan statistik user tersedia di dashboard

### 5. User Management

Hanya `superadmin` yang dapat mengakses modul user management.

Fitur:

- Lihat daftar user
- Cari user
- Tambah user
- Edit user
- Hapus user

### 6. Marketing Management

Dapat diakses oleh `superadmin` dan `admin`.

Fitur:

- CRUD akun marketing
- Lihat status absensi hari ini
- Lihat lokasi terakhir marketing
- Lihat map lokasi marketing
- Lihat daftar barang yang dibawa marketing hari ini
- Lihat status request pengembalian barang
- Approval atau penolakan request pengembalian barang

### 7. Absensi Marketing

Halaman absensi hanya untuk role `marketing`.

Fitur:

- Check in otomatis
- Check out otomatis
- Tanggal, jam check in, dan jam check out diambil otomatis dari server
- Koordinat lokasi wajib aktif saat check in dan check out
- Lokasi marketing direkam otomatis setiap 1 jam
- Status absensi: `hadir`, `terlambat`, `izin`, `sakit`
- Riwayat absensi tersedia
- List barang yang dibawa hari ini tersedia di halaman absensi
- Checkout ditolak jika masih ada barang yang belum selesai diproses
- Warning checkout: `Barang belum dikembalikan`
- Jika barang habis terjual sesuai quantity yang dibawa, checkout tetap diperbolehkan tanpa input pengembalian

### 8. Product Management

Dapat diakses oleh `superadmin` dan `admin`.

Tabel `products`:

- `id_product`
- `nama_product`
- `harga`
- `harga_modal`
- `stock`
- `gambar`
- `created_at`

Fitur:

- CRUD product
- Upload gambar product
- Stock otomatis berkurang saat barang diambil marketing atau reseller
- Stock otomatis bertambah setelah pengembalian disetujui admin atau superadmin

### 9. Product On Hand Marketing dan Reseller

Halaman product untuk `marketing` dan `reseller` mengambil data dari `product_onhands`.

Tabel `product_onhands`:

- `id_product_onhand`
- `user_id`
- `id_product`
- `nama_product`
- `quantity`
- `quantity_dikembalikan`
- `return_status`
- `approved_by`
- `assignment_date`
- `created_at`

Fitur:

- Ambil barang dengan pilihan product dari master product
- Product picker sudah searchable saat memilih
- Marketing wajib absensi check in sebelum mengambil barang
- Marketing dan reseller dapat membawa lebih dari 1 product
- Tabel khusus `Pengembalian Barang Yang Dibawa Hari Ini`
- Request pengembalian barang tersedia
- Pengembalian barang wajib approval admin atau superadmin
- Status pengembalian: `belum`, `pending`, `disetujui`, `tidak_disetujui`
- Status otomatis `selesai_terjual` jika quantity penjualan sama dengan quantity barang yang dibawa
- Request baru ditolak jika masih ada pending approval
- Warning request ganda: `Masih ada antrian yang belum disetujui`
- Validasi pengembalian tidak boleh melebihi quantity pengambilan
- Validasi pengembalian tidak boleh melebihi sisa barang yang belum terjual

### 10. Penjualan Offline

Tersedia untuk `marketing`, `reseller`, `admin`, dan `superadmin`.

Tabel `offline_sales`:

- `id_penjualan_offline`
- `id_user`
- `id_product`
- `id_product_onhand`
- `promo_id`
- `nama`
- `nama_product`
- `quantity`
- `harga`
- `kode_promo`
- `promo`
- `bukti_pembelian`
- `approval_status`
- `approved_by`
- `approved_at`
- `created_at`

Fitur:

- Input penjualan offline dengan upload bukti pembelian
- Product picker sudah searchable saat memilih
- Harga otomatis diambil dari product
- Promo otomatis memotong harga jika valid
- Marketing dan reseller hanya melihat data penjualan miliknya sendiri
- Admin dan superadmin dapat melihat seluruh data penjualan
- Admin dan superadmin dapat edit, hapus, approve, dan reject penjualan
- Penjualan dari marketing dan reseller membutuhkan approval admin atau superadmin
- Penjualan untuk marketing dan reseller ditautkan ke batch product on-hand aktif hari itu
- Validasi quantity penjualan tidak boleh melebihi barang yang dibawa

### 11. Promo Management

Dapat diakses oleh `admin` dan `superadmin`.

Tabel `promos`:

- `kode_promo`
- `nama_promo`
- `potongan`
- `masa_aktif`
- `minimal_quantity`
- `minimal_belanja`
- `created_at`

Fitur:

- CRUD promo
- `kode_promo` otomatis digenerate dari nama promo dan tanggal pembuatan
- Promo expired tidak muncul di form penjualan
- Promo expired tidak bisa digunakan
- Validasi minimal quantity dan minimal belanja aktif saat penjualan dibuat
- Informasi minimal quantity dan minimal pembelian ditampilkan saat promo dipilih
- Warning promo jika syarat belum terpenuhi: `Pembelian belum mencapai syarat`

## Kredensial Akun Dummy

Gunakan akun berikut untuk login:

### Superadmin

- Username: `superadmin`
- Password: `Superadmin123!`

### Admin

- Username: `admin`
- Password: `Admin123!`

### Marketing

- Username: `marketing`
- Password: `Marketing123!`

### Reseller

- Username: `reseller`
- Password: `Reseller123!`

## Route Utama

- `/login`
- `/dashboard`
- `/users`
- `/marketing`
- `/marketing/attendance`
- `/products`
- `/promos`
- `/offline-sales`

## Migration Tambahan Penting

Migration tambahan terbaru:

- `2026_03_24_000011_add_id_product_onhand_to_offline_sales_table.php`

Fungsi migration ini:

- menambahkan `id_product_onhand` ke tabel `offline_sales`
- menghubungkan penjualan offline dengan batch barang yang dibawa
- membuat validasi stock on-hand lebih akurat per pengambilan

## Data Dummy Tambahan

Seeder saat ini juga menyiapkan:

- product dummy
- promo dummy
- riwayat absensi dummy marketing
- riwayat lokasi dummy marketing

## Status Verifikasi

Yang sudah diverifikasi:

- `php artisan migrate:fresh --seed` berhasil
- `php artisan test` berhasil lulus
- `npm run build` berhasil
- `php artisan storage:link` berhasil

## Catatan Teknis

- Upload gambar product dan bukti pembelian menggunakan disk `public`
- Link storage publik sudah dibuat ke `public/storage`
- Validasi checkout marketing bergantung pada sisa barang yang dibawa, barang terjual, dan request pengembalian
- Approval pengembalian barang dilakukan dari halaman marketing milik admin atau superadmin
- Searchable product picker digunakan di halaman product marketing, reseller, admin, superadmin, dan penjualan offline