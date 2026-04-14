# Flutter Sweetie App

## Update Pekerjaan 2026-04-14

Dokumen ini khusus untuk `mobile/flutter_sweetie_app`.

## Ringkasan Re-check

Hasil re-check terbaru menunjukkan dokumen update `2026-04-12` sudah tidak cukup mewakili kondisi app saat ini. Beberapa flow utama Sweetie memang sudah berjalan, tetapi banyak CRUD owner module masih belum selesai atau masih gagal saat dipakai.

Temuan penting dari codebase saat ini:
- Owner modules masih memakai fallback `mock` untuk beberapa data seperti `products`, `product-knowledge`, dan `notifications`.
- Beberapa modul masih ditandai `read_only`, misalnya `notifications`, `account-receivables`, dan `online-sales`.
- Form owner generic masih memakai input tanggal teks `YYYY-MM-DD`, belum `datepicker`.
- Success state tambah/edit/delete masih `SnackBar`, belum popup success dengan logo.
- Konfirmasi hapus masih dialog standar `Hapus ... ini?`, belum copy final `Apakah anda ingin hapus data?` dengan tombol `Iya` dan `Tidak`.
- Login screen lama di `lib/src/screens/login_screen.dart` masih card standar putih, belum background pink-ungu dengan garis tipis putih.

## Update Yang Dikerjakan 2026-04-14

- [x] Migration `2026_04_14_000056_add_amount_to_account_payables_table.php` sudah dijalankan ke database lokal.
- [x] Migration `2026_04_14_000057_add_revenue_target_fields_to_sales_targets_table.php` sudah dijalankan ke database lokal.
- [x] Bug blocker API mobile owner tanpa session web sudah diperbaiki:
  - [x] `StoreContext::currentStore()` tidak lagi memaksa akses session pada request mobile token
  - [x] fallback store mobile sekarang memakai primary store assignment user
  - [x] `initializeSession()` dan `setCurrentStore()` sekarang aman untuk request tanpa session
- [x] Audit CRUD real owner modules dengan data API nyata sudah dijalankan untuk:
  - [x] `products`
  - [x] `product-knowledge`
  - [x] `hpp`
  - [x] `raw-materials`
  - [x] `extra-toppings`
  - [x] `notifications`
  - [x] `expenses`
  - [x] `account-receivables`
  - [x] `account-payables`
  - [x] `sales-targets`
  - [x] `promos`
  - [x] `customers`
  - [x] `users`
  - [x] `sops`
- [x] Semua modul audit di atas sudah lolos flow real:
  - [x] `GET`
  - [x] `POST`
  - [x] `PUT`
  - [x] `DELETE`
- [x] Data audit sementara berhasil dibersihkan kembali setelah verifikasi delete.
- [x] Queue mobile sekarang menghitung `waktu berjalan` dari `created_at` pesanan offline sales/kasir pertama kali dibuat.
- [x] Nomor antrian pada card queue sekarang ditampilkan dengan format `dd/mm/yy - n`.
- [x] Card queue mobile dirapikan per antrian:
  - [x] nomor antrian di pojok kiri atas
  - [x] waktu berjalan di pojok kanan atas
  - [x] blok `Nama Pemesan`
  - [x] blok `Detail Order` per item
  - [x] topping tambahan ditampilkan sebagai chip agar tidak berantakan
  - [x] detail order tetap rapi saat ada sampai 6 item berbeda dalam 1 antrian
- [x] Dashboard owner diperbarui untuk menampilkan `offline sales`, `online sales`, dan `waste material` dengan simbol minus.
- [x] Ringkasan tim owner diganti menjadi `Top 3 Product Terjual`.
- [x] Data `Top 3 Product Terjual` ditambahkan dari backend mobile dashboard.
- [x] Form owner generic untuk field tanggal sekarang memakai `datepicker`.
- [x] Dropdown select pada owner form diperbaiki agar perubahan pilihan tersimpan dan tampil dengan benar.
- [x] Popup success dengan logo ditambahkan untuk tambah, edit, dan delete pada owner module generic.
- [x] Konfirmasi delete diubah menjadi `Apakah anda ingin hapus data?` dengan tombol `Iya` dan `Tidak`.
- [x] Notifications owner diubah dari read-only menjadi CRUD basic:
  - [x] tambah
  - [x] edit
  - [x] delete
- [x] Account payable ditambah field `nominal` pada mobile:
  - [x] field UI
  - [x] payload API mobile
  - [x] model backend
  - [x] migration database baru
