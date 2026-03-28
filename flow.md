# Flow Aplikasi Avenor Web

## Ringkasan Modul
- Autentikasi: login berbasis `nama` dan `password`, lalu akses dibatasi oleh role `superadmin`, `admin`, `marketing`, dan `reseller`.
- Dashboard: menampilkan ringkasan operasional per role, statistik penjualan, kehadiran, dan alert stock minimum.
- User Management: superadmin mengelola user admin, marketing, dan reseller.
- Marketing Management: superadmin/admin memantau data marketing.
- Attendance: marketing melakukan check in, check out, dan heartbeat lokasi.
- Product On Hand: marketing/reseller meminta barang, admin/superadmin menyetujui atau menolak, lalu pengembalian mengikuti status penjualan.
- Raw Material: superadmin mengelola bahan baku dan restock.
- HPP: superadmin menyusun komposisi raw material per product.
- Product: admin/superadmin mengelola product, dan penambahan stock akan mengurangi raw material sesuai HPP.
- Promo: admin/superadmin mengelola promo.
- Customer: admin/superadmin mengelola master pelanggan.
- Content Creator: admin/superadmin mengelola database content creator.
- Offline Sale: marketing/reseller/admin/superadmin membuat transaksi penjualan offline, dengan approval untuk transaksi non-manager.

## Role dan Hak Akses
- `superadmin`: akses penuh ke semua master data, approval, dashboard, raw material, HPP, customers, content creators, dan offline sales.
- `admin`: akses operasional ke marketing monitoring, approvals, products, promos, customers, content creators, dan offline sales.
- `marketing`: akses dashboard pribadi, attendance, products, dan offline sales berdasarkan stock on hand.
- `reseller`: akses dashboard pribadi, products, dan offline sales berdasarkan stock on hand.

## Alur Fitur

### 1. Login
1. User membuka `/login`.
2. User mengirim `nama` dan `password`.
3. Jika valid, user diarahkan ke `/dashboard`.
4. Navigasi, sidebar, dan alert stock dibentuk dari role user yang sedang login.

### 2. Dashboard
1. Controller membaca role user.
2. Sistem membangun quick action dan highlight sesuai role.
3. Untuk admin/superadmin:
   - hitung gross profit, net profit, top product, top marketing, top reseller, jumlah marketing, jumlah reseller, dan marketing on duty.
4. Untuk marketing/reseller:
   - hitung grafik absensi, grafik penjualan, grafik jam kerja bulanan, dan top product milik user.
5. Layout global menampilkan alert jika:
   - `products.stock < 20`
   - `raw_materials.total_quantity < 200`

### 3. Attendance Marketing
1. Marketing membuka `/marketing/attendance`.
2. Saat check in:
   - sistem menyimpan `check_in`, koordinat, status, catatan, dan event lokasi ke `marketing_locations`.
3. Saat check out:
   - sistem mengecek semua `product_onhands` hari ini.
   - jika masih ada barang yang belum habis terjual atau belum dikembalikan, checkout ditolak.
   - jika aman, sistem menyimpan `check_out` dan koordinat.
4. Browser marketing juga mengirim heartbeat lokasi berkala ke `marketing_locations`.

### 4. Pengambilan Barang
1. Marketing harus check in dulu sebelum meminta barang.
2. Marketing/reseller memilih product dan quantity.
3. Sistem membuat row `product_onhands` dengan:
   - `take_status = pending`
   - `return_status = belum`
4. Admin/superadmin membuka `/approvals`.
5. Saat approve:
   - stock `products.stock` dikurangi.
   - `take_status` berubah menjadi `disetujui`.
6. Saat reject:
   - `take_status` berubah menjadi `ditolak`.

### 5. Pengembalian Barang
1. Marketing/reseller mengirim `quantity_dikembalikan`.
2. Validasi:
   - minimum `1`
   - tidak boleh melebihi quantity dibawa
   - tidak boleh melebihi sisa barang yang belum terjual
   - tidak boleh membuat request ganda saat pending
