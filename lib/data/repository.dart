import 'dart:async';
import 'dart:typed_data';

import 'package:myitsbook/data/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookFilter {
  const BookFilter({
    this.query = '',
    this.category,
    this.jenisListing,
    this.kondisi,
    this.minPrice,
    this.maxPrice,
    this.lokasi,
    this.sort = BookSort.terbaru,
    this.page = 0,
    this.pageSize = 12,
  });

  final String query;
  final String? category;
  final ListingType? jenisListing;
  final String? kondisi;
  final int? minPrice;
  final int? maxPrice;
  final String? lokasi;
  final BookSort sort;
  final int page;
  final int pageSize;
}

class BookPayload {
  const BookPayload({
    required this.judul,
    required this.kategori,
    required this.kondisi,
    required this.deskripsi,
    required this.jenisListing,
    required this.harga,
    required this.namaPenjual,
    required this.kontakWa,
    required this.lokasi,
    this.existingFotoUrl,
    this.coverBytes,
    this.coverFileName,
  });

  final String judul;
  final String kategori;
  final String kondisi;
  final String deskripsi;
  final ListingType jenisListing;
  final int harga;
  final String namaPenjual;
  final String kontakWa;
  final String lokasi;
  final String? existingFotoUrl;
  final Uint8List? coverBytes;
  final String? coverFileName;
}

abstract class AppRepository {
  bool get isDemoMode;
  UserProfile? get currentProfile;

  Future<UserProfile?> restoreSession();
  Future<UserProfile> signIn({required String email, required String password});
  Future<UserProfile?> registerStudent({
    required String nama,
    required String nrp,
    required String jurusan,
    required String telepon,
    required String email,
    required String password,
  });
  Future<UserProfile> verifySignupOtp({
    required String email,
    required String token,
  });
  Future<void> resendSignupVerification(String email);
  Future<void> requestPasswordReset(String email);
  Future<void> signOut();
  Future<UserProfile> updateProfile({
    required String nama,
    required String jurusan,
    required String telepon,
  });

  Future<List<BookItem>> fetchBooks(BookFilter filter);
  Future<List<BookItem>> fetchMyBooks();
  Future<BookItem?> fetchBookById(String bookId);
  Future<SellerInfo?> fetchSellerInfo(String sellerId);
  Future<List<SellerReview>> fetchSellerReviews(String sellerId);

  Future<SellerReview> submitSellerReview({
    required String conversationId,
    required int rating,
    String? ulasan,
  });

  Future<BookItem> createBook(BookPayload payload);
  Future<BookItem> updateBook(String bookId, BookPayload payload);
  Future<void> updateBookStatus(String bookId, BookStatus status);
  Future<void> deleteBook(String bookId);

  Future<Set<String>> fetchWishlistIds();
  Future<List<BookItem>> fetchWishlistBooks();
  Future<bool> toggleWishlist(String bookId);

  Stream<List<ConversationSummary>> watchConversations();
  Future<ConversationSummary> getOrCreateConversation(BookItem book);
  Stream<List<ChatMessage>> watchMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String text);
  Future<void> markConversationRead(String conversationId);

  Stream<List<AppNotification>> watchNotifications();
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();

  void dispose();
}

