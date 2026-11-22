import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_detail_screen.dart';
import 'package:myitsbook/features/books/book_form_screen.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({
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
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  ListingType _tab = ListingType.jual;
  List<BookItem> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
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

  Future<void> _updateStatus(BookItem book, BookStatus status) async {
    try {
      await widget.repository.updateBookStatus(book.id, status);
      widget.onDataMutated();
      await _load();
      if (!mounted) return;
      if (status == BookStatus.terjual || status == BookStatus.selesai) {
        await showBookCompletedBottomSheet(
          context: context,
          book: book,
          newStatus: status,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    }
  }

  Future<void> _confirmDelete(BookItem book) async {
    final ok = await showConfirmBottomSheet(
      context: context,
      title: 'Hapus Daftar Buku?',
      message: 'Buku "${book.judul}" akan dihapus permanen dari katalog.',
      confirmLabel: 'Hapus Buku',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok) return;
    try {
      await widget.repository.deleteBook(book.id);
      widget.onDataMutated();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    }
  }

  Future<void> _pickStatus(BookItem book) async {
    final options = [
      BookStatus.tersedia,
      BookStatus.dalamProses,
      book.isDonation ? BookStatus.selesai : BookStatus.terjual,
    ];
    final picked = await showAppBottomSheet<BookStatus>(
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
              Text(
                'Ubah Status Buku',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(book.judul, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              for (final s in options) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: s == book.status
                          ? scheme.primary
                          : semantic.border,
                      width: s == book.status ? 1.6 : 1,
                    ),
                  ),
                  tileColor: s == book.status
                      ? semantic.silverFrost
                      : scheme.surface,
                  title: Text(
                    s.label,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  trailing: s == book.status
                      ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(s),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
    if (picked != null && picked != book.status) {
      await _updateStatus(book, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final filtered = _books.where((b) => b.jenisListing == _tab).toList();
    final tersedia =
        filtered.where((b) => b.status == BookStatus.tersedia).length;
    final proses =
        filtered.where((b) => b.status == BookStatus.dalamProses).length;
    final selesai = filtered
        .where(
          (b) =>
              b.status == BookStatus.terjual || b.status == BookStatus.selesai,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Buku Saya'),
        actions: [
          IconButton(
            tooltip: 'Tambah Buku',
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BookFormScreen(
                    repository: widget.repository,
                    profile: widget.profile,
                    initialType: _tab,
                  ),
                ),
              );
              if (created == true) {
                widget.onDataMutated();
                _load();
              }
            },
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
                        (ListingType.jual, 'Dijual'),
                        (ListingType.donasi, 'Donasi'),
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
                      _StatusStat(
                        label: 'Tersedia',
                        count: tersedia,
                        dotColor: semantic.donation,
                      ),
                      Container(width: 1, height: 30, color: semantic.border),
                      _StatusStat(
                        label: 'Dalam Proses',
                        count: proses,
                        dotColor: semantic.warning,
                      ),
                      Container(width: 1, height: 30, color: semantic.border),
                      _StatusStat(
                        label:
                            _tab == ListingType.donasi ? 'Selesai' : 'Terjual',
                        count: selesai,
                        dotColor: semantic.silverBlue,
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
                : filtered.isEmpty
                ? EmptyStateView(
                    icon: Icons.library_books_outlined,
                    title: _tab == ListingType.jual
                        ? 'Belum ada buku dijual'
                        : 'Belum ada buku donasi',
                    subtitle:
                        'Tambahkan buku bekas layak pakai Anda agar mudah ditemukan sivitas akademika ITS.',
                    actionLabel: 'Unggah Sekarang',
                    onAction: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => BookFormScreen(
                            repository: widget.repository,
                            profile: widget.profile,
                            initialType: _tab,
                          ),
                        ),
                      );
                      if (created == true) {
                        widget.onDataMutated();
                        _load();
                      }
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, idx) {
                        final book = filtered[idx];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) => BookDetailScreen(
                                          repository: widget.repository,
                                          profile: widget.profile,
                                          bookId: book.id,
                                          initialBook: book,
                                          isWishlisted: widget.wishlistIds
                                              .contains(book.id),
                                          onToggleWishlist: () =>
                                              widget.onToggleWishlist(book.id),
                                          onBookChanged: widget.onDataMutated,
                                        ),
                                      ),
                                    );
                                    _load();
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 68,
                                        height: 86,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: BookCoverImage(
                                            fotoUrl: book.fotoUrl,
                                            title: book.judul,
                                            desaturated: !book.isAvailable,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: book.isAvailable
                                                    ? semantic.donationContainer
                                                    : semantic.warningContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                book.status.label.toUpperCase(),
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.bodyFont,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.6,
                                                  color: book.isAvailable
                                                      ? semantic.donation
                                                      : semantic.warning,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              book.judul,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              book.isDonation
                                                  ? 'Donasi · Gratis'
                                                  : formatRupiah(book.harga),
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTheme.displayFont,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                                color: book.isDonation
                                                    ? semantic.donation
                                                    : scheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 22, color: semantic.border),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _pickStatus(book),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(48, 42),
                                        ),
                                        child: const Text('Status'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final edited =
                                              await Navigator.of(context)
                                                  .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => BookFormScreen(
                                                repository: widget.repository,
                                                profile: widget.profile,
                                                initialType: book.jenisListing,
                                                editingBook: book,
                                              ),
                                            ),
                                          );
                                          if (edited == true) {
                                            widget.onDataMutated();
                                            _load();
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(48, 42),
                                        ),
                                        child: const Text('Edit'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _confirmDelete(book),
                                      tooltip: 'Hapus buku',
                                      style: IconButton.styleFrom(
                                        backgroundColor: scheme.error
                                            .withValues(alpha: 0.08),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: scheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

class _StatusStat extends StatelessWidget {
  const _StatusStat({
    required this.label,
    required this.count,
    required this.dotColor,
  });

  final String label;
  final int count;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: semantic.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
