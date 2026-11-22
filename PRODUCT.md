# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

- **Buyer (Mahasiswa ITS)**: Mahasiswa tingkat awal hingga menengah yang membutuhkan buku kuliah, kamus, novel, atau komik bekas layak pakai dengan harga terjangkau serta informasi kondisi dan status ketersediaan yang jelas.
- **Seller / Donatur (Mahasiswa ITS)**: Mahasiswa (sering kali tingkat akhir) yang ingin menjual atau mendonasikan buku bekas layak pakai dengan cepat. Satu akun mahasiswa memiliki kapabilitas sebagai Buyer sekaligus Seller/Donatur.

## Product Purpose

MyITSBook adalah platform mobile berbasis re-commerce dan donasi buku kuliah terpusat untuk lingkungan sivitas akademika Institut Teknologi Sepuluh Nopember (ITS). Aplikasi ini menggantikan pertukaran buku lewat grup percakapan yang tersebar agar pencarian buku per mata kuliah/kategori cepat, informasi kondisi dan harga transparan, komunikasi pembeli–penjual aman di dalam aplikasi, serta mendorong budaya berbagi pengetahuan dan ekonomi sirkular kampus (mendukung SDG 4 dan SDG 12).

## Positioning

Katalog buku kampus terstruktur untuk sivitas akademika ITS dengan pemisahan eksplisit antara buku **Dijual** dan **Donasi (Gratis)**, transparansi kondisi fisik dan status ketersediaan (`Tersedia` → `Dalam Proses` → `Terjual`/`Selesai`), identitas mahasiswa berbasis NRP unik, serta ruang chat real-time langsung di dalam aplikasi tanpa perantara grup chat eksternal.

## Operating Context

Digunakan oleh mahasiswa ITS di ponsel Android (prioritas Android 8.0+, dengan dukungan iOS 13+ dan preview web) saat berada di lingkungan kampus (ruang kelas, perpustakaan, kantin, asrama) terutama di awal dan akhir semester. Pengguna mencari buku dari buka aplikasi hingga menemukan listing dalam target ≤ 2 menit, mengunggah foto sampul dari kamera atau galeri, dan menyepakati transaksi maupun serah terima secara mandiri di luar aplikasi (pembayaran dan pengiriman tidak diproses di dalam sistem pada v1.0). Seluruh antarmuka berbahasa Indonesia.

## Capabilities and Constraints

- **Cakupan MVP terkonfirmasi (Modul M1–M6)**:
  - **M1 Autentikasi**: Registrasi mahasiswa (nama lengkap, NRP unik, jurusan, nomor telepon, email valid bebas domain, password), login mahasiswa, pemulihan Lupa Password, sesi persisten, lihat dan kelola profil, logout.
  - **M2 Beranda**: Sapaan pengguna, ikon notifikasi dengan penanda belum dibaca, kolom pencarian cepat, pintasan kategori, rekomendasi buku dengan tab `Semua`, `Dijual`, dan `Donasi`, daftar buku terbaru, banner ajakan `Donasi Sekarang`, serta navigasi bawah 5 tujuan (`Beranda`, `Katalog`, `Tambah +`, `Chat`, `Profil`).
  - **M3 Katalog, Pencarian, Kategori, dan Filter**: Daftar kartu buku (foto, judul, harga atau label `Gratis`, kondisi, status), pencarian judul, 4 kategori wajib (`Buku Kuliah`, `Kamus`, `Novel`, `Komik`), filter status/jenis (`Semua`, `Dijual`, `Donasi`), filter kondisi, pagination/infinite scroll, dan tampilan state kosong yang jelas.
  - **M4 Detail Buku dan Wishlist**: Foto sampul, judul, deskripsi, harga/`Gratis`, kondisi, lokasi, kontak sesuai aturan privasi, identitas penjual (nama, jurusan, status verifikasi, rating rata-rata), status ketersediaan (`Tersedia`, `Dalam Proses`, `Terjual`/`Selesai`), tombol simpan/hapus Wishlist, tombol Chat yang membuka Chat Room disertai kartu ringkasan buku, penonaktifan aksi transaksi jika buku tidak `Tersedia`, dan halaman daftar Wishlist. Seller tidak dapat membeli atau memulai transaksi atas bukunya sendiri.
  - **M5 Kelola Buku (Jual dan Donasi)**: Tombol `+` pada navigasi bawah membuka pilihan `Jual Buku` atau `Donasi`; formulir memvalidasi foto sampul JPG/PNG maksimal 5 MB, judul, kategori, kondisi, harga numerik > 0 untuk jual (otomatis gratis/`0` untuk donasi), deskripsi singkat maksimal 15 kata, nama penjual, nomor WhatsApp, dan lokasi. Listing langsung tayang ke katalog tanpa moderasi pra-tayang; penjual dapat mengedit, menghapus dengan konfirmasi, serta mengubah status (`Tersedia`, `Dalam Proses`, `Terjual`/`Selesai`).
  - **M6 Chat Real-time dan Notifikasi**: Halaman daftar percakapan dengan filter `Semua` dan `Belum Dibaca` serta pencarian; Chat Room real-time dengan kartu ringkasan buku di bagian atas, gelembung pesan, kolom input, dan kirim; penanda pesan belum dibaca pada daftar percakapan dan navigasi; notifikasi dalam aplikasi untuk pesan baru dan perubahan status buku.
