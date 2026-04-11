# Laporan Pengerjaan 2026-04-11

## Yang sudah dikerjakan

### 1. Sidebar dan role/store visibility
- Menambahkan menu `SOP` ke sidebar dan visibilitasnya sekarang mengikuti permission `sops.view`.
- Merapikan struktur sidebar agar:
  - `Penjualan Offline` dan `Penjualan Online` keluar dari dropdown `Finance`.
  - Tidak ada menu double setelah deduplikasi navigasi.
  - Menu yang tidak boleh tampil di store `Smoothies Sweetie` tetap tersembunyi.
- Menu yang secara eksplisit tetap disembunyikan untuk store Sweetie:
  - `Approvals`
  - `Consign`
  - `Barang Onhand`
  - `Field Team`
  - `Content Creator`
  - `Master Store`
  - `Roles`
- Promo tetap tersedia untuk admin Sweetie dan tetap tampil di sidebar.

### 2. Halaman SOP
- Halaman SOP sudah tersedia dan sekarang bisa diakses dari sidebar.
- Hak akses halaman SOP sudah mengikuti permission:
  - `sops.view` untuk melihat
  - `sops.manage` untuk tambah/ubah/hapus

### 3. Product Knowledge untuk Smoothies Sweetie
- Filter Product Knowledge tetap dinonaktifkan untuk store Sweetie.
- Card Product Knowledge di store Sweetie tidak lagi menampilkan `fragrance detail`.
- Card sekarang menampilkan `deskripsi` product.
- Query Product Knowledge juga sudah dibatasi per store aktif, jadi data tidak tercampur lintas store.

### 4. Halaman Absensi
- Tabel `Barang Yang Dibawa Hari Ini` dinonaktifkan pada store Sweetie.
- Backend web absensi tetap mengirim `carriedProducts` kosong untuk Sweetie.
- Frontend web absensi sekarang juga tidak merender tabel tersebut jika store aktif adalah Sweetie.
- Artinya untuk Sweetie sudah tidak ada relasi tampilan aktif ke fitur onhand di halaman absensi web.

### 5. Queue board / antrian
- Auto refresh queue board tetap ada, tetapi sekarang route refresh menggunakan `adminUrl('/queue-board')`.
- Detail antrian sekarang menampilkan:
  - `Nama product`
  - `Quantity`
  - `Topping tambahan` jika ada
- Informasi `transaction_code` juga ditampilkan di card antrian.

### 6. Perbaikan 404 saat reload otomatis
- Memperbaiki path literal yang masih memakai `'/queue-board'` menjadi path berbasis prefix admin.
- Hal yang diperbaiki:
  - auto refresh di halaman queue board
  - tombol buka antrian dari halaman penjualan
  - tombol buka antrian dari halaman login
- Auto refresh di halaman penjualan offline Sweetie sudah tetap dinonaktifkan, jadi fokus realtime hanya di queue board.

### 7. Product form Sweetie
- Field `Stock Awal` pada tambah product disembunyikan untuk store Sweetie.

### 8. User/Role restrictions
- Role checklist sekarang hanya bisa ditambah/ubah/hapus oleh `superadmin`.
- Halaman users sekarang tidak menampilkan pengaturan `Store Access` untuk admin non-superadmin.

### 9. Notifikasi lintas store
- Feed notifikasi mobile sekarang difilter berdasarkan `store_id`.
- Push notification service sekarang juga memfilter device token berdasarkan store assignment user.
- Tujuannya agar notifikasi store Sweetie tidak bocor ke store lain.

### 10. Mobile app Sweetie
- Menemukan mismatch Android launch configuration:
  - `AndroidManifest.xml` menunjuk `com.sweetie.flutter_sweetie_app.MainActivity`
  - tetapi file activity yang ada berada di package lain
- Sudah ditambahkan file activity yang sesuai di:
  - `mobile/flutter_sweetie_app/android/app/src/main/kotlin/com/sweetie/flutter_sweetie_app/MainActivity.kt`
- `flutter analyze` untuk app Sweetie berhasil tanpa issue.

## Yang belum selesai / belum tervalidasi penuh

### 1. Verifikasi final crash mobile di perangkat
- Belum bisa dipastikan 100% dari sisi install di HP karena build APK debug di environment ini gagal pada tahap Gradle daemon.
- Hasil log menunjukkan penyebab build failure di environment kerja ini adalah **out of memory pada JVM/Gradle**, bukan error Dart aplikasi.
- Karena itu:
  - perbaikan `MainActivity` sangat mungkin memperbaiki crash launch yang sebelumnya terjadi
  - tetapi saya belum bisa mengonfirmasi sampai tahap install-run di device fisik dari mesin ini

### 2. Audit penuh parity alur mobile vs website
- Saya sudah merapikan fondasi utama:
  - store flags
  - QRIS URL
  - notifikasi berbasis store
  - launch configuration Android
- Tetapi saya belum melakukan audit menyeluruh untuk setiap alur mobile Sweetie satu per satu di perangkat fisik, khususnya:
  - check-in/check-out real geolocation
  - transaksi QRIS end-to-end
  - close queue dari kasir ke board lalu refresh ulang dari app mobile
  - seluruh empty state dan edge case setelah install APK nyata

### 3. Playwright Sweetie-specific flow
- Smoke test yang tersedia saat ini hanya meng-cover flow superadmin umum.
- Belum ada Playwright khusus untuk:
  - login `admin_swetiee`
  - validasi sidebar Sweetie
  - queue board Sweetie
  - product knowledge Sweetie
  - SOP Sweetie

