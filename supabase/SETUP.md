# Panduan Setup Supabase — MyITSBook

Proyek Supabase aktif: **`MyITSBook`** (Organisasi `Kel5_Tekber`)  
URL Proyek: `https://ipttkvilafopfrrhpixl.supabase.co`

## 1. Skema Database ([schema.sql](./schema.sql))
Skema database sudah diterapkan ke proyek Supabase dan bersifat *idempotent* (aman dijalankan ulang di **SQL Editor**). Skema mencakup:
- 7 tabel dengan **Row Level Security (RLS)** aktif: `profiles`, `seller_profiles`, `books`, `wishlists`, `conversations`, `messages`, `notifications`.
- Tabel `seller_profiles` yang disinkronkan otomatis lewat trigger untuk menampilkan identitas publik penjual tanpa mengekspos NRP, email, atau nomor telepon.
- RPC `is_nrp_available(p_nrp)` untuk pengecekan keunikan NRP sebelum registrasi.
- Trigger otomatis pembuatan profil baru (`handle_new_user`), proteksi kolom sensitif (`guard_profile_updates`), sinkronisasi pesan terakhir (`handle_new_message`), dan notifikasi perubahan status buku (`handle_book_status_change`).
- Storage bucket `book-covers` (maks. 5 MB, JPG/PNG) dengan policy per folder pemilik (`auth.uid()`).
- Publikasi Realtime pada `messages`, `conversations`, `notifications`, dan `books`.

## 2. Verifikasi Email 2 Langkah (Gmail)
Aplikasi Flutter mendukung verifikasi pendaftaran melalui **kode OTP (6–8 digit)** maupun **tautan konfirmasi email** di Bottom Sheet verifikasi.

Pastikan pengaturan berikut di **Supabase Dashboard**:
1. Buka **Authentication → Providers → Email**:
   - **Enable Email provider**: `ON`
   - **Confirm email**: `ON` *(wajib aktif agar pengguna baru harus verifikasi email sebelum masuk)*
2. *(Disarankan untuk pengiriman ke Gmail tanpa batas 2 email/jam)* Buka **Project Settings → Authentication → SMTP Settings**:
   - Aktifkan **Enable Custom SMTP**
   - Gunakan Gmail App Password (`smtp.gmail.com`, port `465` SSL atau `587` TLS) atau layanan SMTP transaksional (Resend/Brevo).
3. *(Opsional untuk menampilkan kode OTP secara jelas di email Gmail)* Buka **Authentication → Email Templates → Confirm signup** dan pastikan template memuat kode `{{ .Token }}` di samping tautan `{{ .ConfirmationURL }}`:
   ```html
   <h2>Konfirmasi Pendaftaran MyITSBook</h2>
   <p>Masukkan kode verifikasi berikut di aplikasi MyITSBook:</p>
   <p><strong>{{ .Token }}</strong></p>
   <p>Atau klik tautan ini: <a href="{{ .ConfirmationURL }}">Konfirmasi Akun</a></p>
   ```

## 3. Data Contoh Katalog (Opsional)
1. Daftarkan minimal 1 akun mahasiswa melalui aplikasi (dan selesaikan verifikasi email).
2. Jalankan [seed.sql](./seed.sql) di **SQL Editor** untuk menambahkan beberapa contoh buku kuliah, kamus, dan novel.

## 4. Keamanan API Key
- Aplikasi Flutter hanya menggunakan **Publishable Key** (`sb_publishable_...`), yang aman untuk klien publik karena seluruh tabel dilindungi RLS.
- **Jangan pernah** menempatkan `sb_secret_...` atau `service_role` key pada kode Flutter atau repository Git.
