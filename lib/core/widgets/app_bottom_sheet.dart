import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/data/models.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: builder(ctx),
        ),
      );
    },
  );
}

Future<bool> showConfirmBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final semantic = AppSemanticColors.of(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      final accent = destructive ? scheme.error : scheme.primary;
      final accentBg = destructive
          ? scheme.error.withValues(alpha: 0.12)
          : semantic.silverFrost;

      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: semantic.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel),
            ),
          ],
        ),
      );
    },
  );
  return result == true;
}

Future<void> showBookCompletedBottomSheet({
  required BuildContext context,
  required BookItem book,
  required BookStatus newStatus,
}) {
  final isDonasi = book.isDonation || newStatus == BookStatus.selesai;
  return showAppBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final semantic = AppSemanticColors.of(ctx);
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: semantic.donationContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: semantic.donation,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isDonasi ? 'Donasi Buku Selesai!' : 'Buku Telah Terjual!',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              isDonasi
                  ? 'Terima kasih telah mendonasikan buku bagi sivitas akademika ITS.'
                  : 'Selamat, status buku Anda telah diperbarui di katalog.',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: semantic.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: semantic.subtleSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: semantic.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 64,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          book.isDonation ? 'Gratis' : formatRupiah(book.harga),
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: book.isDonation
                                ? semantic.donation
                                : scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${newStatus.label}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: semantic.donation,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    },
  );
}

class FilterSheetResult {
  const FilterSheetResult({
    this.jenis,
    this.kondisi,
    this.minPrice,
    this.maxPrice,
    this.lokasi,
    this.sort = BookSort.terbaru,
  });

  final ListingType? jenis;
  final String? kondisi;
  final int? minPrice;
  final int? maxPrice;
  final String? lokasi;
  final BookSort sort;
}

Future<FilterSheetResult?> showBookFilterSheet({
  required BuildContext context,
  ListingType? initialJenis,
  String? initialKondisi,
  int? initialMinPrice,
  int? initialMaxPrice,
  String? initialLokasi,
  BookSort initialSort = BookSort.terbaru,
}) {
  return showAppBottomSheet<FilterSheetResult>(
    context: context,
    builder: (ctx) => _FilterSheetBody(
      initialJenis: initialJenis,
      initialKondisi: initialKondisi,
      initialMinPrice: initialMinPrice,
      initialMaxPrice: initialMaxPrice,
      initialLokasi: initialLokasi,
      initialSort: initialSort,
    ),
  );
}

class _FilterSheetBody extends StatefulWidget {
  const _FilterSheetBody({
    this.initialJenis,
    this.initialKondisi,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialLokasi,
    required this.initialSort,
  });

  final ListingType? initialJenis;
  final String? initialKondisi;
  final int? initialMinPrice;
  final int? initialMaxPrice;
  final String? initialLokasi;
  final BookSort initialSort;

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  ListingType? _jenis;
  String? _kondisi;
  late BookSort _sort;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _jenis = widget.initialJenis;
    _kondisi = widget.initialKondisi;
    _sort = widget.initialSort;
    _minCtrl = TextEditingController(
      text: widget.initialMinPrice?.toString() ?? '',
    );
    _maxCtrl = TextEditingController(
      text: widget.initialMaxPrice?.toString() ?? '',
    );
    _locCtrl = TextEditingController(text: widget.initialLokasi ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _jenis = null;
      _kondisi = null;
      _sort = BookSort.terbaru;
      _minCtrl.clear();
      _maxCtrl.clear();
      _locCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter & Urutkan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: semantic.silverBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Jenis Penawaran', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillChoice(
                label: 'Semua',
                selected: _jenis == null,
                onTap: () => setState(() => _jenis = null),
              ),
              _PillChoice(
                label: 'Dijual',
                selected: _jenis == ListingType.jual,
                onTap: () => setState(() => _jenis = ListingType.jual),
              ),
              _PillChoice(
                label: 'Donasi',
                selected: _jenis == ListingType.donasi,
                onTap: () => setState(() => _jenis = ListingType.donasi),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Kondisi Fisik', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in kBookConditions)
                _PillChoice(
                  label: k,
                  selected: _kondisi == k,
                  onTap: () => setState(() => _kondisi = _kondisi == k ? null : k),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Rentang Harga', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Rp Minimum',
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 12,
                  height: 2,
                  color: semantic.textMuted,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Rp Maksimum',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Lokasi Penjual', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _locCtrl,
            decoration: InputDecoration(
              hintText: 'Contoh: Gedung SI, Perpustakaan ITS',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: semantic.silverBlue,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Urutkan',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<BookSort>(
            initialValue: _sort,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final s in BookSort.values)
                DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _sort = val);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final minP = int.tryParse(_minCtrl.text.trim());
              final maxP = int.tryParse(_maxCtrl.text.trim());
              final loc = _locCtrl.text.trim();
              Navigator.of(context).pop(
                FilterSheetResult(
                  jenis: _jenis,
                  kondisi: _kondisi,
                  minPrice: minP,
                  maxPrice: maxP,
                  lokasi: loc.isEmpty ? null : loc,
                  sort: _sort,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            child: const Text('Terapkan Filter'),
          ),
        ],
      ),
    );
  }
}

class _PillChoice extends StatelessWidget {
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.primary : semantic.border,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : semantic.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
