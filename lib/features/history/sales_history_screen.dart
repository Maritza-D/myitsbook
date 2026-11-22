import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/date_labels.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_detail_screen.dart';

/// Riwayat buku yang sudah selesai dijual / didonasikan oleh pengguna.
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.wishlistIds,
    required this.onToggleWishlist,
    required this.onDataMutated,
  });

  final AppRepository repository;
  final UserProfile profile;
  final Set<String> wishlistIds;
  final ValueChanged<String> onToggleWishlist;
  final VoidCallback onDataMutated;

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  ListingType _tab = ListingType.jual;
  List<BookItem> _books = [];
  bool _loading = true;
  bool _newestFirst = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _books.isEmpty;
      _error = null;
    });
    try {
      final items = await widget.repository.fetchMyBooks();
      if (!mounted) return;
      setState(() {
        _books = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapAppError(e);
        _loading = false;
      });
    }
  }

  bool _isCompleted(BookItem b) =>
      b.status == BookStatus.terjual || b.status == BookStatus.selesai;

  List<BookItem> get _completed {
    final list = _books
        .where((b) => b.jenisListing == _tab && _isCompleted(b))
        .toList();
    list.sort(
      (a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return list;
  }

  int get _inProgressCount => _books
      .where(
        (b) => b.jenisListing == _tab && b.status == BookStatus.dalamProses,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = _completed;
    final isSale = _tab == ListingType.jual;
    final totalRevenue = items.fold<int>(0, (sum, b) => sum + b.harga);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Dijual & Donasi'),
        actions: [
          IconButton(
            tooltip: _newestFirst ? 'Urutkan terlama' : 'Urutkan terbaru',
            icon: Icon(
              _newestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
            ),
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: semantic.subtleSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      for (final opt in [
                        (ListingType.jual, 'Riwayat Dijual'),
                        (ListingType.donasi, 'Riwayat Donasi'),
                      ])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = opt.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tab == opt.$1
                                    ? scheme.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                opt.$2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 13,
                                  fontWeight: _tab == opt.$1
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _tab == opt.$1
                                      ? scheme.primary
                                      : semantic.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: semantic.border),
                  ),
                  child: Row(
                    children: [
                      _SummaryStat(
                        label: isSale ? 'Buku Terjual' : 'Buku Didonasikan',
                        value: '${items.length}',
                      ),
                      Container(width: 1, height: 32, color: semantic.border),
                      if (isSale)
                        _SummaryStat(
                          label: 'Total Pendapatan',
                          value: formatRupiah(totalRevenue),
                        )
                      else
                        _SummaryStat(
                          label: 'Dalam Proses',
                          value: '$_inProgressCount',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ErrorRetryView(message: _error!, onRetry: _load)
                : items.isEmpty
                ? EmptyStateView(
                    icon: Icons.history_rounded,
                    title: isSale
                        ? 'Belum ada buku yang terjual'
                        : 'Belum ada donasi yang selesai',
                    subtitle: isSale
                        ? 'Buku yang statusnya sudah Anda ubah menjadi Terjual akan muncul di sini.'
                        : 'Buku donasi yang statusnya sudah Anda ubah menjadi Selesai akan muncul di sini.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, idx) {
                        final book = items[idx];
                        return _HistoryTile(
                          book: book,
                          onTap: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(
                                  repository: widget.repository,
                                  profile: widget.profile,
                                  bookId: book.id,
                                  initialBook: book,
                                  isWishlisted: widget.wishlistIds.contains(
                                    book.id,
                                  ),
                                  onToggleWishlist: () =>
                                      widget.onToggleWishlist(book.id),
                                  onBookChanged: widget.onDataMutated,
                                ),
                              ),
                            );
                            _load();
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: semantic.navy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: semantic.textMuted),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.book, required this.onTap});

  final BookItem book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final isDonation = book.isDonation;
    final badgeColor = isDonation ? semantic.donation : semantic.silverBlue;
    final badgeBg = isDonation
        ? semantic.donationContainer
        : semantic.silverFrost;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 76,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BookCoverImage(
                    fotoUrl: book.fotoUrl,
                    title: book.judul,
                    desaturated: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book.status.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDonation ? 'Donasi · Gratis' : formatRupiah(book.harga),
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDonation
                            ? semantic.donation
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Diunggah ${formatShortDate(book.createdAt)} · ${book.lokasi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: semantic.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: semantic.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
