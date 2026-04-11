# Smoothies Sweetie Multi-Store Rollout

## Checklist Implementasi

- [x] Menambahkan `master store` dengan store existing `avenor_perfume`
- [x] Menambahkan store baru kosong `smoothies_sweetie`
- [x] Menambahkan akun utama store sweetie `admin_swetiee`
- [x] Menambahkan role checklist berbasis permission
- [x] Menerapkan role checklist ke user management existing
- [x] Menambahkan assignment user ke store
- [x] Menambahkan store switcher di layout aplikasi
- [x] Memisahkan data existing ke store `avenor_perfume`
- [x] Menjaga data `smoothies_sweetie` tetap kosong saat awal setup
- [x] Menambahkan halaman `Master Store`
- [x] Menambahkan halaman `Roles`
- [x] Menambahkan filter store aktif ke dashboard
- [x] Menambahkan filter store aktif ke products
- [x] Menambahkan filter store aktif ke raw materials
- [x] Menambahkan filter store aktif ke HPP
- [x] Menambahkan filter store aktif ke offline sales
- [x] Menambahkan filter store aktif ke online sales
- [x] Menambahkan filter store aktif ke expenses
- [x] Menambahkan filter store aktif ke account receivables
- [x] Menambahkan filter store aktif ke account payables
- [x] Menambahkan filter store aktif ke customers
- [x] Menambahkan filter store aktif ke notifications
- [x] Menambahkan filter store aktif ke attendance
- [x] Menambahkan filter store aktif ke approval/onhand management
- [x] Menambahkan fallback store default untuk data existing/test tanpa `store_id`
- [x] Memastikan build frontend berhasil
- [x] Memastikan seluruh test backend lulus

## Akun dan Store Awal

- [x] Store existing: `avenor_perfume`
- [x] Store baru: `smoothies_sweetie`
- [x] Superadmin dapat melihat dan mengedit seluruh store
- [x] Akun utama sweetie: `admin_swetiee`
- [x] Role akun `admin_swetiee`: admin full access
- [x] Scope akses `admin_swetiee`: hanya store `smoothies_sweetie`
- [x] Password awal `admin_swetiee`: `AdminSweetie123!`

## Alur Kerja Per Menu

### 1. Master Store

- [x] Superadmin membuka menu `Master Store`
- [x] Superadmin dapat menambah store baru
- [x] Superadmin dapat mengubah `code`, `name`, `display_name`, `status`, `timezone`, `currency`, dan `address`
- [x] Store aktif dipilih dari dropdown di header

Handling:
- Jika user tidak punya izin `stores.view`, halaman ditolak
- Jika user tidak punya izin `stores.manage`, tombol tambah/edit tidak tersedia
- Jika store switch diarahkan ke store di luar akses user, request ditolak

Kondisi khusus:
- `display_name` dipakai sebagai identitas visual store aktif
- Data existing otomatis dianggap milik `avenor_perfume`

### 2. Roles

- [x] Role dikelola lewat menu `Roles`
- [x] Setiap role memiliki `key`, `name`, `legacy_role`, `description`, dan daftar permission checklist
- [x] User saat dipilihkan role akan mewarisi checklist permission role itu

Handling:
- Role sistem terkunci tidak bisa dihapus
- Role yang masih dipakai user tidak bisa dihapus

Kondisi khusus:
- `legacy_role` menjaga kompatibilitas dengan flow existing seperti admin, marketing, dan sales field executive
- Checklist permission menjadi sumber utama akses menu

### 3. Users

- [x] User baru dibuat dengan `username`, `status`, `role checklist`, `store access`, dan password
- [x] User existing sekarang menampilkan role checklist dan store yang dimiliki
- [x] Saat memilih role, checklist akses tampil langsung di form

Handling:
- Non-superadmin hanya bisa assign user ke store aktif yang dia kelola
- User yang sedang login tidak bisa menghapus dirinya sendiri
- Validasi username tetap unik

Kondisi khusus:
- User dengan satu role bisa ditempatkan ke satu atau beberapa store
- Role checklist menentukan hak akses menu

### 4. Dashboard

- [x] Dashboard selalu mengikuti store aktif
- [x] KPI, chart, inventory alert, dan summary hanya menghitung data store aktif
- [x] Superadmin dan admin melihat mode manager
- [x] Marketing dan sales field executive melihat mode seller

Handling:
- Tanpa permission `dashboard.view`, halaman ditolak
- Inventory alert hanya membaca stock dan raw material store aktif

Kondisi khusus:
- Perubahan store dari header langsung mengubah konteks dashboard

### 5. Products

- [x] Daftar produk manager hanya membaca produk store aktif
- [x] Marketing/sales hanya bisa mengambil barang dari product store aktif
- [x] Tambah/edit/hapus product tersimpan per store
- [x] Approval pengambilan dan pengembalian ikut store aktif

Handling:
- Nama produk unik per store
- Product baru tetap wajib stock awal `0`
- Penambahan stock tetap mengurangi raw material store yang sama

