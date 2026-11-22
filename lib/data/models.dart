enum ListingType {
  jual('jual', 'Dijual'),
  donasi('donasi', 'Donasi');

  const ListingType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static ListingType fromDb(String value) {
    return ListingType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ListingType.jual,
    );
  }
}

enum BookStatus {
  tersedia('tersedia', 'Tersedia'),
  dalamProses('dalam_proses', 'Dalam Proses'),
  terjual('terjual', 'Terjual'),
  selesai('selesai', 'Selesai');

  const BookStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static BookStatus fromDb(String value) {
    return BookStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => BookStatus.tersedia,
    );
  }
}

enum BookSort {
  terbaru('Terbaru'),
  termurah('Harga Terendah'),
  termahal('Harga Tertinggi');

  const BookSort(this.label);
  final String label;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.nama,
    required this.nrp,
    required this.jurusan,
    required this.telepon,
    required this.email,
    required this.role,
    required this.statusVerifikasi,
    required this.ratingRata2,
  });

  final String id;
  final String nama;
  final String nrp;
  final String jurusan;
  final String telepon;
  final String email;
  final String role;
  final String statusVerifikasi;
  final double ratingRata2;

  String get firstName {
    final parts = nama.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'Mahasiswa' : parts.first;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      nama: (map['nama'] ?? 'Mahasiswa ITS') as String,
      nrp: (map['nrp'] ?? '') as String,
      jurusan: (map['jurusan'] ?? '') as String,
      telepon: (map['telepon'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? 'mahasiswa') as String,
      statusVerifikasi: (map['status_verifikasi'] ?? 'terverifikasi') as String,
      ratingRata2: ((map['rating_rata2'] ?? 0) as num).toDouble(),
    );
  }

  UserProfile copyWith({
    String? nama,
    String? jurusan,
    String? telepon,
  }) {
    return UserProfile(
      id: id,
      nama: nama ?? this.nama,
      nrp: nrp,
      jurusan: jurusan ?? this.jurusan,
      telepon: telepon ?? this.telepon,
      email: email,
      role: role,
      statusVerifikasi: statusVerifikasi,
      ratingRata2: ratingRata2,
    );
  }
}

class SellerInfo {
  const SellerInfo({
    required this.id,
    required this.nama,
    required this.jurusan,
    required this.statusVerifikasi,
    required this.ratingRata2,
  });

  final String id;
  final String nama;
  final String jurusan;
  final String statusVerifikasi;
  final double ratingRata2;

  factory SellerInfo.fromMap(Map<String, dynamic> map) {
    return SellerInfo(
      id: map['id'] as String,
      nama: (map['nama'] ?? 'Mahasiswa ITS') as String,
      jurusan: (map['jurusan'] ?? 'ITS') as String,
      statusVerifikasi: (map['status_verifikasi'] ?? 'terverifikasi') as String,
      ratingRata2: ((map['rating_rata2'] ?? 0) as num).toDouble(),
    );
  }
}

class BookItem {
  const BookItem({
    required this.id,
    required this.sellerId,
    required this.judul,
    required this.kategori,
    required this.kondisi,
    required this.deskripsi,
    required this.jenisListing,
    required this.harga,
    required this.fotoUrl,
    required this.status,
    required this.namaPenjual,
    required this.kontakWa,
    required this.lokasi,
    required this.createdAt,
  });

  final String id;
  final String sellerId;
  final String judul;
  final String kategori;
  final String kondisi;
  final String deskripsi;
  final ListingType jenisListing;
  final int harga;
  final String fotoUrl;
  final BookStatus status;
  final String namaPenjual;
  final String kontakWa;
  final String lokasi;
  final DateTime createdAt;

  bool get isDonation => jenisListing == ListingType.donasi;
  bool get isAvailable => status == BookStatus.tersedia;

  factory BookItem.fromMap(Map<String, dynamic> map) {
    return BookItem(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      judul: (map['judul'] ?? '') as String,
      kategori: (map['kategori'] ?? 'Buku Kuliah') as String,
      kondisi: (map['kondisi'] ?? 'Baik') as String,
      deskripsi: (map['deskripsi'] ?? '') as String,
      jenisListing: ListingType.fromDb((map['jenis_listing'] ?? 'jual') as String),
      harga: ((map['harga'] ?? 0) as num).toInt(),
      fotoUrl: (map['foto_url'] ?? '') as String,
      status: BookStatus.fromDb((map['status'] ?? 'tersedia') as String),
      namaPenjual: (map['nama_penjual'] ?? '') as String,
      kontakWa: (map['kontak_wa'] ?? '') as String,
      lokasi: (map['lokasi'] ?? '') as String,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  BookItem copyWith({
    String? judul,
    String? kategori,
    String? kondisi,
    String? deskripsi,
    ListingType? jenisListing,
    int? harga,
    String? fotoUrl,
    BookStatus? status,
    String? namaPenjual,
    String? kontakWa,
    String? lokasi,
  }) {
    return BookItem(
      id: id,
      sellerId: sellerId,
      judul: judul ?? this.judul,
      kategori: kategori ?? this.kategori,
      kondisi: kondisi ?? this.kondisi,
      deskripsi: deskripsi ?? this.deskripsi,
      jenisListing: jenisListing ?? this.jenisListing,
      harga: harga ?? this.harga,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      status: status ?? this.status,
      namaPenjual: namaPenjual ?? this.namaPenjual,
      kontakWa: kontakWa ?? this.kontakWa,
      lokasi: lokasi ?? this.lokasi,
      createdAt: createdAt,
    );
  }
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.bookId,
    required this.bookTitle,
    required this.bookFotoUrl,
    required this.bookHarga,
    required this.bookJenis,
    required this.bookStatus,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.unreadCount,
    required this.updatedAt,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final String bookId;
  final String bookTitle;
  final String bookFotoUrl;
  final int bookHarga;
  final ListingType bookJenis;
  final BookStatus bookStatus;
  final String otherUserName;
  final String lastMessage;
  final String? lastMessageSenderId;
  final int unreadCount;
  final DateTime updatedAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.isi,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String isi;
  final bool isRead;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      isi: (map['isi'] ?? '') as String,
      isRead: (map['is_read'] ?? false) as bool,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.tipe,
    required this.judul,
    required this.isi,
    required this.refId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String tipe;
  final String judul;
  final String isi;
  final String? refId;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      tipe: (map['tipe'] ?? 'sistem') as String,
      judul: (map['judul'] ?? '') as String,
      isi: (map['isi'] ?? '') as String,
      refId: map['ref_id'] as String?,
      isRead: (map['is_read'] ?? false) as bool,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
