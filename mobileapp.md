# Flutter Sweetie App

## Update Pekerjaan 2026-04-12

Dokumen ini khusus untuk `mobile/flutter_sweetie_app`.

## Checklist Implementasi

### Phase 1. Role, Navigasi, dan Tampilan Owner
- [x] Dashboard owner di mobile dibuat mengikuti pola website dan fokus ke data keuntungan tanpa bar chart atau pie chart
- [x] Dashboard existing owner yang lama tidak lagi menjadi alur utama
- [x] Warna aktif aplikasi pada flow Sweetie diarahkan ke kombinasi pink-ungu yang lebih lembut
- [x] Top bar memakai `notifications`
- [x] Top bar owner memiliki shortcut `Kasir`
- [x] Top bar tetap memuat `logout`
- [x] Icon antrian tersedia pada bar atas dan membuka panel antrian
- [x] Struktur menu owner mengikuti:
  `Dashboard`, `Stock and Inventory`, `Karyawan`, `Finance`, `Pengaturan`
- [x] Struktur menu karyawan mengikuti:
  `Absensi`, `Kasir`, `Product Knowledge`
- [x] Owner modules tetap memakai pola popup form seperti website untuk create/edit

### Phase 2. Absensi Owner dan Karyawan
- [x] Absensi owner dinonaktifkan sebagai form check in/check out
- [x] Owner hanya melihat riwayat absensi karyawan
- [x] Filter absensi owner berdasarkan tanggal aktif di mobile
- [x] Backend owner attendance diblok agar owner tidak bisa submit absensi dari endpoint mobile
- [x] Karyawan tetap memiliki flow check in/check out

### Phase 3. Sales, Kasir, dan Queue
- [x] Upload bukti pembelian di flow sales Sweetie dihapus dari alur submit
- [x] Field `No Telp` dihapus dari flow kasir Sweetie
- [x] Field `TikTok/Instagram` dihapus dari flow kasir Sweetie
- [x] QRIS image dapat dibuka besar lewat popup
- [x] Pada popup QRIS tersedia tombol `Sudah Bayar`
- [x] Konfirmasi QRIS hanya wajib jika gambar QRIS memang tersedia
- [x] Setelah transaksi selesai muncul popup success dengan logo
- [x] Nomor penjualan mengikuti format `dd/mm/yyyy - no_penjualan`
- [x] Queue mobile menampilkan nomor penjualan, nama pemesan, dan detail product
- [x] Queue item bisa di-close
- [x] Queue di mock flow ikut ter-update saat transaksi berhasil disimpan

### Phase 4. Sweetie Tanpa Relasi On Hand / Consign
- [x] Flow checkout Sweetie tidak memakai relasi `product_onhand`
- [x] Backend Sweetie sales tidak memaksa relasi `onhand`
- [x] Product kasir Sweetie dibaca dari stok toko, bukan stok onhand user
- [x] Validasi quantity Sweetie memakai stok product toko
- [x] Flow Sweetie tidak memakai consign untuk checkout karyawan
- [x] Info alur stok kasir tidak lagi bergantung pada warning onhand lama

## Apa Yang Saya Buat

- Mengubah backend `OfflineSaleController` agar mode Sweetie memakai stok toko langsung, mengirim `remaining/stock` yang benar ke kasir, dan memvalidasi quantity berdasarkan stok product.
- Mengubah backend `AttendanceController` agar role owner tidak bisa submit absensi dari mobile dan hanya bisa melihat riwayat absensi karyawan.
- Merapikan `mobile/flutter_sweetie_app/lib/main.dart` untuk flow owner dashboard, queue sheet, QRIS popup, submit kasir, serta warna aktif pada area kasir.
- Mengubah `mobile/flutter_sweetie_app/lib/sales_submit_service.dart` agar mock sales Sweetie ikut mengurangi stok katalog dan menambahkan data queue.
- Memperbarui widget test `mobile/flutter_sweetie_app/test/sales_flow_test.dart` agar sesuai dengan tampilan histori transaksi saat ini.

## Hasil Pengecekan

- [x] `php -l app/Http/Controllers/Api/Mobile/AttendanceController.php`
- [x] `php -l app/Http/Controllers/Api/Mobile/OfflineSaleController.php`
- [x] `dart analyze lib/main.dart lib/sales_submit_service.dart`
- [x] `flutter test test/sales_flow_test.dart`

Hasil verifikasi terakhir:
- `dart analyze`: `No issues found!`
- `flutter test test/sales_flow_test.dart`: `All tests passed!`

## Temuan Setelah Re-check

- `mobile/flutter_sweetie_app/lib/main.dart` adalah runtime utama yang terverifikasi untuk flow Sweetie saat ini.
- Masih ada shell lama di `mobile/flutter_sweetie_app/lib/src/screens/home_shell.dart` yang belum sepenuhnya seragam dengan runtime utama. Ini tidak memblokir hasil verifikasi sekarang, tetapi berpotensi membingungkan maintenance berikutnya.
- `flutter test` menampilkan info dependency yang sudah punya versi lebih baru, tetapi itu tidak memblokir build/test saat pengecekan ini.

## Saran

- Satukan source of truth UI Sweetie ke satu shell utama agar `main.dart` dan shell lama tidak berjalan paralel secara konsep.
- Setelah itu, lanjutkan smoke test manual di device untuk owner modules CRUD popup, queue close, dan dashboard owner dengan data real store.
- Jika ingin repo lebih bersih, tahap berikutnya sebaiknya hapus atau rapikan kode Sweetie lama yang sudah tidak dipakai lagi.