3. Admin/superadmin melakukan approve/reject di approvals.
4. Saat approve:
   - `products.stock` ditambah sesuai quantity kembali
   - `return_status = disetujui`
5. Saat reject:
   - `quantity_dikembalikan` di-reset ke `0`
   - `return_status = tidak_disetujui`

### 6. Raw Material
1. Superadmin membuat raw material dengan:
   - `harga` per pack
   - `quantity` per pack
   - `satuan` (`ML` atau `pcs`)
   - `stock` pack
2. Sistem menghitung:
   - `harga_satuan = harga / quantity`
   - `total_quantity = stock * quantity`
   - `harga_total = stock * harga`
3. Saat restock:
   - `stock` pack bertambah
   - `total_quantity` bertambah sesuai quantity per pack
   - semua `hpp_calculation_items.total_stock` untuk raw material itu ikut disinkronkan

### 7. HPP
1. Superadmin memilih product yang sudah ada.
2. Superadmin menambah beberapa raw material untuk 1 product.
3. Aturan perhitungan:
   - jika `satuan = ML`, input HPP dibaca sebagai persentase dari basis `50`
   - rumus pemakaian: `(presentase / 100) * 50`
   - jika `satuan = pcs`, input dibaca sebagai quantity langsung
4. `harga_final` tiap item dihitung dari `pemakaian * harga_satuan`.
5. `total_hpp` adalah penjumlahan semua item.
6. Saat disimpan:
   - `hpp_calculations` dibuat/diupdate
   - `hpp_calculation_items` diganti penuh
   - `products.harga_modal` diupdate dari total HPP
   - `hpp_calculation_items.total_stock` diisi dari `raw_materials.total_quantity`

### 8. Product
1. Product baru harus dibuat dengan `stock = 0`.
2. Alasan:
   - HPP baru bisa disusun setelah product memiliki `id_product`
   - penambahan stock harus mengikuti pemotongan raw material
3. Setelah HPP selesai, admin/superadmin menaikkan stock lewat edit product.
4. Saat stock product dinaikkan:
   - sistem mengambil komposisi HPP product
   - setiap raw material dihitung pemakaiannya per product
   - total pemakaian = pemakaian per product * kenaikan stock
   - `raw_materials.total_quantity` dikurangi
   - `raw_materials.stock` dihitung ulang dari `total_quantity / quantity`
   - `hpp_calculation_items.total_stock` untuk raw material tersebut ikut diupdate
5. Jika HPP belum ada atau raw material tidak cukup:
   - update stock ditolak dengan validation error

### 9. Promo
1. Admin/superadmin membuat promo dengan:
   - `kode_promo`
   - `potongan`
   - `masa_aktif`
   - `minimal_quantity`
   - `minimal_belanja`
2. Saat offline sale memakai promo:
   - sistem mengecek promo masih aktif
   - quantity total dan subtotal harus memenuhi syarat
   - potongan dibagi proporsional ke setiap line item transaksi

### 10. Customer
1. Admin/superadmin bisa CRUD customer manual.
2. Pada offline sale, customer bisa otomatis dipakai ulang berdasarkan `no_telp`.
3. Jika customer sudah ada:
   - data existing dipakai
   - `pembelian_terakhir` diupdate
   - nama dan sosial media ikut diperbarui bila input baru tersedia
4. Jika belum ada:
   - customer baru dibuat

### 11. Content Creator
1. Admin/superadmin mengelola master `content_creators`.
2. Field `bidang` bersifat multi-pilih dan disimpan sebagai JSON array.
3. Fitur yang tersedia:
   - create
   - update
   - delete
   - list

### 12. Offline Sale
1. User membuka `/offline-sales`.
2. User dapat memilih lebih dari satu product dalam satu transaksi.
3. Untuk admin/superadmin:
   - boleh memilih product dari master product
   - transaksi langsung `disetujui`
4. Untuk marketing/reseller:
   - hanya boleh menjual product yang ada di `product_onhands` hari ini
   - transaksi dibuat `pending`