class SupabaseRepository implements AppRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;
  UserProfile? _cachedProfile;

  @override
  bool get isDemoMode => false;

  @override
  UserProfile? get currentProfile => _cachedProfile;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Sesi login tidak ditemukan.');
    return id;
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      _cachedProfile = null;
      return null;
    }
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();
    if (data == null) {
      _cachedProfile = null;
      return null;
    }
    _cachedProfile = UserProfile.fromMap(data);
    return _cachedProfile;
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Gagal masuk ke akun.');
    }
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    final profile = UserProfile.fromMap(data);
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile?> registerStudent({
    required String nama,
    required String nrp,
    required String jurusan,
    required String telepon,
    required String email,
    required String password,
  }) async {
    final nrpAvailable = await _client.rpc<bool>(
      'is_nrp_available',
      params: {'p_nrp': nrp.trim()},
    );
    if (!nrpAvailable) {
      throw Exception('NRP ini sudah terdaftar pada akun lain.');
    }

    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nama': nama.trim(),
        'nrp': nrp.trim(),
        'jurusan': jurusan.trim(),
        'telepon': telepon.trim(),
      },
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Pendaftaran belum dapat diselesaikan.');
    }
    if (res.session == null) {
      return null;
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    final profile = UserProfile.fromMap(data);
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    final res = await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: token.trim(),
    );
    final user = res.user;
    if (user == null || res.session == null) {
      throw Exception(
        'Verifikasi belum berhasil. Periksa kembali kode dari email Anda.',
      );
    }
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    final profile = UserProfile.fromMap(data);
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<void> resendSignupVerification(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> signOut() async {
    _cachedProfile = null;
    await _client.auth.signOut();
  }

  @override
  Future<UserProfile> updateProfile({
    required String nama,
    required String jurusan,
    required String telepon,
  }) async {
    final data = await _client
        .from('profiles')
        .update({
          'nama': nama.trim(),
          'jurusan': jurusan.trim(),
          'telepon': telepon.trim(),
        })
        .eq('id', _uid)
        .select()
        .single();
    _cachedProfile = UserProfile.fromMap(data);
    return _cachedProfile!;
  }

  @override
  Future<List<BookItem>> fetchBooks(BookFilter filter) async {
    var req = _client.from('books').select();
    if (filter.query.trim().isNotEmpty) {
      req = req.ilike('judul', '%${filter.query.trim()}%');
    }
    if (filter.category != null && filter.category!.isNotEmpty) {
      req = req.eq('kategori', filter.category!);
    }
    if (filter.jenisListing != null) {
      req = req.eq('jenis_listing', filter.jenisListing!.dbValue);
    }
    if (filter.kondisi != null && filter.kondisi!.isNotEmpty) {
      req = req.eq('kondisi', filter.kondisi!);
    }
    if (filter.minPrice != null) {
      req = req.gte('harga', filter.minPrice!);
    }
    if (filter.maxPrice != null) {
      req = req.lte('harga', filter.maxPrice!);
    }
    if (filter.lokasi != null && filter.lokasi!.trim().isNotEmpty) {
      req = req.ilike('lokasi', '%${filter.lokasi!.trim()}%');
    }

    final from = filter.page * filter.pageSize;
    final to = from + filter.pageSize - 1;
    final String orderCol;
    final bool ascending;
    switch (filter.sort) {
      case BookSort.termurah:
        orderCol = 'harga';
        ascending = true;
      case BookSort.termahal:
        orderCol = 'harga';
        ascending = false;
      case BookSort.terbaru:
        orderCol = 'created_at';
        ascending = false;
    }
    final rows = await req
        .order(orderCol, ascending: ascending)
        .range(from, to);
    return rows.map(BookItem.fromMap).toList();
  }

  @override
  Future<List<BookItem>> fetchMyBooks() async {
    final rows = await _client
        .from('books')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(BookItem.fromMap).toList();
  }

  @override
  Future<BookItem?> fetchBookById(String bookId) async {
    final data = await _client
        .from('books')
        .select()
        .eq('id', bookId)
        .maybeSingle();
    return data == null ? null : BookItem.fromMap(data);
  }

  @override
  Future<SellerInfo?> fetchSellerInfo(String sellerId) async {
    final data = await _client
        .from('seller_profiles')
        .select()
        .eq('id', sellerId)
        .maybeSingle();
    return data == null ? null : SellerInfo.fromMap(data);
  }

  @override
  Future<List<SellerReview>> fetchSellerReviews(String sellerId) async {
    final rows = await _client
        .from('reviews')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return rows.map(SellerReview.fromMap).toList();
  }

  @override
  Future<SellerReview> submitSellerReview({
    required String conversationId,
    required int rating,
    String? ulasan,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5.');
    }

    final result = await _client.rpc(
      'submit_seller_review',
      params: {
        'p_conversation_id': conversationId,
        'p_rating': rating,
        'p_ulasan': ulasan?.trim(),
      },
    );

    return SellerReview.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<String> _uploadCoverIfProvided(BookPayload payload) async {
    if (payload.coverBytes == null) {
      final existing = payload.existingFotoUrl;
      if (existing != null && existing.isNotEmpty) return existing;
      throw Exception('Foto sampul buku wajib diunggah.');
    }
    final name = (payload.coverFileName ?? 'cover.jpg').toLowerCase();
    final isPng = name.endsWith('.png');
    final ext = isPng ? 'png' : 'jpg';
    final mime = isPng ? 'image/png' : 'image/jpeg';
    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage
        .from('book-covers')
        .uploadBinary(
          path,
          payload.coverBytes!,
          fileOptions: FileOptions(contentType: mime, upsert: true),
        );
    return _client.storage.from('book-covers').getPublicUrl(path);
  }

  @override
  Future<BookItem> createBook(BookPayload payload) async {
    final fotoUrl = await _uploadCoverIfProvided(payload);
    final data = await _client
        .from('books')
        .insert({
          'seller_id': _uid,
          'judul': payload.judul.trim(),
          'kategori': payload.kategori,
          'kondisi': payload.kondisi,
          'deskripsi': payload.deskripsi.trim(),
          'jenis_listing': payload.jenisListing.dbValue,
          'harga': payload.jenisListing == ListingType.donasi
              ? 0
              : payload.harga,
          'foto_url': fotoUrl,
          'nama_penjual': payload.namaPenjual.trim(),
          'kontak_wa': payload.kontakWa.trim(),
          'lokasi': payload.lokasi.trim(),
        })
        .select()
        .single();
    return BookItem.fromMap(data);
  }

  @override
  Future<BookItem> updateBook(String bookId, BookPayload payload) async {
    final fotoUrl = await _uploadCoverIfProvided(payload);
    final data = await _client
        .from('books')
        .update({
          'judul': payload.judul.trim(),
          'kategori': payload.kategori,
          'kondisi': payload.kondisi,
          'deskripsi': payload.deskripsi.trim(),
          'jenis_listing': payload.jenisListing.dbValue,
          'harga': payload.jenisListing == ListingType.donasi
              ? 0
              : payload.harga,
          'foto_url': fotoUrl,
          'nama_penjual': payload.namaPenjual.trim(),
          'kontak_wa': payload.kontakWa.trim(),
          'lokasi': payload.lokasi.trim(),
        })
        .eq('id', bookId)
        .eq('seller_id', _uid)
        .select()
        .single();
    return BookItem.fromMap(data);
  }

  @override
  Future<void> updateBookStatus(String bookId, BookStatus status) async {
    await _client
        .from('books')
        .update({'status': status.dbValue})
        .eq('id', bookId)
        .eq('seller_id', _uid);
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _client.from('books').delete().eq('id', bookId).eq('seller_id', _uid);
  }

  @override
  Future<Set<String>> fetchWishlistIds() async {
    final rows = await _client
        .from('wishlists')
        .select('book_id')
        .eq('user_id', _uid);
    return rows.map((e) => e['book_id'] as String).toSet();
  }

  @override
  Future<List<BookItem>> fetchWishlistBooks() async {
    final rows = await _client
        .from('wishlists')
        .select('books(*)')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    final books = <BookItem>[];
    for (final row in rows) {
      final rawBook = row['books'];
      if (rawBook is Map<String, dynamic>) {
        books.add(BookItem.fromMap(rawBook));
      }
    }
    return books;
  }

  @override
  Future<bool> toggleWishlist(String bookId) async {
    final existing = await _client
        .from('wishlists')
        .select('id')
        .eq('user_id', _uid)
        .eq('book_id', bookId)
        .maybeSingle();
    if (existing != null) {
      await _client.from('wishlists').delete().eq('id', existing['id']);
      return false;
    }
    await _client.from('wishlists').insert({
      'user_id': _uid,
      'book_id': bookId,
    });
    return true;
  }

  Future<List<ConversationSummary>> _hydrateConversations(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];
    final bookIds = rows.map((r) => r['book_id'] as String).toSet().toList();
    final otherIds = rows
        .map((r) {
          final buyerId = r['buyer_id'] as String;
          final sellerId = r['seller_id'] as String;
          return buyerId == _uid ? sellerId : buyerId;
        })
        .toSet()
        .toList();
    final convIds = rows.map((r) => r['id'] as String).toList();

    final booksRows = await _client
        .from('books')
        .select('id, judul, foto_url, harga, jenis_listing, status')
        .inFilter('id', bookIds);
    final bookMap = {for (final b in booksRows) b['id'] as String: b};

    final profileRows = await _client
        .from('seller_profiles')
        .select('id, nama')
        .inFilter('id', otherIds);
    final nameMap = {
      for (final p in profileRows)
        p['id'] as String: (p['nama'] ?? 'Mahasiswa') as String,
    };

    final unreadRows = await _client
        .from('messages')
        .select('conversation_id')
        .inFilter('conversation_id', convIds)
        .neq('sender_id', _uid)
        .eq('is_read', false);
    final unreadCounts = <String, int>{};
    for (final m in unreadRows) {
      final cid = m['conversation_id'] as String;
      unreadCounts[cid] = (unreadCounts[cid] ?? 0) + 1;
    }

    return rows.map((r) {
      final cid = r['id'] as String;
      final buyerId = r['buyer_id'] as String;
      final sellerId = r['seller_id'] as String;
      final otherId = buyerId == _uid ? sellerId : buyerId;
      final book = bookMap[r['book_id'] as String];
      return ConversationSummary(
        id: cid,
        buyerId: buyerId,
        sellerId: sellerId,
        bookId: r['book_id'] as String,
        bookTitle: (book?['judul'] ?? 'Buku ITS') as String,
        bookFotoUrl: (book?['foto_url'] ?? '') as String,
        bookHarga: ((book?['harga'] ?? 0) as num).toInt(),
        bookJenis: ListingType.fromDb(
          (book?['jenis_listing'] ?? 'jual') as String,
        ),
        bookStatus: BookStatus.fromDb(
          (book?['status'] ?? 'tersedia') as String,
        ),
        otherUserName: nameMap[otherId] ?? 'Mahasiswa ITS',
        lastMessage: (r['last_message'] ?? '') as String,
        lastMessageSenderId: r['last_message_sender_id'] as String?,
        unreadCount: unreadCounts[cid] ?? 0,
        updatedAt:
            DateTime.tryParse((r['updated_at'] ?? '').toString()) ??
            DateTime.now(),
      );
    }).toList();
  }

  @override
  Stream<List<ConversationSummary>> watchConversations() {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .asyncMap(_hydrateConversations);
  }

  @override
  Future<ConversationSummary> getOrCreateConversation(BookItem book) async {
    final existing = await _client
        .from('conversations')
        .select()
        .eq('buyer_id', _uid)
        .eq('seller_id', book.sellerId)
        .eq('book_id', book.id)
        .maybeSingle();

    final Map<String, dynamic> row;
    if (existing != null) {
      row = existing;
    } else {
      row = await _client
          .from('conversations')
          .insert({
            'buyer_id': _uid,
            'seller_id': book.sellerId,
            'book_id': book.id,
          })
          .select()
          .single();
    }
    final hydrated = await _hydrateConversations([row]);
    return hydrated.first;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(ChatMessage.fromMap).toList());
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _uid,
      'isi': clean,
    });
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', _uid)
        .eq('is_read', false);
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromMap).toList());
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', _uid);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
  }

  @override
  void dispose() {}
}