- [x] Tampilan login utama di `lib/main.dart` diubah ke background pink-ungu dengan garis tipis putih.
- [x] Login screen lama di `lib/src/screens/login_screen.dart` ikut diselaraskan ke tema pink-ungu agar tidak tertinggal jauh dari runtime utama.
- [x] Product owner mobile sekarang sudah memakai form khusus:
  - [x] multi variant lebih dari 1 item
  - [x] field `nama`, `harga`, `total satuan`
  - [x] pilih default variant
  - [x] upload foto product dari galeri
- [x] Backend mobile owner module `products` sekarang sudah kirim dan simpan:
  - [x] `variants`
  - [x] `image_url`
  - [x] multipart upload untuk `gambar`
- [x] Owner module sekarang punya aksi `view` untuk melihat detail data tanpa masuk mode edit.
- [x] HPP sekarang punya aksi `view` untuk melihat komposisi raw material.
- [x] Queue owner diubah menjadi full page.
- [x] Header owner dirapikan:
  - [x] icon antrian dipindah ke sisi paling kiri pada mode compact
  - [x] icon kasir diletakkan di area tengah action header
  - [x] icon refresh diletakkan bersebelahan dengan logout
- [x] Product knowledge mobile dirapikan agar tidak lagi fokus ke field stock/harga pada form list owner.
- [x] Product knowledge mobile sekarang punya form khusus upload foto dari galeri.
- [x] Create/update `product-knowledge` mobile diselaraskan agar tidak lagi bergantung ke payload product full (`harga` dan `stock`).
- [x] Delete product knowledge di backend mobile owner module sekarang didukung.
- [x] Account receivables mobile owner sekarang sudah punya CRUD basic:
  - [x] tambah
  - [x] edit
  - [x] delete
  - [x] view
- [x] Sales target backend/mobile dirapikan:
  - [x] field target revenue ditambahkan ke model dan migration
  - [x] delete target penjualan ditambahkan
  - [x] basis target ditandai `Revenue` atau `Botol Terjual`
- [x] Raw materials owner sekarang menampilkan `waste materials` dengan simbol minus pada tabel/detail.
- [x] Target penjualan owner sekarang menampilkan aksi `Tambah` saat target per-role belum pernah disimpan.
- [x] Verifikasi selesai:
  - [x] `php -l app/Http/Controllers/Api/Mobile/DashboardController.php`
  - [x] `php -l app/Http/Controllers/Api/Mobile/OwnerModuleController.php`
  - [x] `php -l app/Models/AccountPayable.php`
  - [x] `php -l app/Models/SalesTarget.php`
  - [x] `php -l database/migrations/2026_04_14_000056_add_amount_to_account_payables_table.php`
  - [x] `php -l database/migrations/2026_04_14_000057_add_revenue_target_fields_to_sales_targets_table.php`
  - [x] `dart analyze lib/main.dart lib/owner_modules.dart lib/src/screens/login_screen.dart`
  - [x] `dart analyze lib/main.dart lib/owner_modules.dart`

## Status Yang Sudah Ada

- [x] Owner tidak wajib check in untuk mengakses penambahan barang, penjualan barang, dan menu kasir.
- [x] Queue sudah punya tombol close.
- [x] Queue sudah menampilkan nama customer.
- [x] Queue sudah menampilkan detail pesanan dan quantity.
- [x] Queue sudah menampilkan nomor antrian dengan format `dd/mm/yy - n`.
- [x] Queue sudah menampilkan waktu berjalan berdasarkan waktu order offline sales dibuat.
- [x] Queue sudah memakai card per antrian dengan layout yang tetap rapi untuk detail item banyak.
- [x] Popup success setelah transaksi kasir selesai sudah ada.
- [x] Product kasir Sweetie sudah mendukung pemilihan varian saat transaksi penjualan.

## Re-check Dashboard dan Navigasi

- [x] Dashboard owner: tambahkan `total waste materials` dengan simbol minus.
- [x] Dashboard owner: tambahkan ringkasan `penjualan offline`.
- [x] Dashboard owner: tambahkan ringkasan `penjualan online`.
- [x] Hapus ringkasan tim dan ganti dengan `Top 3 Product Terjual Terbanyak`.
- [x] Dashboard owner sudah tidak lagi memakai ringkasan tim untuk area tersebut.
- [x] Queue sudah full page.
- [x] Queue sudah menampilkan tambahan topping jika ada pada setiap item.
- [x] Queue sudah menampilkan waktu berjalan dari `created_at` penjualan offline/kasir.
- [x] Queue sudah menampilkan nomor antrian dengan format `dd/mm/yy - n`.
- [x] Layout card queue tetap rapi walau satu antrian memuat 6 item berbeda.
- [x] Posisi icon header utama sudah dirapikan:
  - [x] icon antrian di paling kiri
  - [x] icon kasir di tengah area action
  - [x] icon refresh di sebelah logout