Kondisi khusus:
- Jika HPP belum dibuat, penambahan stock tetap diblok
- Onhand dan approval tidak bisa lintas store

### 6. Raw Materials

- [x] Raw material dipisahkan per store
- [x] Restock hanya menambah stock pada store aktif
- [x] Nama raw material unik per store

Handling:
- Update raw material ikut menyinkronkan `hpp_calculation_items`
- Akses butuh `raw_materials.view` atau `raw_materials.manage`

Kondisi khusus:
- Data raw material existing otomatis masuk `avenor_perfume`

### 7. HPP

- [x] Perhitungan HPP dibaca dan disimpan per store
- [x] Product dan raw material yang dipakai harus berasal dari store aktif

Handling:
- Item raw material tidak boleh duplikat
- Validasi product/raw material dibatasi ke store aktif

Kondisi khusus:
- HPP yang dihapus hanya memengaruhi product di store yang sama

### 8. Offline Sales

- [x] Penjualan offline selalu tersimpan dengan `store_id`
- [x] Product, promo, customer, dan onhand difilter sesuai store aktif
- [x] Reuse customer hanya berlaku di store yang sama

Handling:
- Approval offline sale hanya untuk data store aktif
- Bukti pembelian tetap dipakai bersama per transaksi
- Marketing/sales tidak bisa menjual melebihi onhand store aktif

Kondisi khusus:
- Admin bisa input tanggal manual
- Marketing tetap mengikuti batasan check-in/check-out existing

### 9. Online Sales

- [x] Import online sale sekarang masuk ke store aktif
- [x] Index online sale hanya membaca store aktif
- [x] Online sale item ikut store aktif

Handling:
- Import akan rebuild data online sales pada store aktif saja
- Product matching hanya mencari product dari store aktif

Kondisi khusus:
- Jika store baru belum punya product, order tetap masuk tetapi product match bisa kosong sesuai behavior existing

### 10. Expenses

- [x] Pengeluaran dipisahkan per store
- [x] Summary bahan baku, operasional, dan total mengikuti store aktif

Handling:
- Edit/hapus expense dibatasi ke store aktif

Kondisi khusus:
- Creator expense tetap tercatat seperti existing

### 11. Account Receivables

- [x] Data receivables dibatasi ke store aktif

Handling:
- Hanya role dengan permission `account_receivables.view` yang dapat membuka halaman

Kondisi khusus:
- Existing receivables otomatis menjadi milik `avenor_perfume`

### 12. Account Payables

- [x] Data payables dibatasi ke store aktif
- [x] Create/update/delete payables sekarang menyimpan `store_id`

Handling:
- Edit/hapus payable hanya bisa pada record store aktif

Kondisi khusus:
- Existing payables otomatis menjadi milik `avenor_perfume`

### 13. Customers

- [x] Customer dipisahkan per store
- [x] Nomor telepon unik per store
- [x] Riwayat pembelian terakhir dibaca per store

Handling:
- Reuse customer pada offline sale hanya mencari customer dalam store aktif

Kondisi khusus:
- Customer dengan no telepon sama bisa ada di store berbeda bila dibutuhkan nanti

### 14. Notifications

- [x] Notification backend dipisah per store
- [x] Index, create, edit, publish, delete mengikuti store aktif

Handling:
- User tanpa `notifications.manage` hanya bisa lihat jika punya `notifications.view`

Kondisi khusus:
- Target role existing tetap didukung

### 15. Attendance

- [x] Attendance dan marketing location menyimpan `store_id`
- [x] Riwayat absensi, location terakhir, dan barang bawaan hanya dari store aktif

Handling:
- Check-in/check-out tetap memakai validasi existing
- Location heartbeat sekarang juga membawa konteks store aktif

Kondisi khusus:
- Barang belum kembali tetap memblok checkout sesuai logic existing

## Verifikasi yang Sudah Dijalankan

- [x] `npm run build`
- [x] `php artisan test`
- [x] `DashboardExperienceTest`
- [x] `InventoryFlowTest`
- [x] `OfflineSaleFlowTest`
- [x] `OnlineSaleImportTest`
- [x] `PageAccessTest`
- [x] `ProductKnowledgeTest`

## Catatan Handling Existing Data

- [x] Semua data existing ditandai ke store `avenor_perfume`
- [x] Data baru tanpa `store_id` eksplisit akan fallback ke `avenor_perfume` untuk menjaga kompatibilitas existing/test
- [x] `smoothies_sweetie` dibuat kosong sebagai store baru

## Catatan Operasional Setelah Deploy

- [x] Login sebagai `superadmin`, cek menu `Master Store`, `Roles`, dan `Users`
- [x] Login sebagai `admin_swetiee`, pastikan hanya store `smoothies_sweetie` yang terlihat
- [x] Tambahkan user baru dari `admin_swetiee` dan pilih store/role checklist
- [x] Pindah store dari dropdown header untuk membandingkan data `avenor_perfume` dan `smoothies_sweetie`
