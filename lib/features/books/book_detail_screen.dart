import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_form_screen.dart';
import 'package:myitsbook/features/chat/chat_room_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.bookId,
    this.initialBook,
    this.heroTag,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onBookChanged,
  });

  final AppRepository repository;
  final UserProfile profile;
  final String bookId;
  final BookItem? initialBook;
  final String? heroTag;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onBookChanged;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  BookItem? _book;
  SellerInfo? _seller;
  late bool _saved;
  bool _loading = true;
  bool _openingChat = false;
  bool _revealPhone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _book = widget.initialBook;
    _saved = widget.isWishlisted;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _book == null;
      _error = null;
    });
    try {
      final fetched = await widget.repository.fetchBookById(widget.bookId);
      if (fetched == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Buku tidak ditemukan atau sudah dihapus.';
          _loading = false;
        });
        return;
      }
      final seller = await widget.repository.fetchSellerInfo(fetched.sellerId);
      if (!mounted) return;
      setState(() {
        _book = fetched;
        _seller = seller;
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

  Future<void> _openChat({String? initialDraft}) async {
    final book = _book;
    if (book == null || !book.isAvailable) return;
    HapticFeedback.selectionClick();
    setState(() => _openingChat = true);
    try {
      final conv = await widget.repository.getOrCreateConversation(book);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            repository: widget.repository,
            profile: widget.profile,
            conversation: conv,
            initialDraft: initialDraft,
            onBookStatusUpdated: () {
              widget.onBookChanged();
              _load();
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _changeStatus(BookStatus status) async {
    final book = _book;
    if (book == null) return;
    try {
      await widget.repository.updateBookStatus(book.id, status);
      widget.onBookChanged();
      await _load();
      if (!mounted) return;
      if (status == BookStatus.terjual || status == BookStatus.selesai) {
        await showBookCompletedBottomSheet(
          context: context,
          book: book,
          newStatus: status,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status diperbarui menjadi ${status.label}.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    }
  }

  Future<void> _showContactSheet(BookItem book) async {
    await showAppBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final semantic = AppSemanticColors.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kontak ${book.isDonation ? 'Donatur' : 'Penjual'}',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Hubungi melalui WhatsApp atau mulai percakapan langsung melalui fitur Pesan MyITSBook.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: semantic.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: semantic.subtleSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: semantic.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined, color: semantic.navy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        book.kontakWa,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: book.kontakWa));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor WhatsApp disalin.'),
                          ),
                        );
                      },
                      child: const Text('Salin'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    );
    if (mounted) setState(() => _revealPhone = true);
  }

  String _maskPhone(String phone) {
    final clean = phone.trim();
    if (clean.length <= 7) return clean;
    return '${clean.substring(0, 4)} •••• ${clean.substring(clean.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final book = _book;
    final isOwner = book != null && book.sellerId == widget.profile.id;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || book == null
          ? SafeArea(
              child: Column(
                children: [
                  AppBar(title: const Text('Detail Buku')),
                  Expanded(
                    child: ErrorRetryView(
                      message: _error ?? 'Buku tidak tersedia.',
                      onRetry: _load,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.15,
                        child: widget.heroTag != null
                            ? Hero(
                                tag: widget.heroTag!,
                                child: BookCoverImage(
                                  fotoUrl: book.fotoUrl,
                                  title: book.judul,
                                  category: book.kategori,
                                  desaturated: !book.isAvailable,
                                ),
                              )
                            : BookCoverImage(
                                fotoUrl: book.fotoUrl,
                                title: book.judul,
                                category: book.kategori,
                                desaturated: !book.isAvailable,
                              ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _FrostedCircleButton(
                                tooltip: 'Kembali',
                                icon: Icons.chevron_left_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              _FrostedCircleButton(
                                tooltip: _saved
                                    ? 'Hapus dari Wishlist'
                                    : 'Simpan ke Wishlist',
                                icon: _saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                iconColor: _saved ? scheme.error : null,
                                scalePop: _saved,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _saved = !_saved);
                                  widget.onToggleWishlist();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                book.isDonation
                                    ? 'Gratis'
                                    : formatRupiah(book.harga),
                                style: TextStyle(
                                  fontFamily: AppTheme.displayFont,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: book.isDonation
                                      ? semantic.donation
                                      : scheme.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: book.isAvailable
                                    ? semantic.donationContainer
                                    : semantic.warningContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.5,
                                    height: 6.5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: book.isAvailable
                                          ? semantic.donation
                                          : semantic.warning,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    book.status.label,
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: book.isAvailable
                                          ? semantic.donation
                                          : semantic.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.judul,
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.25,
                            height: 1.32,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TagChip(
                              label: book.kategori,
                              bg: semantic.subtleSurface,
                              fg: semantic.textMuted,
                            ),
                            _TagChip(
                              label: book.kondisi,
                              bg: semantic.silverFrost,
                              fg: semantic.silverBlue,
                            ),
                            _TagChip(
                              label: book.isDonation ? 'Donasi' : 'Dijual',
                              bg: book.isDonation
                                  ? semantic.donationContainer
                                  : semantic.silverFrost,
                              fg: book.isDonation
                                  ? semantic.donation
                                  : semantic.navy,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _ConditionMeterCard(kondisi: book.kondisi),
                        Divider(height: 30, color: semantic.border),
                        Text(
                          'Deskripsi Buku',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.deskripsi,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: semantic.textMuted,
                                height: 1.56,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _SpecBox(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi Serah Terima',
                          value: book.lokasi,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SpecBox(
                                icon: Icons.menu_book_outlined,
                                label: 'Kategori',
                                value: book.kategori,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SpecBox(
                                icon: Icons.schedule_rounded,
                                label: 'Diperbarui',
                                value: formatRelativeTime(book.createdAt),
                              ),
                            ),
                          ],
                        ),
                        if (!isOwner && book.isAvailable) ...[
                          const SizedBox(height: 22),
                          Text(
                            'Pertanyaan Cepat',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: semantic.textMuted),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final prompt in [
                                'Halo, apakah buku ini masih tersedia?',
                                'Apakah tersedia serah terima di area kampus ITS?',
                                'Apakah boleh melihat foto kondisi halaman dalam?',
                              ])
                                ActionChip(
                                  avatar: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: semantic.silverBlue,
                                  ),
                                  label: Text(
                                    prompt,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  onPressed: _openingChat
                                      ? null
                                      : () => _openChat(initialDraft: prompt),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          book.isDonation
                              ? 'Informasi Donatur'
                              : 'Informasi Penjual',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: semantic.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: semantic.silverFrost,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  book.namaPenjual.isNotEmpty
                                      ? book.namaPenjual[0].toUpperCase()
                                      : 'M',
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: semantic.navy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _seller?.nama ?? book.namaPenjual,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTheme.bodyFont,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 15,
                                          color: semantic.silverBlue,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14.5,
                                          color: Color(0xFFEAB308),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            _seller != null
                                                ? '${_seller!.ratingRata2.toStringAsFixed(1)} · ${_seller!.jurusan}'
                                                : 'Mahasiswa ITS',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.subtleSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 19,
                                color: semantic.silverBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  !book.isAvailable
                                      ? 'Disembunyikan (buku tidak tersedia)'
                                      : (_revealPhone
                                            ? book.kontakWa
                                            : _maskPhone(book.kontakWa)),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 13.5,
                                        color: semantic.textMuted,
                                      ),
                                ),
                              ),
                              if (book.isAvailable)
                                TextButton(
                                  onPressed: () => _showContactSheet(book),
                                  style: TextButton.styleFrom(
                                    foregroundColor: semantic.silverBlue,
                                    minimumSize: const Size(48, 36),
                                  ),
                                  child: const Text('Tampilkan'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: book == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: semantic.border)),
                ),
                child: _buildBottomActions(context, book),
              ),
            ),
    );
  }

  Widget _buildBottomActions(BuildContext context, BookItem book) {
    final isOwner = book.sellerId == widget.profile.id;
    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final edited = await Navigator.of(context).push<bool>(
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
                  widget.onBookChanged();
                  _load();
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _showStatusPicker(book),
              icon: const Icon(Icons.sync_alt_rounded, size: 18),
              label: const Text('Ubah Status'),
            ),
          ),
        ],
      );
    }

    if (!book.isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: null,
          child: Text('Tidak Tersedia (${book.status.label})'),
        ),
      );
    }

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _saved = !_saved);
            widget.onToggleWishlist();
          },
          icon: Icon(
            _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: _saved ? Theme.of(context).colorScheme.error : null,
          ),
          label: Text(_saved ? 'Tersimpan' : 'Wishlist'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _openingChat ? null : () => _openChat(),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(
              book.isDonation ? 'Hubungi Donatur' : 'Hubungi Penjual',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showStatusPicker(BookItem book) async {
    final statuses = [
      BookStatus.tersedia,
      BookStatus.dalamProses,
      book.isDonation ? BookStatus.selesai : BookStatus.terjual,
    ];
    final chosen = await showAppBottomSheet<BookStatus>(
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
              Text(
                'Perbarui status ketersediaan buku agar calon pembeli memperoleh informasi terkini.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final st in statuses) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: st == book.status
                          ? scheme.primary
                          : semantic.border,
                      width: st == book.status ? 1.5 : 1,
                    ),
                  ),
                  tileColor: st == book.status
                      ? semantic.silverFrost
                      : scheme.surface,
                  title: Text(
                    st.label,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  trailing: st == book.status
                      ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(st),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
    if (chosen != null && chosen != book.status) {
      await _changeStatus(chosen);
    }
  }
}

class _ConditionMeterCard extends StatelessWidget {
  const _ConditionMeterCard({required this.kondisi});

  final String kondisi;

  int get _level {
    final k = kondisi.toLowerCase();
    if (k.contains('baru') || k.contains('sangat')) return 3;
    if (k.contains('cukup')) return 1;
    return 2;
  }

  String get _guide {
    switch (_level) {
      case 3:
        return 'Halaman bersih, jilid utuh, hampir tanpa bekas pakai.';
      case 2:
        return 'Layak baca, mungkin ada catatan tipis atau lipatan ringan.';
      default:
        return 'Masih terbaca jelas dan lengkap, terdapat tanda pemakaian.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final activeColor = _level == 3 ? semantic.navy : semantic.silverBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantic.subtleSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: semantic.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 17, color: activeColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Kondisi Fisik Buku',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: semantic.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kondisi,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= _level ? activeColor : semantic.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _guide,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: semantic.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.scalePop = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool scalePop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surface.withValues(alpha: 0.84),
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
          icon: AnimatedScale(
            scale: scalePop ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Icon(icon, color: iconColor ?? semantic.navy),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _SpecBox extends StatelessWidget {
  const _SpecBox({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: semantic.subtleSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: semantic.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: semantic.silverBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: semantic.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