## Re-check CRUD Owner Modules

### Product
- [x] Form tambah/edit product khusus sudah dibuat.
- [x] Tambah lebih dari 1 variant sudah didukung di mobile.
- [x] Variant product sudah mendukung `nama`, `harga`, `total satuan`, dan multi-variant.
- [x] Tambah foto product dari galeri sudah didukung.
- [x] View data product sudah ada.
- [x] Edit data product sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk product sudah lolos pada data store nyata.

### HPP
- [x] Product pada halaman HPP sudah lolos audit API real dengan data nyata audit.
- [x] Raw material pada halaman HPP sudah lolos audit API real dengan data nyata audit.
- [x] View data HPP sudah ada.
- [x] Edit data HPP sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk HPP sudah lolos.

### Raw Materials
- [x] Tambah raw materials sudah ada.
- [x] View data raw materials sudah ada.
- [x] Edit data raw materials sudah ada.
- [x] Total waste materials ditampilkan dengan simbol minus.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk raw materials sudah lolos.

### Extra Topping
- [x] Tambah extra topping sudah ada.
- [x] View data extra topping sudah ada.
- [x] Edit data extra topping sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk extra topping sudah lolos.

### Notifications
- [x] Notifications tidak lagi hanya view.
- [x] Tambah notifications sudah dibuat.
- [x] Edit notifications sudah dibuat.
- [x] Delete notifications sudah dibuat.
- [x] View detail notifications sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk notifications sudah lolos.

### Product Knowledge
- [x] Tambah foto sudah bisa dari form mobile khusus product knowledge.
- [x] Field stok tidak lagi ditampilkan pada form list product knowledge owner.
- [x] Field harga tidak lagi ditampilkan pada form list product knowledge owner.
- [x] Delete data product knowledge sudah didukung dari backend mobile owner module.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk product knowledge sudah lolos.

### Pengeluaran
- [x] Tanggal pengeluaran sekarang memakai `datepicker`.
- [x] Tambah pengeluaran sudah ada.
- [x] Edit pengeluaran sudah ada.
- [x] View detail pengeluaran sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk pengeluaran sudah lolos.

### Account Receivable
- [x] Tidak lagi hanya view.
- [x] Tambah sudah ada.
- [x] Edit sudah ada.
- [x] Delete sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk account receivable sudah lolos.

### Account Payable
- [x] Nominal sudah ada di form/data table mobile.
- [x] Tanggal sekarang memakai `datepicker`.
- [x] Tambah account payable sudah ada.
- [x] Edit account payable sudah ada.
- [x] View detail account payable sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk account payable sudah lolos.

### Target Penjualan
- [x] Tambah target penjualan sudah ada.
- [x] Tampilan target sudah menandai basis `revenue` atau `botol terjual`.
- [x] Edit target penjualan sudah final via form per-role.
- [x] Delete target penjualan sudah ada.
- [x] View detail target penjualan sudah ada.
- [x] Audit API real untuk update target penjualan `karyawan` dan `revenue_target` sudah lolos, lalu data asli dipulihkan kembali.

### Promo
- [x] Tambah promo sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk promo sudah lolos.

### Users
- [x] Perbaikan dropdown owner form sudah dilakukan untuk role/status.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk users sudah lolos.
- [x] Tambah user sudah ada.
- [x] Edit user sudah ada.
- [x] Delete user sudah ada.
- [x] View detail user sudah ada.

### Customers
- [x] Tambah customer sudah ada.
- [x] Edit customer sudah ada.
- [x] Delete customer sudah ada.
- [x] View detail customer sudah ada.
- [x] Tanggal customer sudah memakai `datepicker`.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk customers sudah lolos.

### SOP
- [x] Tambah SOP sudah ada.
- [x] Edit SOP sudah ada.
- [x] View SOP sudah ada.
- [x] Delete SOP sudah ada.
- [x] Audit CRUD API real (`GET/POST/PUT/DELETE`) untuk SOP sudah lolos.

## Re-check Error Global CRUD

- [x] Audit kode tidak lagi menunjukkan blanket error `505` untuk semua owner module.
- [x] Endpoint owner modules sudah diaudit:
  - [x] `GET /owner/modules/{module}`
  - [x] `POST /owner/modules/{module}`
  - [x] `PUT /owner/modules/{module}/{record}`
  - [x] `DELETE /owner/modules/{module}/{record}`