/// Repositori lokal dalam memori untuk pengujian widget (flutter test).
class DemoRepository implements AppRepository {
  DemoRepository({
    UserProfile? initialUser,
    this.requireEmailVerification = false,
  }) : _current = initialUser {
    _seedInitialData();
  }

  final bool requireEmailVerification;
  final _changes = StreamController<void>.broadcast();
  UserProfile? _current;
  UserProfile? _pendingProfile;

  final Map<String, SellerInfo> _sellers = {
    'demo-user': const SellerInfo(
      id: 'demo-user',
      nama: 'Michael Raja Pasaribu',
      jurusan: 'Sistem Informasi',
      statusVerifikasi: 'terverifikasi',
      ratingRata2: 4.9,
    ),
    'demo-rina': const SellerInfo(
      id: 'demo-rina',
      nama: 'Rina Salsabila',
      jurusan: 'Teknik Informatika',
      statusVerifikasi: 'terverifikasi',
      ratingRata2: 4.8,
    ),
    'demo-bima': const SellerInfo(
      id: 'demo-bima',
      nama: 'Bima Aditya',
      jurusan: 'Matematika',
      statusVerifikasi: 'terverifikasi',
      ratingRata2: 5.0,
    ),
  };

  final List<BookItem> _books = [];
  final Set<String> _wishlist = {'book-2'};
  final List<_DemoConv> _convs = [];
  final List<ChatMessage> _messages = [];
  final List<AppNotification> _notifications = [];
  final List<SellerReview> _reviews = [];
  int _seq = 100;

