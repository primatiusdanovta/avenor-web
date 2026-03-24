# Rangkuman Proyek Avenor Web

## Deskripsi Proyek
Avenor Web adalah sistem manajemen operasi bisnis yang dibangun dengan Laravel 12 + Vue 3/Inertia.js. Sistem ini mengelola penjualan, inventori, tim marketing, dan kalkulasi biaya barang (HPP) dengan 4 peran pengguna: Superadmin, Admin, Marketing, dan Reseller.

## Fitur Utama

### 1. Modul HPP (Harga Pokok Penjualan)
- **Fungsi**: Menghitung biaya produk berdasarkan bahan baku
- **Formula**: `harga_final = ((persentase / 100) * 50) * harga_satuan`
- **Integrasi**: Otomatis update `product.harga_modal`
- **Akses**: Hanya Superadmin
- **File Utama**: `resources/js/Pages/Hpp/Index.vue`, `app/Http/Controllers/HppController.php`

### 2. Manajemen Bahan Baku
- Master data bahan baku dengan satuan, harga, dan stok
- Input untuk kalkulasi HPP
- Model: `RawMaterial.php`

### 3. Manajemen Produk
- CRUD produk dengan gambar
- Harga modal (dari HPP) vs harga jual
- Integrasi dengan stok onhand
- Model: `Product.php`

### 4. Tracking Absensi & GPS Marketing
- Check-in/check-out real-time dengan koordinat GPS
- Penugasan area dan monitoring coverage
- KPI: jumlah kunjungan, ketepatan waktu, coverage area
- Model: `Attendance.php`, `MarketingLocation.php`

### 5. Sistem Penugasan Produk Onhand
- Workflow approval multi-step:
  - Marketing request → Pending → Admin approve → Field sales → Request return → Pending return → Admin approve → Stok kembali
- Tracking status take dan return
- Model: `ProductOnhand.php`

### 6. Penjualan Offline & Promosi
- Penjualan oleh Marketing/Reseller dengan upload bukti
- Sistem promosi dengan kode diskon (validasi tanggal, qty min, amount min)
- Approval admin untuk non-manager
- Integrasi dengan inventori onhand

## Arsitektur Teknis

### Backend (Laravel)
- **Routes**: 40+ endpoint di `routes/web.php`
- **Models**: 9 model utama dengan custom primary keys
- **Controllers**: Role-based access control
- **Database**: PostgreSQL (dengan konversi ke MariaDB tersedia)

### Frontend (Vue 3 + Inertia)
- **Layout**: `AppLayout.vue` dengan AdminLTE CSS
- **Components**: `Select2Input.vue` untuk dropdown
- **State Management**: Props dari Inertia, kalkulasi lokal di Vue

### Database Schema
- Tabel utama: users, products, raw_materials, hpp_calculations, attendances, dll.
- Foreign keys dengan CASCADE delete
- Timestamps manual (bukan auto)

## Integrasi
- **Inertia.js**: Bridge antara Laravel dan Vue
- **Vite**: Build tool untuk assets
- **AdminLTE**: UI framework
- **GPS Tracking**: Browser geolocation API
- **File Upload**: Bukti pembelian dan gambar produk

## Masalah & Saran Perbaikan

### 🔴 Masalah Kritis

1. **Magic Number di HPP Logic**
   - Lokasi: `app/Http/Controllers/HppController.php#L92`
   - Masalah: `* 50` hard-coded tanpa penjelasan
   - Dampak: Perubahan formula mempengaruhi backend dan frontend
   - Saran: Buat konfigurasi atau dokumentasi business rule

2. **Celah Validasi**
   - ProductOnhand: Tidak ada constraint unik - memungkinkan duplikasi request
   - RawMaterial: Input harga + quantity + harga_satuan tanpa validasi konsistensi
   - OfflineSale: Tidak ada pencegahan penjualan di luar sistem onhand

3. **Inkonsistensi Schema Absensi**
   - Migrasi menghapus `area_id` tapi file lama masih mereferensikannya
   - Saran: Cleanup dan dokumentasi tracking area

4. **Duplikasi Kalkulasi State**
   - Fungsi seperti "remaining quantity" dihitung ad-hoc di controller
   - Saran: Pindah ke model sebagai accessor

5. **Duplikasi Data GPS**
   - Koordinat disimpan di `attendances` dan `marketing_locations`
   - Saran: Tentukan single source of truth

### ⚠️ Observasi Lain

- **Penamaan Status Inkonsisten**: `approval_status` vs `take_status`
- **Timestamp Manual**: Tidak ada auto-management
- **State Kompleks di Frontend**: Recalculate di setiap render
- **Query N+1**: `with()` tidak konsisten
- **Auth Custom**: Tidak ada Sanctum, terbatas untuk API

### 💡 Rekomendasi

1. **Ekstrak Magic Number**: Buat setting di config/database
2. **Tambah Constraint Unik**: Pada `(user_id, id_product, assignment_date)` untuk ProductOnhand
3. **Konsolidasi Kalkulasi**: Pindah ke model ProductOnhand
4. **Dokumentasi GPS Strategy**: Putuskan single source of truth
5. **Tambah Layer API**: Jika ada integrasi mobile di masa depan
6. **Tambah Test**: Khususnya logic approval ProductOnhand
7. **Refactor Frontend State**: Gunakan computed properties atau Pinia untuk state management

## Kesimpulan
Proyek ini memiliki struktur yang baik dengan pemisahan role yang jelas dan pola Laravel yang solid. Modul HPP sederhana namun magic number merupakan risiko maintenance. Fokus perbaikan pada validasi, konsistensi data, dan dokumentasi business logic akan meningkatkan reliability sistem.</content>
<parameter name="filePath">c:\Project\avenor-web\rangkuman.md