- [x] Smoke test real API sudah dijalankan untuk modul prioritas `products`, `raw-materials`, `extra-toppings`, `expenses`, `customers`, `users`, dan `sops`.
- [x] Bug utama yang ditemukan dari audit real adalah dependensi session pada flow mobile owner; blocker ini sudah diperbaiki.
- [x] Audit real lanjutan juga sudah lolos untuk `hpp`, `product-knowledge`, `notifications`, `account-receivables`, `account-payables`, `sales-targets`, dan `promos`.

## Re-check Popup dan UX

- [x] Tambahkan popup success dengan logo setelah tambah data.
- [x] Tambahkan popup success dengan logo setelah edit data.
- [x] Tambahkan popup success dengan logo setelah delete data.
- [x] Saat delete, gunakan popup: `Apakah anda ingin hapus data?`
- [x] Tombol konfirmasi delete harus `Iya` dan `Tidak`.

## Re-check Login

- [x] Halaman login utama memakai background pink dan ungu.
- [x] Garis tipis putih ditambahkan pada background login utama.
- [x] Screen login lama ikut diperbarui mendekati desain final.

## Catatan Kode Saat Re-check

- `mobile/flutter_sweetie_app/lib/main.dart`
  - dashboard owner sudah diperbarui ke metrik penjualan offline/online, waste, dan top 3 produk
  - owner module fetch/store/update/delete diarahkan ke endpoint `/owner/modules/...`
  - payload owner module sekarang mendukung multipart upload untuk file
  - mode mock masih aktif sebagai fallback pada kondisi tertentu
- `mobile/flutter_sweetie_app/lib/owner_modules.dart`
  - generic form tanggal sudah memakai datepicker
  - select field owner form sudah diperbaiki
  - notifications tidak lagi read-only
  - delete confirmation dan success feedback sudah disesuaikan
  - product owner sudah memakai dialog khusus multi-variant + upload foto
  - view detail owner modules sudah ditambahkan
- `app/Support/StoreContext.php`
  - context store sekarang aman dipakai oleh request mobile bearer token tanpa session web
  - fallback store untuk request tanpa session memakai primary store assignment user
- `mobile/flutter_sweetie_app/lib/src/screens/login_screen.dart`
  - UI login sudah diarahkan ke tema pink-ungu
- `app/Http/Controllers/Api/Mobile/OwnerModuleController.php`
  - product mobile owner sekarang mendukung variants, image upload, dan delete product knowledge
  - notifications owner sudah CRUD
  - account payable sudah mendukung nominal
  - account receivables sekarang sudah CRUD
  - sales target sekarang sudah mendukung delete
- `app/Models/SalesTarget.php`
  - field revenue target sudah diselaraskan dengan controller mobile

## Temuan Tambahan Setelah Pengerjaan

- Endpoint mobile owner module sebenarnya sudah tersedia di backend untuk banyak modul, jadi error CRUD tidak semuanya karena route belum ada.
- Audit real API membuktikan modul `products`, `raw-materials`, `extra-toppings`, `expenses`, `customers`, `users`, dan `sops` memang sudah bisa dipakai pada data nyata setelah bug session store diperbaiki.
- Audit real batch lanjutan membuktikan modul `product-knowledge`, `hpp`, `notifications`, `account-receivables`, `account-payables`, `sales-targets`, dan `promos` juga sudah lolos di data nyata.
- Akar blocker terbesar yang benar-benar ditemukan dari API nyata bukan error `505`, melainkan akses `StoreContext` yang masih mencoba membaca session browser pada request mobile bearer token.
- Penyebab error yang berhasil diidentifikasi dari sisi mobile adalah form select owner yang tidak melakukan `setState`, sehingga pilihan seperti role/status bisa terasa tidak jalan.
- Notifications sebelumnya terkunci karena definisi UI mobile dan API mobile owner module masih diposisikan read-only.
- Nominal account payable memang belum ada di struktur mobile dan model backend, jadi perlu ditambah sampai level migration.
- `mode mock` di runtime Sweetie masih berpotensi menutupi masalah data real bila tidak dimatikan saat uji CRUD.
- Gap besar product sebelumnya memang ada di integrasi mobile owner:
  - payload mobile belum membawa `variants`
  - upload foto belum dikirim sebagai multipart
  - owner list belum punya aksi `view`
- Gap nyata yang masih tersisa di dokumen lama adalah `product-knowledge`:
  - form mobile khusus upload foto belum ada
  - create backend masih memakai validasi `product` penuh sehingga rawan gagal jika mobile hanya kirim nama/deskripsi/foto
  - gap ini sekarang sudah diselaraskan
