import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/data/models.dart';

/// Data pengajuan pembelian yang diisi pembeli.
class BuyRequest {
  const BuyRequest({required this.location, this.note = ''});

  final String location;
  final String note;
}

/// Menampilkan bottom sheet "Beli Buku" / "Ambil Donasi".
/// Mengembalikan [BuyRequest] jika pembeli menekan tombol ajukan.
Future<BuyRequest?> showBuyBookSheet({
  required BuildContext context,
  required BookItem book,
}) {
  return showAppBottomSheet<BuyRequest>(
    context: context,
    builder: (_) => _BuyBookSheetBody(book: book),
  );
}

/// Pesan otomatis yang dikirim ke penjual saat pembeli mengajukan pembelian.
String buildPurchaseRequestMessage(BookItem book, BuyRequest request) {
  final buf = StringBuffer();
  if (book.isDonation) {
    buf.write('Halo, saya ingin mengambil donasi buku "${book.judul}".');
  } else {
    buf.write(
      'Halo, saya ingin membeli buku "${book.judul}" '
      'seharga ${formatRupiah(book.harga)}.',
    );
  }
  buf.write('\nUsulan serah terima: ${request.location}.');
  final note = request.note.trim();
  if (note.isNotEmpty) {
    buf.write('\nCatatan: $note');
  }
  buf.write('\nMohon konfirmasinya, terima kasih.');
  return buf.toString();
}

class _BuyBookSheetBody extends StatefulWidget {
  const _BuyBookSheetBody({required this.book});

  final BookItem book;

  @override
  State<_BuyBookSheetBody> createState() => _BuyBookSheetBodyState();
}

class _BuyBookSheetBodyState extends State<_BuyBookSheetBody> {
  final _noteCtrl = TextEditingController();
  late String _location;

  @override
  void initState() {
    super.initState();
    _location = kCampusLocations.contains(widget.book.lokasi)
        ? widget.book.lokasi
        : kCampusLocations.first;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final book = widget.book;
    final isDonation = book.isDonation;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isDonation ? 'Ajukan Pengambilan Donasi' : 'Ajukan Pembelian',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: semantic.subtleSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BookCoverImage(
                      fotoUrl: book.fotoUrl,
                      title: book.judul,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Penjual: ${book.namaPenjual}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: semantic.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isDonation ? 'Gratis' : formatRupiah(book.harga),
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDonation ? semantic.donation : scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Usulan lokasi serah terima',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final loc in kCampusLocations)
                ChoiceChip(
                  label: Text(loc, style: const TextStyle(fontSize: 12)),
                  selected: _location == loc,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _location = loc);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _noteCtrl,
            maxLength: 120,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan untuk penjual (opsional)',
              hintText: 'Contoh: bisa bertemu sore hari setelah kuliah',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: semantic.warningContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: semantic.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDonation
                        ? 'Pengajuan akan dikirim ke donatur lewat chat. Serah terima dilakukan langsung di kampus.'
                        : 'Pengajuan akan dikirim ke penjual lewat chat. Pembayaran dilakukan langsung (COD) saat serah terima di kampus.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: semantic.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(
              BuyRequest(location: _location, note: _noteCtrl.text),
            ),
            icon: Icon(
              isDonation
                  ? Icons.volunteer_activism_outlined
                  : Icons.shopping_bag_outlined,
              size: 18,
            ),
            label: Text(
              isDonation ? 'Kirim Pengajuan Donasi' : 'Kirim Pengajuan Beli',
            ),
          ),
        ],
      ),
    );
  }
}