- **Di luar cakupan MVP (ditunda ke rilis lanjutan)**: M7 Riwayat Transaksi penuh, M8 Rating & Ulasan, M9 Keranjang/Checkout/QRIS/Transfer/COD, M10 Panel Admin penuh, integrasi payment gateway/escrow/pengiriman, dan aplikasi desktop.
- **Batasan Teknis & Keamanan**: Dibangun dengan Flutter & Dart terhubung ke backend Supabase (`https://ipttkvilafopfrrhpixl.supabase.co`). Aplikasi klien wajib memakai Publishable/Anon Key melalui `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` dan seluruh akses data dilindungi Row Level Security (RLS) di Postgres serta Storage policy. Secret Key Supabase tidak boleh ditanam di aplikasi klien. Data pribadi (NRP, email, nomor telepon) dibatasi eksposurnya sesuai kebutuhan transaksi.

## Brand Commitments

- Nama resmi produk: **MyITSBook**
- Pengembang: Kelompok 5 – Departemen Sistem Informasi, FTEIC, Institut Teknologi Sepuluh Nopember (ITS)
- Bahasa antarmuka: Bahasa Indonesia (NFR-10)
- Sistem UI: Material Design 3 asli untuk Android
- Identitas visual: Logo kustom orisinal (Konsep C — Jilid Bertumpuk)
- Arah visual terkonfirmasi: Marketplace buku kampus bergaya Midnight Navy (perpaduan Midnight Navy `#0B2245` + Biru Perak `#4F83BE` / `#8AB8E8`), tipografi **Poppins** (Regular/SemiBold untuk tajuk & Bold khusus untuk aksen/harga/angka kunci) dipadu **Inter** (Regular/Medium/SemiBold untuk teks & kontrol UI), Hijau Donasi (`#15803D`) untuk buku gratis, seluruh pop-up/aksi kontekstual memakai Bottom Sheet, serta tema terang dan gelap setara.

## Evidence on Hand

- Dokumen Product Requirements Document (PRD) MyITSBook versi 1.0 (Draft, 20 November 2026) yang memuat definisi masalah, persona, kebutuhan fungsional M1–M10, user flow, kebutuhan non-fungsional, model data, dan aturan bisnis.
- Proyek Supabase aktif (`ipttkvilafopfrrhpixl`) saat ini masih kosong (0 tabel publik dan 0 bucket storage) dan siap diisi melalui `supabase/schema.sql`.
- Data contoh pada `supabase/seed.sql` (jika dijalankan) hanya bersifat data ilustratif untuk pengujian dan tidak boleh diklaim sebagai data produksi nyata.

## Product Principles

1. **Temukan buku dalam hitungan detik**: Pencarian, kategori, dan filter status (`Dijual` vs `Donasi`) selalu mudah dijangkau agar target ≤ 2 menit tercapai.
2. **Transparansi kondisi dan status**: Kondisi fisik, harga atau label `Gratis`, dan status ketersediaan (`Tersedia`, `Dalam Proses`, `Terjual`/`Selesai`) tampil jelas tanpa ambiguitas.
3. **Donasi setara dengan jual-beli**: Jalur donasi buku mendapat posisi yang sama jelasnya di beranda, katalog, dan tombol publikasi (`+`), bukan fitur tersembunyi.
4. **Keamanan sivitas & privasi terjaga**: Validasi identitas NRP, pembatasan eksposur data pribadi, dan penegakan aturan bisnis hingga level database (RLS, constraint, trigger).
5. **Alur Material 3 yang akrab dan bebas friksi**: Komponen navigasi, formulir, dialog, dan umpan balik mengikuti standar Android agar mahasiswa baru langsung bisa memakai tanpa panduan.

## Accessibility & Inclusion

- Kontras warna memenuhi standar keterbacaan (minimal WCAG AA).
- Ukuran area sentuh seluruh elemen interaktif minimal 48×48 dp dengan jarak memadai (NFR-09).
- Tipografi mendukung penskalaan teks sistem (`sp`) dan tidak memotong label saat `font_scale` diperbesar.
- Mendukung tema terang (Light) dan gelap (Dark) sebagai skema kelas satu.