- Queue sebelumnya masih bottom sheet, sehingga tidak sesuai kebutuhan operasional antrian yang lebih fokus.
- Status "belum bisa" untuk beberapa CRUD sekarang kemungkinan tersisa di level uji API real, bukan lagi semata-mata karena komponen UI belum dibuat.
- Beberapa item backlog CRUD ternyata tertinggal di dokumen, karena route `GET/POST/PUT/DELETE /owner/modules/...` dan handler controller-nya sudah tersedia untuk modul seperti `raw-materials`, `extra-toppings`, `expenses`, `account-payables`, `promos`, `customers`, `users`, dan `sops`.
- Migration `amount` account payable dan migration revenue sales target sebelumnya memang belum dijalankan di DB lokal audit; keduanya sekarang sudah applied.
- `sales_targets` ternyata belum punya kolom revenue target di model/schema mobile path yang sedang dipakai, jadi itu sebelumnya sangat berpotensi membuat target revenue tidak persisten dengan benar.
- Data queue dari backend mobile sudah membawa `created_at`, sehingga waktu berjalan bisa dihitung langsung dari waktu order offline sales dibuat tanpa perlu field tambahan baru.
- Data lama bisa saja masih menyimpan `sale_number` dengan tahun 4 digit, jadi UI queue sekarang menormalkan tampilannya ke `dd/mm/yy` agar tetap konsisten di board.
- Untuk antrian dengan item banyak, layout teks biasa rawan cepat terlihat padat; pemecahan menjadi sub-card per item membuat 6 item masih lebih mudah dibaca kasir/board.

## Saran Lanjutan

- Lanjutkan audit CRUD real per modul dengan data API nyata, terutama `products`, `raw-materials`, `extra-toppings`, `expenses`, `customers`, `users`, dan `sops`.
- Batch prioritas CRUD real yang diminta sekarang sudah selesai dan lolos untuk `products`, `raw-materials`, `extra-toppings`, `expenses`, `customers`, `users`, dan `sops`.
- Batch audit real lanjutan juga sudah selesai dan lolos untuk `product-knowledge`, `hpp`, `notifications`, `account-receivables`, `account-payables`, `sales-targets`, dan `promos`.
- Migration baru untuk `account_payables.amount` dan revenue target sekarang sudah applied di DB lokal audit.
- Matikan `mock mode` saat smoke test owner modules agar hasil CRUD benar-benar memakai data backend.
- Fokus berikutnya yang masih belum selesai penuh adalah:
  - verifikasi manual UI Flutter di device untuk memastikan flow popup, upload file, dan state refresh sesuai hasil API yang sekarang sudah lolos
- Jalankan smoke test manual khusus `product-knowledge` create/edit dengan upload gambar untuk memastikan file benar-benar tersimpan di storage publik store aktif.
- Jika `dart analyze` masih perlu dijadikan bukti verifikasi formal, jalankan lagi langsung dari environment Flutter lokal karena percobaan via terminal agent ini timeout sebelum selesai.
- Saat smoke test queue, coba skenario 1 antrian berisi 6 item berbeda dan campuran topping untuk memastikan ritme card masih nyaman dibaca pada perangkat kecil.
- Saat uji regresi offline sales, periksa bahwa nomor penjualan baru dari backend dan mock sama-sama sudah mengikuti format `dd/mm/yy - n`.

## Kesimpulan Progress

- Progress lama pada dokumen sebelumnya hanya valid untuk flow Sweetie tertentu seperti kasir, queue dasar, dan pembatasan absensi owner.
- Berdasarkan daftar issue terbaru dan hasil baca code saat ini, CRUD owner modules belum selesai dan belum stabil.
- Semua poin baru dari permintaan terbaru sudah dimasukkan ke dokumen ini sebagai backlog re-check aktif per `2026-04-14`.
- Pengerjaan terbaru pada turn ini fokus ke queue mobile Sweetie: format nomor antrian, timer berjalan dari waktu order dibuat, dan card detail order agar lebih operasional saat antrian ramai.
- Pengerjaan terbaru pada turn ini juga menutup gap `product-knowledge` owner mobile, merapikan indikator waste raw material, serta menyelaraskan checklist CRUD owner modules dengan kondisi kode aktual.
- Pengerjaan terbaru pada turn ini juga sudah mengeksekusi audit CRUD real prioritas, menjalankan migration yang tertunda, dan memperbaiki blocker session pada API owner mobile sehingga modul audit sekarang benar-benar bisa dipakai dengan bearer token.
- Pengerjaan lanjutan pada turn ini juga sudah menutup audit real untuk sisa modul owner penting, termasuk HPP dan finance modules, dengan cleanup data audit setelah test selesai.