  static const UserProfile defaultStudent = UserProfile(
    id: 'demo-user',
    nama: 'Michael Raja Pasaribu',
    nrp: '5026241196',
    jurusan: 'Sistem Informasi',
    telepon: '081234567890',
    email: 'michael@student.its.ac.id',
    role: 'mahasiswa',
    statusVerifikasi: 'terverifikasi',
    ratingRata2: 4.9,
  );

  void _seedInitialData() {
    final now = DateTime.now();
    _books.addAll([
      BookItem(
        id: 'book-1',
        sellerId: 'demo-rina',
        judul: 'Rekayasa Perangkat Lunak Edisi 9',
        kategori: 'Buku Kuliah',
        kondisi: 'Seperti Baru',
        deskripsi: 'Buku pegangan RPL semester 4 bersih tanpa coretan dan sampul rapi.',
        jenisListing: ListingType.jual,
        harga: 75000,
        fotoUrl: '',
        status: BookStatus.tersedia,
        namaPenjual: 'Rina Salsabila',
        kontakWa: '081298765432',
        lokasi: 'Gedung Sistem Informasi ITS',
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      BookItem(
        id: 'book-2',
        sellerId: 'demo-bima',
        judul: 'Kalkulus Purcell Jilid 1',
        kategori: 'Buku Kuliah',
        kondisi: 'Baik',
        deskripsi: 'Halaman lengkap dengan sedikit stabilo rapi pada bab turunan dasar.',
        jenisListing: ListingType.donasi,
        harga: 0,
        fotoUrl: '',
        status: BookStatus.tersedia,
        namaPenjual: 'Bima Aditya',
        kontakWa: '081355501234',
        lokasi: 'Perpustakaan Pusat ITS',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      BookItem(
        id: 'book-3',
        sellerId: 'demo-rina',
        judul: 'Kamus Lengkap Teknik Informatika',
        kategori: 'Kamus',
        kondisi: 'Baik',
        deskripsi: 'Kamus istilah komputasi dan jaringan cocok untuk mahasiswa baru FTEIC.',
        jenisListing: ListingType.jual,
        harga: 40000,
        fotoUrl: '',
        status: BookStatus.tersedia,
        namaPenjual: 'Rina Salsabila',
        kontakWa: '081298765432',
        lokasi: 'Kantin Pusat ITS',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      BookItem(
        id: 'book-4',
        sellerId: 'demo-bima',
        judul: 'Laskar Pelangi Edisi Cetak Ulang',
        kategori: 'Novel',
        kondisi: 'Cukup Baik',
        deskripsi: 'Novel bacaan ringan tetap terbaca jelas dan jilid utuh.',
        jenisListing: ListingType.donasi,
        harga: 0,
        fotoUrl: '',
        status: BookStatus.tersedia,
        namaPenjual: 'Bima Aditya',
        kontakWa: '081355501234',
        lokasi: 'Asrama Mahasiswa ITS',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BookItem(
        id: 'book-5',
        sellerId: 'demo-rina',
        judul: 'Sistem Basis Data Connoly',
        kategori: 'Buku Kuliah',
        kondisi: 'Baik',
        deskripsi: 'Buku basis data lengkap dengan catatan ringkas perancangan relasional.',
        jenisListing: ListingType.jual,
        harga: 60000,
        fotoUrl: '',
        status: BookStatus.terjual,
        namaPenjual: 'Rina Salsabila',
        kontakWa: '081298765432',
        lokasi: 'Kantin Pusat ITS',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      BookItem(
        id: 'book-6',
        sellerId: 'demo-user',
        judul: 'Algoritma & Pemrograman Dart Flutter',
        kategori: 'Buku Kuliah',
        kondisi: 'Seperti Baru',
        deskripsi:
            'Modul praktikum pemrograman bergerak bersih dan siap pakai.',
        jenisListing: ListingType.jual,
        harga: 55000,
        fotoUrl: '',
        status: BookStatus.tersedia,
        namaPenjual: 'Michael Raja Pasaribu',
        kontakWa: '081234567890',
        lokasi: 'Gedung Sistem Informasi ITS',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    _convs.add(
      _DemoConv(
        id: 'conv-1',
        buyerId: 'demo-user',
        sellerId: 'demo-rina',
        bookId: 'book-1',
        updatedAt: now.subtract(const Duration(minutes: 12)),
      ),
    );
    _messages.addAll([
      ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'demo-user',
        isi: 'Halo, apakah buku Rekayasa Perangkat Lunak Edisi 9 masih tersedia?',
        isRead: true,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      ChatMessage(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'demo-rina',
        isi: 'Halo, buku masih tersedia. Serah terima dapat dilakukan di lobi Gedung Sistem Informasi pukul 15.00.',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
    ]);

    _notifications.addAll([
      AppNotification(
        id: 'notif-1',
        userId: 'demo-user',
        tipe: 'pesan',
        judul: 'Rina Salsabila',
        isi: 'Rekayasa Perangkat Lunak Edisi 9: Halo, buku masih tersedia. Serah terima dapat dilakukan di lobi Gedung SI.',
        refId: 'conv-1',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 'notif-2',
        userId: 'demo-user',
        tipe: 'status_buku',
        judul: 'Status Buku Diperbarui',
        isi: 'Buku "Sistem Basis Data Connoly" kini berstatus terjual.',
        refId: 'book-5',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  bool get isDemoMode => true;

  @override
  UserProfile? get currentProfile => _current;

  @override
  Future<UserProfile?> restoreSession() async => _current;

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    _current = defaultStudent;
    _emit();
    return _current!;
  }

  @override
  Future<UserProfile?> registerStudent({
    required String nama,
    required String nrp,
    required String jurusan,
    required String telepon,
    required String email,
    required String password,
  }) async {
    final profile = UserProfile(
      id: 'demo-user',
      nama: nama.trim(),
      nrp: nrp.trim(),
      jurusan: jurusan.trim(),
      telepon: telepon.trim(),
      email: email.trim(),
      role: 'mahasiswa',
      statusVerifikasi: 'terverifikasi',
      ratingRata2: 5.0,
    );
    _sellers['demo-user'] = SellerInfo(
      id: 'demo-user',
      nama: nama.trim(),
      jurusan: jurusan.trim(),
      statusVerifikasi: 'terverifikasi',
      ratingRata2: 5.0,
    );
    if (requireEmailVerification) {
      _pendingProfile = profile;
      return null;
    }
    _current = profile;
    _emit();
    return _current;
  }

  @override
  Future<UserProfile> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    if (token.trim().length < 6) {
      throw Exception('Kode verifikasi minimal 6 digit.');
    }
    _current = _pendingProfile ?? defaultStudent;
    _pendingProfile = null;
    _emit();
    return _current!;
  }

  @override
  Future<void> resendSignupVerification(String email) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    _current = null;
    _emit();
  }

  @override
  Future<UserProfile> updateProfile({
    required String nama,
    required String jurusan,
    required String telepon,
  }) async {
    _current = (_current ?? defaultStudent).copyWith(
      nama: nama.trim(),
      jurusan: jurusan.trim(),
      telepon: telepon.trim(),
    );
    _emit();
    return _current!;
  }

  @override
  Future<List<BookItem>> fetchBooks(BookFilter filter) async {
    final q = filter.query.trim().toLowerCase();
    final loc = filter.lokasi?.trim().toLowerCase() ?? '';
    final filtered = _books.where((b) {
      if (q.isNotEmpty && !b.judul.toLowerCase().contains(q)) return false;
      if (filter.category != null &&
          filter.category!.isNotEmpty &&
          b.kategori != filter.category) {
        return false;
      }
      if (filter.jenisListing != null &&
          b.jenisListing != filter.jenisListing) {
        return false;
      }
      if (filter.kondisi != null &&
          filter.kondisi!.isNotEmpty &&
          b.kondisi != filter.kondisi) {
        return false;
      }
      if (filter.minPrice != null && b.harga < filter.minPrice!) {
        return false;
      }
      if (filter.maxPrice != null && b.harga > filter.maxPrice!) {
        return false;
      }
      if (loc.isNotEmpty && !b.lokasi.toLowerCase().contains(loc)) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sort) {
      case BookSort.termurah:
        filtered.sort((a, b) => a.harga.compareTo(b.harga));
      case BookSort.termahal:
        filtered.sort((a, b) => b.harga.compareTo(a.harga));
      case BookSort.terbaru:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final start = filter.page * filter.pageSize;
    if (start >= filtered.length) return [];
    final end = (start + filter.pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Future<List<BookItem>> fetchMyBooks() async {
    final uid = _current?.id ?? 'demo-user';
    return _books.where((b) => b.sellerId == uid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<BookItem?> fetchBookById(String bookId) async {
    for (final b in _books) {
      if (b.id == bookId) return b;
    }
    return null;
  }

  @override
  Future<SellerInfo?> fetchSellerInfo(String sellerId) async {
    return _sellers[sellerId];
  }

  @override
  Future<List<SellerReview>> fetchSellerReviews(String sellerId) async {
    return _reviews.where((review) => review.sellerId == sellerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<SellerReview> submitSellerReview({
    required String conversationId,
    required int rating,
    String? ulasan,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5.');
    }

    final uid = _current?.id;
    if (uid == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    final matches = _convs.where((c) => c.id == conversationId);
    if (matches.isEmpty) {
      throw Exception('Percakapan tidak ditemukan.');
    }

    final conv = matches.first;

    if (conv.buyerId != uid) {
      throw Exception('Hanya pembeli yang dapat memberikan ulasan.');
    }

    final books = _books.where((b) => b.id == conv.bookId);
    if (books.isEmpty || books.first.status != BookStatus.selesai) {
      throw Exception('Buku belum berstatus selesai.');
    }

    if (_reviews.any((r) => r.reviewerId == uid && r.bookId == conv.bookId)) {
      throw Exception('Kamu sudah memberikan ulasan untuk buku ini.');
    }

    final review = SellerReview(
      id: 'review-${++_seq}',
      reviewerId: uid,
      sellerId: conv.sellerId,
      bookId: conv.bookId,
      rating: rating,
      ulasan: ulasan?.trim().isEmpty ?? true ? null : ulasan!.trim(),
      createdAt: DateTime.now(),
    );

    _reviews.add(review);

    final sellerReviews = _reviews
        .where((r) => r.sellerId == conv.sellerId)
        .toList();

    final average =
        sellerReviews.fold<int>(0, (total, r) => total + r.rating) /
        sellerReviews.length;

    final seller = _sellers[conv.sellerId];
    if (seller != null) {
      _sellers[conv.sellerId] = SellerInfo(
        id: seller.id,
        nama: seller.nama,
        jurusan: seller.jurusan,
        statusVerifikasi: seller.statusVerifikasi,
        ratingRata2: double.parse(average.toStringAsFixed(1)),
      );
    }

    _emit();
    return review;
  }

  @override
  Future<BookItem> createBook(BookPayload payload) async {
    final uid = _current?.id ?? 'demo-user';
    final item = BookItem(
      id: 'book-${++_seq}',
      sellerId: uid,
      judul: payload.judul.trim(),
      kategori: payload.kategori,
      kondisi: payload.kondisi,
      deskripsi: payload.deskripsi.trim(),
      jenisListing: payload.jenisListing,
      harga: payload.jenisListing == ListingType.donasi ? 0 : payload.harga,
      fotoUrl: payload.existingFotoUrl ?? '',
      status: BookStatus.tersedia,
      namaPenjual: payload.namaPenjual.trim(),
      kontakWa: payload.kontakWa.trim(),
      lokasi: payload.lokasi.trim(),
      createdAt: DateTime.now(),
    );
    _books.insert(0, item);
    _emit();
    return item;
  }

  @override
  Future<BookItem> updateBook(String bookId, BookPayload payload) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) throw Exception('Buku tidak ditemukan.');
    final updated = _books[idx].copyWith(
      judul: payload.judul.trim(),
      kategori: payload.kategori,
      kondisi: payload.kondisi,
      deskripsi: payload.deskripsi.trim(),
      jenisListing: payload.jenisListing,
      harga: payload.jenisListing == ListingType.donasi ? 0 : payload.harga,
      fotoUrl: payload.existingFotoUrl ?? _books[idx].fotoUrl,
      namaPenjual: payload.namaPenjual.trim(),
      kontakWa: payload.kontakWa.trim(),
      lokasi: payload.lokasi.trim(),
    );
    _books[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<void> updateBookStatus(String bookId, BookStatus status) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    _books[idx] = _books[idx].copyWith(status: status);
    _emit();
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _books.removeWhere((b) => b.id == bookId);
    _wishlist.remove(bookId);
    _emit();
  }

  @override
  Future<Set<String>> fetchWishlistIds() async => Set<String>.from(_wishlist);

  @override
  Future<List<BookItem>> fetchWishlistBooks() async {
    return _books.where((b) => _wishlist.contains(b.id)).toList();
  }

  @override
  Future<bool> toggleWishlist(String bookId) async {
    final added = !_wishlist.contains(bookId);
    if (added) {
      _wishlist.add(bookId);
    } else {
      _wishlist.remove(bookId);
    }
    _emit();
    return added;
  }

  List<ConversationSummary> _buildConvList() {
    final uid = _current?.id ?? 'demo-user';
    final result = <ConversationSummary>[];
    for (final c in _convs) {
      if (c.buyerId != uid && c.sellerId != uid) continue;
      final book = _books.firstWhere(
        (b) => b.id == c.bookId,
        orElse: () => _books.first,
      );
      final convMsgs = _messages.where((m) => m.conversationId == c.id).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final last = convMsgs.isEmpty ? null : convMsgs.last;
      final unread = convMsgs
          .where((m) => m.senderId != uid && !m.isRead)
          .length;
      final otherId = c.buyerId == uid ? c.sellerId : c.buyerId;
      result.add(
        ConversationSummary(
          id: c.id,
          buyerId: c.buyerId,
          sellerId: c.sellerId,
          bookId: c.bookId,
          bookTitle: book.judul,
          bookFotoUrl: book.fotoUrl,
          bookHarga: book.harga,
          bookJenis: book.jenisListing,
          bookStatus: book.status,
          otherUserName: _sellers[otherId]?.nama ?? book.namaPenjual,
          lastMessage: last?.isi ?? '',
          lastMessageSenderId: last?.senderId,
          unreadCount: unread,
          updatedAt: last?.createdAt ?? c.updatedAt,
        ),
      );
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Stream<T> _reactiveStream<T>(T Function() compute) async* {
    yield compute();
    await for (final _ in _changes.stream) {
      yield compute();
    }
  }

  @override
  Stream<List<ConversationSummary>> watchConversations() =>
      _reactiveStream(_buildConvList);

  @override
  Future<ConversationSummary> getOrCreateConversation(BookItem book) async {
    final uid = _current?.id ?? 'demo-user';
    final existing = _convs.where(
      (c) =>
          c.buyerId == uid &&
          c.sellerId == book.sellerId &&
          c.bookId == book.id,
    );
    if (existing.isEmpty) {
      _convs.add(
        _DemoConv(
          id: 'conv-${++_seq}',
          buyerId: uid,
          sellerId: book.sellerId,
          bookId: book.id,
          updatedAt: DateTime.now(),
        ),
      );
      _emit();
    }
    return _buildConvList().firstWhere(
      (s) => s.bookId == book.id && s.buyerId == uid,
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _reactiveStream(() {
      return _messages.where((m) => m.conversationId == conversationId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final uid = _current?.id ?? 'demo-user';
    _messages.add(
      ChatMessage(
        id: 'msg-${++_seq}',
        conversationId: conversationId,
        senderId: uid,
        isi: clean,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    final uid = _current?.id ?? 'demo-user';
    var changed = false;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.conversationId == conversationId &&
          m.senderId != uid &&
          !m.isRead) {
        _messages[i] = ChatMessage(
          id: m.id,
          conversationId: m.conversationId,
          senderId: m.senderId,
          isi: m.isi,
          isRead: true,
          createdAt: m.createdAt,
        );
        changed = true;
      }
    }
    if (changed) _emit();
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return _reactiveStream(() {
      return List<AppNotification>.from(_notifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1) return;
    final n = _notifications[idx];
    _notifications[idx] = AppNotification(
      id: n.id,
      userId: n.userId,
      tipe: n.tipe,
      judul: n.judul,
      isi: n.isi,
      refId: n.refId,
      isRead: true,
      createdAt: n.createdAt,
    );
    _emit();
  }

  @override
  Future<void> markAllNotificationsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      _notifications[i] = AppNotification(
        id: n.id,
        userId: n.userId,
        tipe: n.tipe,
        judul: n.judul,
        isi: n.isi,
        refId: n.refId,
        isRead: true,
        createdAt: n.createdAt,
      );
    }
    _emit();
  }

  @override
  void dispose() {
    _changes.close();
  }
}

class _DemoConv {
  _DemoConv({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.bookId,
    required this.updatedAt,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final String bookId;
  final DateTime updatedAt;
}
