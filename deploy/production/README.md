# SSH Upload Guide

## Files in this folder
- `release-package.zip`: aplikasi yang siap diunggah ke server
- `import.sql`: dump PostgreSQL lengkap dengan schema dan data
- `ssh-upload-example.sh`: contoh upload dan ekstraksi via SSH

## Recommended flow
1. Upload `release-package.zip` dan `import.sql` ke server.
2. Extract release ke folder aplikasi.
3. Copy `.env.prod` menjadi `.env` lalu isi secret production.
4. Jalankan optimize command Laravel.
5. Import database bila diperlukan.
