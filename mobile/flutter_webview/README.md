# Flutter WebView Wrapper

Project ini adalah wrapper Flutter untuk membuka aplikasi web produksi Avenor melalui WebView.

## Prasyarat
- Flutter SDK
- Android SDK / Android Studio

## Langkah cepat
1. Masuk ke folder `mobile/flutter_webview`
2. Jalankan `flutter create . --platforms=android`
3. Jalankan `flutter pub get`
4. Build APK dengan:
   `flutter build apk --release --dart-define=AVENOR_WEB_URL=https://domain-produksi-anda.com`

## File utama
- `pubspec.yaml`
- `lib/main.dart`

## Catatan
- APK final belum bisa saya build di environment ini karena Flutter belum terpasang.
- URL produksi diisi melalui `--dart-define=AVENOR_WEB_URL=...`
