# Update Proyek Avenor Web

## Ringkasan Teknologi

- Laravel 12
- PostgreSQL (`pgsql`)
- Inertia.js + Vue 3
- Vite
- AdminLTE telah terpasang di tahap awal proyek

## Konfigurasi Database

Project saat ini sudah diarahkan ke PostgreSQL dengan konfigurasi berikut:

- Database: `avenor_web`
- Username: `pgsql`
- Password: `root`
- Host: `127.0.0.1`
- Port: `5432`

## Fitur Yang Sudah Dibuat

### 1. Autentikasi Login

- Login menggunakan `nama` sebagai username
- Password sudah menggunakan hashing Laravel
- Session login memakai auth bawaan Laravel
- Session di-regenerate setelah login
- Logout menghapus session dengan aman
- Proteksi CSRF aktif
- Rate limit login aktif
- Redirect setelah login langsung ke dashboard utama
- Hanya user dengan status `aktif` yang dapat login

### 2. Branding Login

- Logo login menggunakan file `resources/img/primatama.png`
- Logo sudah dipublikasikan untuk dipakai di halaman login

### 3. Struktur User Custom

Tabel `users` menggunakan struktur:

- `id_user`
- `nama`
- `status`
- `role`
- `password`
- `created_at`

Role yang dipakai:

- `superadmin`
- `admin`
- `marketing`
- `reseller`

### 4. Dummy Data User

Seeder sudah dibuat untuk 4 akun dummy berdasarkan role.

### 5. Dashboard Berbasis Role

- Dashboard dibuat dengan Inertia.js
- Menu sidebar menyesuaikan role
- Ringkasan dashboard menampilkan statistik user
- Deferred props digunakan untuk data yang dimuat setelah render awal
- `WhenVisible` digunakan untuk lazy loading recent users
- Navigasi antar halaman menggunakan SPA visit Inertia

### 6. User Management Hanya Untuk Superadmin

Fitur CRUD user berbasis Inertia hanya bisa diakses oleh `superadmin`.

Fitur yang tersedia:

- Lihat daftar user
- Cari user
- Tambah user baru
- Edit user
- Hapus user
- Form create dan edit berbasis Inertia form handling
- Validasi backend untuk username unik, role, status, dan password

### 7. KPI Marketing

Halaman KPI khusus role `marketing` sudah dibuat.

KPI yang ditampilkan:

- Total absensi bulan berjalan
- Total hadir tepat waktu
- Total terlambat
- Coverage area

Tambahan:

- Ringkasan area aktif
- Riwayat absensi terbaru
- Performa area dengan deferred props

### 8. Absensi Marketing Berbasis Area

Sudah dibuat modul absensi marketing dengan tabel:

- `areas`
- `attendances`

Fitur absensi:

- Input absensi berdasarkan area
- Tanggal absensi
- Check in
- Check out
- Status: `hadir`, `terlambat`, `izin`
- Catatan aktivitas

### 9. Data Area dan Absensi Dummy

Seeder saat ini juga membuat:

- 3 area dummy
- 6 data absensi dummy untuk user marketing

## Credentials Akun Dummy

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

## Route Utama Yang Tersedia

- `/login`
- `/dashboard`
- `/users` -> hanya `superadmin`
- `/marketing/kpi` -> hanya `marketing`

## Status Verifikasi

Yang sudah diverifikasi:

- Migrasi PostgreSQL berhasil dijalankan
- Seeder berhasil dijalankan
- Build frontend berhasil
- Test otomatis Laravel berhasil lulus

## Catatan

Jika ingin melanjutkan pengembangan, langkah berikut yang disarankan:

- CRUD area untuk superadmin
- Filter KPI marketing per tanggal atau per area
- Approval workflow absensi
- Permission middleware per role yang lebih formal