5. Customer dan promo opsional.
6. Sistem membentuk `transaction_code` untuk mengelompokkan banyak row menjadi satu transaksi.
7. Bukti pembelian diupload satu kali dan dibagikan ke semua row transaksi.
8. Admin/superadmin dapat:
   - approve transaksi
   - reject transaksi
   - edit transaksi per `transaction_code`
   - delete transaksi per `transaction_code`
9. Saat delete transaksi:
   - file bukti hanya dihapus jika sudah tidak dipakai row lain

## Event Handling yang Aktif
- Inertia progress bar saat perpindahan halaman atau submit request.
- Sidebar toggle di layout untuk desktop/mobile.
- Flash success message setelah aksi create/update/delete/approve/reject.
- Alert stock minimum global untuk admin/superadmin.
- Geolocation heartbeat per jam untuk marketing saat layout aktif.
- Event lokasi `check_in`, `check_out`, dan `heartbeat` disimpan ke `marketing_locations`.

## Relasi Antar Table

### Tabel inti
- `users`
  - one-to-many ke `attendances` melalui `user_id`
  - one-to-many ke `marketing_locations` melalui `user_id`
  - one-to-many ke `product_onhands` melalui `user_id`
  - one-to-many ke `offline_sales` melalui `id_user`

- `products`
  - one-to-one ke `hpp_calculations` melalui `id_product`
  - one-to-many ke `product_onhands` melalui `id_product`
  - one-to-many ke `offline_sales` melalui `id_product`

- `raw_materials`
  - one-to-many ke `hpp_calculation_items` melalui `id_rm`

- `hpp_calculations`
  - belongs-to `products`
  - one-to-many ke `hpp_calculation_items` melalui `id_hpp`

- `hpp_calculation_items`
  - belongs-to `hpp_calculations`
  - belongs-to `raw_materials`

- `product_onhands`
  - belongs-to `users`
  - belongs-to `products`
  - one-to-many ke `offline_sales` melalui `id_product_onhand`

- `offline_sales`
  - belongs-to `users`
  - belongs-to `products`
  - belongs-to `product_onhands`
  - belongs-to `promos` melalui `promo_id`
  - belongs-to `customers` melalui `id_pelanggan`
  - dikelompokkan logis dengan `transaction_code`

- `customers`
  - one-to-many ke `offline_sales`

- `promos`
  - one-to-many ke `offline_sales`

- `content_creators`
  - tabel master mandiri

- `attendances`
  - belongs-to `users`
  - dipakai untuk status hadir, check in/out, dan kalkulasi dashboard

- `marketing_locations`
  - belongs-to `users`
  - menyimpan histori lokasi event marketing

### Tabel legacy / struktural
- `areas`
  - masih ada di schema karena riwayat migration attendance lama
  - saat ini tidak dipakai flow runtime aktif setelah refactor attendance

## Konsistensi Data yang Dijaga Sistem
- Product baru wajib dibuat dengan stock `0`.
- Penambahan stock product hanya valid setelah HPP ada.
- Semua pemakaian raw material saat stock product naik mengikuti aturan ML/PCS yang sama.
- Customer tidak diduplikasi jika `no_telp` sudah ada.
- Offline sale multi-product selalu dikelompokkan dengan `transaction_code`.
- Bukti pembelian tidak dihapus jika masih dipakai transaksi lain.
- Pengembalian barang tidak bisa dilakukan dua kali dalam status pending.

## Catatan Audit dan Perbaikan yang Sudah Dilakukan
- Layout dipusatkan ke pipeline Vite + AdminLTE v4 agar aset tidak campur antara paket lama dan baru.
- `transaction_code` ditambahkan ke mass assignment `OfflineSale`.
- Migrasi `000021` dibuat kompatibel dengan PostgreSQL dan SQLite untuk testing.
- Product create dengan stock awal positif sekarang ditolak agar flow HPP dan konsumsi raw material konsisten.
- Dead code yang tidak punya route aktif dihapus:
  - `app/Http/Controllers/MarketingKpiController.php`
  - `app/Models/Area.php`
  - `resources/js/Pages/Marketing/Kpi.vue`
- Test contoh lama diganti dengan test fitur yang benar-benar memeriksa flow aplikasi.
