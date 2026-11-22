import 'package:flutter_test/flutter_test.dart';
import 'package:myitsbook/core/utils/date_labels.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/features/transaction/buy_book_sheet.dart';

BookItem _book({ListingType type = ListingType.jual, int harga = 45000}) {
  return BookItem(
    id: 'b1',
    sellerId: 's1',
    judul: 'Kalkulus Jilid 1',
    kategori: 'Buku Kuliah',
    kondisi: 'Baik',
    deskripsi: 'Masih mulus',
    jenisListing: type,
    harga: harga,
    fotoUrl: '',
    status: BookStatus.tersedia,
    namaPenjual: 'Rae',
    kontakWa: '081234567890',
    lokasi: 'Perpustakaan Pusat ITS',
    createdAt: DateTime(2026, 11, 5),
  );
}

void main() {
  group('Pengajuan pembelian', () {
    test('pesan beli memuat judul, harga, lokasi, dan catatan', () {
      final msg = buildPurchaseRequestMessage(
        _book(),
        const BuyRequest(location: 'Kantin Pusat ITS', note: 'Sore ya'),
      );
      expect(msg, contains('Kalkulus Jilid 1'));
      expect(msg, contains('Rp 45.000'));
      expect(msg, contains('Kantin Pusat ITS'));
      expect(msg, contains('Catatan: Sore ya'));
    });

    test('pesan donasi tidak memuat harga dan catatan kosong dilewati', () {
      final msg = buildPurchaseRequestMessage(
        _book(type: ListingType.donasi, harga: 0),
        const BuyRequest(location: 'Bundaran ITS'),
      );
      expect(msg, contains('mengambil donasi'));
      expect(msg, isNot(contains('Rp')));
      expect(msg, isNot(contains('Catatan:')));
    });
  });

  group('Label tanggal chat', () {
    final now = DateTime(2026, 11, 22, 10);

    test('hari ini, kemarin, dan tanggal biasa', () {
      expect(formatDayLabel(DateTime(2026, 11, 22, 8), now: now), 'Hari ini');
      expect(formatDayLabel(DateTime(2026, 11, 21, 23), now: now), 'Kemarin');
      expect(formatDayLabel(DateTime(2026, 11, 5), now: now), '5 Nov 2026');
    });
  });
}