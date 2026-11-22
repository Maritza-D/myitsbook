# MyITSBook

Aplikasi mobile re-commerce dan donasi buku kuliah untuk mahasiswa Institut Teknologi Sepuluh Nopember (ITS), berfokus pada transaksi **Penjual (Seller)** dan **Pembeli (Buyer)**.

## Fitur Utama
- **Autentikasi & Verifikasi Email 2 Langkah**: Daftar akun mahasiswa (NRP unik, jurusan, WhatsApp, email Gmail/ITS) dengan verifikasi kode OTP / tautan konfirmasi email via Supabase Auth.
- **Katalog Jual & Donasi**: Pencarian judul, filter kategori (*Buku Kuliah, Kamus, Novel, Komik*), kondisi fisik, jenis listing (*Dijual / Donasi*), rentang harga, lokasi kampus ITS, dan pengurutan.
- **Publikasi & Kelola Buku**: Unggah foto sampul ke Supabase Storage (`book-covers`), atur harga atau donasi gratis, ubah status buku (*Tersedia, Dalam Proses, Terjual, Selesai*).
- **Wishlist, Pesan Realtime & Notifikasi**: Simpan buku favorit, negosiasi langsung dengan penjual melalui chat realtime, dan notifikasi otomatis perubahan status buku maupun pesan baru.
- **Desain Midnight Navy**: Tema terang & gelap adaptif, tipografi *Poppins* + *Inter*, dan seluruh dialog interaktif berbasis *Bottom Sheet*.

## Tech Stack
- **Frontend**: Flutter (Material 3)
- **Backend**: Supabase (PostgreSQL, Row Level Security, Auth, Storage, Realtime)

## Panduan Kolaborasi Tim

### 1. Clone & Install Dependensi
```bash
git clone https://github.com/Maritza-D/myitsbook.git
cd myitsbook
flutter pub get
```

### 2. Jalankan Aplikasi
Konfigurasi proyek Supabase (`MyITSBook`, organisasi `Kel5_Tekber`) sudah tertanam melalui Publishable Key aman (RLS aktif di seluruh tabel), sehingga aplikasi langsung dapat dijalankan:
```bash
flutter run
```
Jika ingin menimpa konfigurasi Supabase ke instance lain:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://ipttkvilafopfrrhpixl.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

### 3. Pengujian & Pemeriksaan Kode
```bash
flutter analyze
flutter test
```

### 4. Database & Konfigurasi Supabase
- Skema database lengkap tersedia di [supabase/schema.sql](supabase/schema.sql).
- Data contoh opsional tersedia di [supabase/seed.sql](supabase/seed.sql).
- Panduan verifikasi email Gmail, SMTP, dan manajemen skema tersedia di [supabase/SETUP.md](supabase/SETUP.md).
- **Aturan Keamanan**: Jangan pernah memasukkan `sb_secret_...` atau `service_role` key ke kode Flutter atau commit ke Git.

### 5. Alur Kerja Git Tim
```bash
git checkout -b feat/nama-fitur
# kerjakan perubahan, lalu pastikan flutter analyze & flutter test lolos
git add .
git commit -m "feat: deskripsi singkat perubahan"
git push -u origin feat/nama-fitur
```
Buat *Pull Request* ke branch `main` untuk review bersama.
