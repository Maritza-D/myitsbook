-- MyITSBook — Supabase Database, RLS, Triggers, Storage & Realtime Schema
-- Fokus Seller & Buyer (Mahasiswa ITS). Idempotent & Advisor-clean.

create extension if not exists pgcrypto;

-- ============================================================================
-- 1. TABLES
-- ============================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nama text not null check (char_length(btrim(nama)) >= 2),
  nrp text not null unique check (char_length(btrim(nrp)) >= 6),
  jurusan text not null check (char_length(btrim(jurusan)) >= 2),
  telepon text not null check (char_length(btrim(telepon)) >= 8),
  email text not null unique,
  role text not null default 'mahasiswa' check (role = 'mahasiswa'),
  status_verifikasi text not null default 'terverifikasi' check (status_verifikasi in ('terverifikasi', 'tinjau', 'nonaktif')),
  rating_rata2 numeric(2, 1) not null default 0.0 check (rating_rata2 >= 0 and rating_rata2 <= 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Tabel publik aman privasi untuk identitas penjual (tanpa NRP, email, atau nomor telepon).
create table if not exists public.seller_profiles (
  id uuid primary key references public.profiles (id) on delete cascade,
  nama text not null,
  jurusan text not null,
  status_verifikasi text not null default 'terverifikasi',
  rating_rata2 numeric(2, 1) not null default 0.0,
  updated_at timestamptz not null default now()
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  judul text not null check (char_length(btrim(judul)) >= 2),
  kategori text not null check (kategori in ('Buku Kuliah', 'Kamus', 'Novel', 'Komik')),
  kondisi text not null check (kondisi in ('Seperti Baru', 'Baik', 'Cukup Baik')),
  deskripsi text not null,
  jenis_listing text not null check (jenis_listing in ('jual', 'donasi')),
  harga integer not null default 0 check (harga >= 0),
  foto_url text not null check (char_length(btrim(foto_url)) > 0),
  status text not null default 'tersedia' check (status in ('tersedia', 'dalam_proses', 'terjual', 'selesai')),
  nama_penjual text not null check (char_length(btrim(nama_penjual)) >= 2),
  kontak_wa text not null check (char_length(btrim(kontak_wa)) >= 8),
  lokasi text not null check (char_length(btrim(lokasi)) >= 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint books_listing_price_chk check (
    (jenis_listing = 'donasi' and harga = 0)
    or (jenis_listing = 'jual' and harga > 0)
  ),
  constraint books_deskripsi_max_15_kata_chk check (
    char_length(btrim(deskripsi)) > 0
    and array_length(regexp_split_to_array(btrim(deskripsi), '\s+'), 1) <= 15
  )
);

create table if not exists public.wishlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, book_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  last_message text not null default '',
  last_message_sender_id uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (buyer_id, seller_id, book_id),
  constraint conversations_no_self_chat_chk check (buyer_id <> seller_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  isi text not null check (char_length(btrim(isi)) > 0),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  tipe text not null check (tipe in ('pesan', 'status_buku', 'sistem')),
  judul text not null,
  isi text not null,
  ref_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 2. INDEXES (termasuk seluruh FK)
-- ============================================================================

create index if not exists idx_books_created_at on public.books (created_at desc);
create index if not exists idx_books_jenis_status on public.books (jenis_listing, status);
create index if not exists idx_books_kategori on public.books (kategori);
create index if not exists idx_books_seller_id on public.books (seller_id);
create index if not exists idx_wishlists_user_id on public.wishlists (user_id);
create index if not exists idx_wishlists_book_id on public.wishlists (book_id);
create index if not exists idx_conversations_buyer_updated on public.conversations (buyer_id, updated_at desc);
create index if not exists idx_conversations_seller_updated on public.conversations (seller_id, updated_at desc);
create index if not exists idx_conversations_book_id on public.conversations (book_id);
create index if not exists idx_conversations_last_sender on public.conversations (last_message_sender_id);
create index if not exists idx_messages_conversation_created on public.messages (conversation_id, created_at asc);
create index if not exists idx_messages_sender_id on public.messages (sender_id);
create index if not exists idx_notifications_user_read_created on public.notifications (user_id, is_read, created_at desc);

-- ============================================================================
-- 3. NRP AVAILABILITY RPC
-- ============================================================================

create or replace function public.is_nrp_available(p_nrp text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select not exists (
    select 1
    from public.profiles p
    join auth.users u on u.id = p.id
    where p.nrp = btrim(p_nrp)
      and u.email_confirmed_at is not null
  );
$$;

revoke all on function public.is_nrp_available(text) from public;
grant execute on function public.is_nrp_available(text) to anon, authenticated;

-- ============================================================================
-- 4. FUNCTIONS & TRIGGERS
-- ============================================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_books_updated_at on public.books;
create trigger trg_books_updated_at
before update on public.books
for each row execute function public.set_updated_at();

drop trigger if exists trg_conversations_updated_at on public.conversations;
create trigger trg_conversations_updated_at
before update on public.conversations
for each row execute function public.set_updated_at();

-- Sinkronkan profil publik seller setiap kali public.profiles berubah.
create or replace function public.sync_seller_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.seller_profiles (id, nama, jurusan, status_verifikasi, rating_rata2, updated_at)
  values (new.id, new.nama, new.jurusan, new.status_verifikasi, new.rating_rata2, now())
  on conflict (id) do update set
    nama = excluded.nama,
    jurusan = excluded.jurusan,
    status_verifikasi = excluded.status_verifikasi,
    rating_rata2 = excluded.rating_rata2,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_sync_seller_profile on public.profiles;
create trigger trg_sync_seller_profile
after insert or update of nama, jurusan, status_verifikasi, rating_rata2 on public.profiles
for each row execute function public.sync_seller_profile();

-- Buat profil otomatis saat user registrasi di Auth. Role selalu dikunci ke 'mahasiswa'.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nama text;
  v_nrp text;
  v_jurusan text;
  v_telepon text;
begin
  v_nama := coalesce(nullif(btrim(new.raw_user_meta_data ->> 'nama'), ''), 'Mahasiswa ITS');
  v_nrp := coalesce(nullif(btrim(new.raw_user_meta_data ->> 'nrp'), ''), replace(new.id::text, '-', ''));
  v_jurusan := coalesce(nullif(btrim(new.raw_user_meta_data ->> 'jurusan'), ''), 'Sistem Informasi');
  v_telepon := coalesce(nullif(btrim(new.raw_user_meta_data ->> 'telepon'), ''), '0800000000');

  update public.profiles p
  set nrp = 'pending-' || replace(p.id::text, '-', '')
  from auth.users u
  where p.id = u.id
    and p.nrp = v_nrp
    and p.id <> new.id
    and u.email_confirmed_at is null;

  insert into public.profiles (id, nama, nrp, jurusan, telepon, email, role)
  values (new.id, v_nama, v_nrp, v_jurusan, v_telepon, coalesce(new.email, ''), 'mahasiswa')
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Cegah user memodifikasi kolom hak akses/verifikasi/rating miliknya sendiri.
create or replace function public.guard_profile_updates()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if new.role is distinct from old.role
     or new.status_verifikasi is distinct from old.status_verifikasi
     or new.rating_rata2 is distinct from old.rating_rata2 then
    raise exception 'Tidak diizinkan mengubah role, status_verifikasi, atau rating_rata2';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_profile_updates on public.profiles;
create trigger trg_guard_profile_updates
before update on public.profiles
for each row execute function public.guard_profile_updates();

-- Sinkronisasi pesan terakhir & kirim notifikasi otomatis ke penerima saat ada pesan baru.
create or replace function public.handle_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid;
  v_seller_id uuid;
  v_book_id uuid;
  v_recipient_id uuid;
  v_sender_name text;
  v_book_title text;
begin
  select c.buyer_id, c.seller_id, c.book_id
  into v_buyer_id, v_seller_id, v_book_id
  from public.conversations c
  where c.id = new.conversation_id;

  if v_buyer_id is null then
    return new;
  end if;

  update public.conversations
  set last_message = left(btrim(new.isi), 140),
      last_message_sender_id = new.sender_id,
      updated_at = now()
  where id = new.conversation_id;

  if new.sender_id = v_buyer_id then
    v_recipient_id := v_seller_id;
  else
    v_recipient_id := v_buyer_id;
  end if;

  select nama into v_sender_name from public.profiles where id = new.sender_id;
  select judul into v_book_title from public.books where id = v_book_id;

  insert into public.notifications (user_id, tipe, judul, isi, ref_id)
  values (
    v_recipient_id,
    'pesan',
    coalesce(v_sender_name, 'Pesan Baru'),
    coalesce(v_book_title || ': ', '') || left(btrim(new.isi), 100),
    new.conversation_id
  );

  return new;
end;
$$;

drop trigger if exists trg_handle_new_message on public.messages;
create trigger trg_handle_new_message
after insert on public.messages
for each row execute function public.handle_new_message();

-- Notifikasi ke calon pembeli jika status buku yang sedang didiskusikan berubah.
create or replace function public.handle_book_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, tipe, judul, isi, ref_id)
  select distinct
    c.buyer_id,
    'status_buku',
    'Status Buku Diperbarui',
    'Status buku "' || new.judul || '" kini menjadi ' || replace(new.status, '_', ' ') || '.',
    new.id
  from public.conversations c
  where c.book_id = new.id
    and c.buyer_id <> new.seller_id;

  return new;
end;
$$;

drop trigger if exists trg_handle_book_status_change on public.books;
create trigger trg_handle_book_status_change
after update of status on public.books
for each row
when (old.status is distinct from new.status)
execute function public.handle_book_status_change();

-- Cabut hak eksekusi langsung via RPC pada fungsi trigger SECURITY DEFINER.
revoke all on function public.sync_seller_profile() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.guard_profile_updates() from public, anon, authenticated;
revoke all on function public.handle_new_message() from public, anon, authenticated;
revoke all on function public.handle_book_status_change() from public, anon, authenticated;

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.seller_profiles enable row level security;
alter table public.books enable row level security;
alter table public.wishlists enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

-- PROFILES
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- SELLER PROFILES (publik aman privasi untuk user terautentikasi)
drop policy if exists "seller_profiles_select_authenticated" on public.seller_profiles;
create policy "seller_profiles_select_authenticated"
on public.seller_profiles for select
to authenticated
using (true);

-- BOOKS
drop policy if exists "books_select_authenticated" on public.books;
create policy "books_select_authenticated"
on public.books for select
to authenticated
using (true);

drop policy if exists "books_insert_own" on public.books;
create policy "books_insert_own"
on public.books for insert
to authenticated
with check ((select auth.uid()) = seller_id);

drop policy if exists "books_update_own" on public.books;
create policy "books_update_own"
on public.books for update
to authenticated
using ((select auth.uid()) = seller_id)
with check ((select auth.uid()) = seller_id);

drop policy if exists "books_delete_own" on public.books;
create policy "books_delete_own"
on public.books for delete
to authenticated
using ((select auth.uid()) = seller_id);

-- WISHLISTS
drop policy if exists "wishlists_select_own" on public.wishlists;
create policy "wishlists_select_own"
on public.wishlists for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "wishlists_insert_own" on public.wishlists;
create policy "wishlists_insert_own"
on public.wishlists for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "wishlists_delete_own" on public.wishlists;
create policy "wishlists_delete_own"
on public.wishlists for delete
to authenticated
using ((select auth.uid()) = user_id);

-- CONVERSATIONS
drop policy if exists "conversations_select_participant" on public.conversations;
create policy "conversations_select_participant"
on public.conversations for select
to authenticated
using ((select auth.uid()) in (buyer_id, seller_id));

drop policy if exists "conversations_insert_buyer_available_book" on public.conversations;
create policy "conversations_insert_buyer_available_book"
on public.conversations for insert
to authenticated
with check (
  (select auth.uid()) = buyer_id
  and buyer_id <> seller_id
  and exists (
    select 1
    from public.books b
    where b.id = book_id
      and b.seller_id = seller_id
      and b.status = 'tersedia'
  )
);

drop policy if exists "conversations_update_participant" on public.conversations;
create policy "conversations_update_participant"
on public.conversations for update
to authenticated
using ((select auth.uid()) in (buyer_id, seller_id))
with check ((select auth.uid()) in (buyer_id, seller_id));

-- MESSAGES
drop policy if exists "messages_select_participant" on public.messages;
create policy "messages_select_participant"
on public.messages for select
to authenticated
using (
  exists (
    select 1
    from public.conversations c
    where c.id = conversation_id
      and (select auth.uid()) in (c.buyer_id, c.seller_id)
  )
);

drop policy if exists "messages_insert_sender_participant" on public.messages;
create policy "messages_insert_sender_participant"
on public.messages for insert
to authenticated
with check (
  (select auth.uid()) = sender_id
  and exists (
    select 1
    from public.conversations c
    where c.id = conversation_id
      and (select auth.uid()) in (c.buyer_id, c.seller_id)
  )
);

drop policy if exists "messages_update_mark_read_recipient" on public.messages;
create policy "messages_update_mark_read_recipient"
on public.messages for update
to authenticated
using (
  (select auth.uid()) <> sender_id
  and exists (
    select 1
    from public.conversations c
    where c.id = conversation_id
      and (select auth.uid()) in (c.buyer_id, c.seller_id)
  )
)
with check (
  (select auth.uid()) <> sender_id
  and exists (
    select 1
    from public.conversations c
    where c.id = conversation_id
      and (select auth.uid()) in (c.buyer_id, c.seller_id)
  )
);

-- NOTIFICATIONS
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own"
on public.notifications for delete
to authenticated
using ((select auth.uid()) = user_id);

-- ============================================================================
-- 6. STORAGE BUCKET & POLICIES ('book-covers')
-- ============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'book-covers',
  'book-covers',
  true,
  5242880,
  array['image/jpeg', 'image/png']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "book_covers_public_read" on storage.objects;
create policy "book_covers_public_read"
on storage.objects for select
to public
using (bucket_id = 'book-covers');

drop policy if exists "book_covers_auth_insert_own_folder" on storage.objects;
create policy "book_covers_auth_insert_own_folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'book-covers'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "book_covers_auth_update_own_folder" on storage.objects;
create policy "book_covers_auth_update_own_folder"
on storage.objects for update
to authenticated
using (
  bucket_id = 'book-covers'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'book-covers'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "book_covers_auth_delete_own_folder" on storage.objects;
create policy "book_covers_auth_delete_own_folder"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'book-covers'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

-- ============================================================================
-- 7. REALTIME PUBLICATION
-- ============================================================================

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.conversations;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.books;
exception when duplicate_object then null;
end $$;

-- =====================================================
-- TABLE TRANSACTIONS
-- =====================================================

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),

  book_id uuid not null
    references public.books(id) on delete restrict,

  seller_id uuid not null
    references public.profiles(id) on delete restrict,

  buyer_id uuid not null
    references public.profiles(id) on delete restrict,

  price integer not null check (price > 0),

  status text not null default 'dalam_proses'
    check (status in ('dalam_proses', 'selesai', 'dibatalkan')),

  created_at timestamptz not null default now(),
  completed_at timestamptz,

  constraint transaction_no_self_purchase
    check (seller_id <> buyer_id)
);

-- =====================================================
-- TABLE DONATIONS
-- =====================================================

create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),

  book_id uuid not null
    references public.books(id) on delete restrict,

  donor_id uuid not null
    references public.profiles(id) on delete restrict,

  receiver_id uuid not null
    references public.profiles(id) on delete restrict,

  status text not null default 'dalam_proses'
    check (status in ('dalam_proses', 'selesai', 'dibatalkan')),

  created_at timestamptz not null default now(),
  completed_at timestamptz,

  constraint donation_no_self_claim
    check (donor_id <> receiver_id)
);

-- =====================================================
-- INDEXES
-- =====================================================

create index if not exists idx_transactions_buyer
on public.transactions(buyer_id, created_at desc);

create index if not exists idx_transactions_seller
on public.transactions(seller_id, created_at desc);

create index if not exists idx_donations_donor
on public.donations(donor_id, created_at desc);

create index if not exists idx_donations_receiver
on public.donations(receiver_id, created_at desc);

-- =====================================================
-- ENABLE RLS
-- =====================================================

alter table public.transactions enable row level security;
alter table public.donations enable row level security;

-- Users can read their own transaction history

create policy "Users can read own transactions"
on public.transactions
for select
to authenticated
using (
  auth.uid() = buyer_id
  or auth.uid() = seller_id
);

-- Users can read their own donation history

create policy "Users can read own donations"
on public.donations
for select
to authenticated
using (
  auth.uid() = donor_id
  or auth.uid() = receiver_id
);
