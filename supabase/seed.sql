-- MyITSBook — Data Contoh Ilustratif (Opsional untuk Pengujian Katalog)
-- Jalankan SETELAH minimal 1 akun mahasiswa terdaftar lewat halaman Daftar / Auth
-- sehingga baris pada public.profiles sudah tersedia.
-- Catatan: Data buku berikut hanya contoh ilustratif untuk demo pengembangan.

do $$
declare
  v_seller record;
begin
  select id, nama, telepon
  into v_seller
  from public.profiles
  order by created_at asc
  limit 1;

  if v_seller.id is null then
    raise notice 'Belum ada profil pengguna di public.profiles. Daftar minimal 1 akun terlebih dahulu sebelum menjalankan seed.sql.';
    return;
  end if;

  if exists (select 1 from public.books where seller_id = v_seller.id) then
    raise notice 'Data contoh sudah tersedia untuk seller %.', v_seller.nama;
    return;
  end if;

  insert into public.books (
    seller_id,
    judul,
    kategori,
    kondisi,
    deskripsi,
    jenis_listing,
    harga,
    foto_url,
    status,
    nama_penjual,
    kontak_wa,
    lokasi
  ) values
  (
    v_seller.id,
    'Rekayasa Perangkat Lunak Edisi 9',
    'Buku Kuliah',
    'Seperti Baru',
    'Buku pegangan RPL semester 4 bersih tanpa coretan dan sampul rapi.',
    'jual',
    75000,
    'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=600',
    'tersedia',
    v_seller.nama,
    v_seller.telepon,
    'Gedung Sistem Informasi ITS'
  ),
  (
    v_seller.id,
    'Kalkulus Purcell Jilid 1',
    'Buku Kuliah',
    'Baik',
    'Kondisi halaman lengkap dan sedikit stabilo pada bab turunan.',
    'donasi',
    0,
    'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600',
    'tersedia',
    v_seller.nama,
    v_seller.telepon,
    'Perpustakaan Pusat ITS'
  ),
  (
    v_seller.id,
    'Kamus Lengkap Teknik Informatika',
    'Kamus',
    'Baik',
    'Kamus istilah komputasi dan jaringan cocok untuk mahasiswa baru FTEIC.',
    'jual',
    40000,
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
    'tersedia',
    v_seller.nama,
    v_seller.telepon,
    'Kantin Pusat ITS'
  ),
  (
    v_seller.id,
    'Laskar Pelangi',
    'Novel',
    'Cukup Baik',
    'Novel bacaan ringan edisi cetak lama tetap terbaca jelas dan utuh.',
    'donasi',
    0,
    'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=600',
    'tersedia',
    v_seller.nama,
    v_seller.telepon,
    'Asrama Mahasiswa ITS'
  );
end $$;
