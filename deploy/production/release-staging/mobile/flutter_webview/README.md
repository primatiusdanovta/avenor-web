# Flutter WebView Wrapper

Project ini adalah wrapper Flutter untuk membuka panel admin produksi Avenor melalui WebView.

## Target default
- `https://avenorperfume.site/administrator`

## Prasyarat
- Flutter SDK
- Android SDK / Android Studio

## Langkah cepat
1. Masuk ke folder `mobile/flutter_webview`
2. Jalankan `flutter create . --platforms=android`
3. Jalankan `flutter pub get`
4. Build APK dengan:
   `flutter build apk --release --dart-define=AVENOR_WEB_URL=https://avenorperfume.site/administrator`

## File utama
- `pubspec.yaml`
- `lib/main.dart`

## Catatan
- Jika `--dart-define=AVENOR_WEB_URL` tidak diberikan, wrapper otomatis membuka `https://avenorperfume.site/administrator`.
- APK final belum bisa saya build di environment ini karena Flutter belum terpasang.