## Temuan pada Playwright

Perintah yang dijalankan:
- `npx playwright test tests/e2e/smoke.spec.ts --project=desktop-chromium`

Hasil:
- `2 passed`
- Test yang lolos:
  - membuka dashboard, halaman users, dan search berjalan
  - membuka halaman online sales dan search table berjalan

Interpretasi:
- Build frontend pasca perubahan tetap sehat.
- Routing dasar admin masih aman.
- Namun coverage belum menyentuh fitur Sweetie yang baru dirapikan.

## Catatan keputusan teknis

### 1. Navigasi dipusatkan di `ShareStoreContext`
- Saya memilih tetap memusatkan logika sidebar utama di middleware `ShareStoreContext`.
- Alasan:
  - di repo ini sidebar sudah dibentuk dari sana
  - perubahan visibilitas menu jadi bisa berbasis kombinasi `permission + role + current store`
  - lebih mudah mencegah menu dobel

### 2. Sweetie diperlakukan sebagai feature-flag store
- Perilaku khusus Sweetie dipertahankan berbasis store aktif, bukan hardcode username.
- Alasan:
  - lebih aman saat nanti user/role Sweetie bertambah
  - konsisten dengan arsitektur multi-store yang sudah ada

### 3. Queue detail ditarik dari group transaksi
- Detail product antrian dibentuk dari group `sale_number`.
- Alasan:
  - queue board memang mewakili satu transaksi yang bisa berisi banyak line item
  - tambahan topping tetap bisa ditampilkan tanpa query baru di frontend

### 4. 404 auto refresh diperbaiki di level URL generation
- Saya tidak menambal dengan redirect tambahan.
- Saya memilih memperbaiki semua path literal yang salah ke `adminUrl(...)`.
- Alasan:
  - akar masalah ada pada prefix route admin
  - solusi ini lebih stabil dan tidak menambah lapisan hack

### 5. Mobile launch fix diprioritaskan pada package mismatch
- Dari hasil inspeksi, mismatch `MainActivity` adalah kandidat paling jelas untuk app launch failure.
- Saya prioritaskan itu dulu sebelum menyentuh kode Dart besar di `main.dart`.
- Alasan:
  - ini failure yang paling mendasar di startup Android
  - perbaikannya kecil tetapi high-impact

## Temuan teknis penting

### 1. Build Android environment bermasalah karena RAM
- File crash JVM:
  - `mobile/flutter_sweetie_app/android/hs_err_pid1436.log`
- Ringkasannya:
  - JVM kehabisan native memory saat Gradle build
  - ini adalah masalah environment build lokal, bukan bukti langsung ada bug di kode Dart

### 2. Repo masih dalam kondisi dirty
- Banyak file lain sudah berubah sejak awal sesi.
- Saya sengaja membatasi edit pada file yang relevan agar tidak merusak pekerjaan yang sudah ada.

### 3. `HandleInertiaRequests` masih punya navigasi lama
- Sidebar aktif saat ini tetap ditimpa oleh `ShareStoreContext`, jadi aplikasi berjalan benar.
- Namun middleware lama itu masih menyimpan definisi navigasi lawas dan berpotensi membingungkan maintainer.

## Saran pengembangan selanjutnya

### Prioritas tinggi
- Tambahkan Playwright khusus `admin_swetiee`:
  - login
  - verifikasi sidebar Sweetie
  - buka SOP
  - buka Product Knowledge Sweetie
  - buka Penjualan Offline
  - buka Queue Board dan cek detail item
- Jalankan install APK ke device nyata setelah memory build environment ditingkatkan.
- Tambahkan smoke test Flutter minimal:
  - app launch
  - login mock mode
  - buka halaman sales
  - pilih produk
  - tampilkan panel QRIS

### Prioritas menengah
- Rapikan `HandleInertiaRequests` agar tidak lagi menyimpan navigation lawas yang berpotensi overlap dengan `ShareStoreContext`.
- Tambahkan helper terpusat untuk menu top-level agar struktur sidebar tidak tersebar.
- Tambahkan test untuk memastikan notifikasi selalu ter-scope ke store aktif.

### Prioritas UX
- Queue board bisa ditingkatkan dengan:
  - total item per transaksi
  - label metode pembayaran
  - badge status lebih jelas
  - tombol detail/expand jika transaksi panjang
- SOP bisa ditingkatkan dengan:
  - kategori SOP
  - urutan prioritas
  - SOP aktif per shift atau per halaman

### Prioritas mobile
- Kurangi ukuran dan kompleksitas `mobile/flutter_sweetie_app/lib/main.dart` yang saat ini terlalu besar.
- Pecah menjadi modul:
  - auth/session
  - dashboard
  - attendance
  - sales
  - knowledge
  - notifications
- Tambahkan global crash reporting/logging agar crash device bisa dilacak lebih cepat.

## Ringkasan status akhir

Status yang bisa saya nyatakan selesai:
- Sidebar SOP + role-based access
- Product Knowledge Sweetie pakai deskripsi, bukan fragrance detail
- Tabel barang dibawa disembunyikan di absensi Sweetie
- Detail item di queue board
- Penjualan offline/online dipindah keluar dari Finance
- Promo tetap tampil untuk Sweetie di sidebar
- Perbaikan path 404 pada refresh/antrian web
- Perbaikan Android launch configuration yang salah

Status yang masih perlu verifikasi lanjutan:
- Konfirmasi final mobile app tidak crash saat install-run di device fisik
- Verifikasi end-to-end semua flow Sweetie di mobile setelah build environment Android stabil
