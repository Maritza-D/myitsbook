import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/data/models.dart';

class BookCoverImage extends StatelessWidget {
  const BookCoverImage({
    super.key,
    required this.fotoUrl,
    required this.title,
    this.category,
    this.fit = BoxFit.cover,
    this.desaturated = false,
  });

  final String fotoUrl;
  final String title;
  final String? category;
  final BoxFit fit;
  final bool desaturated;

  @override
  Widget build(BuildContext context) {
    final colors = AppSemanticColors.of(context);

    Widget child;
    if (fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://')) {
      child = CachedNetworkImage(
        imageUrl: fotoUrl,
        fit: fit,
        placeholder: (_, _) =>
            _EditorialBookJacket(category: category, colors: colors),
        errorWidget: (_, _, _) =>
            _EditorialBookJacket(category: category, colors: colors),
      );
    } else if (fotoUrl.startsWith('file://') ||
        fotoUrl.contains(':\\') ||
        fotoUrl.startsWith('/')) {
      final path = fotoUrl.replaceFirst('file://', '');
      child = Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, _, _) =>
            _EditorialBookJacket(category: category, colors: colors),
      );
    } else {
      child = _EditorialBookJacket(category: category, colors: colors);
    }

    if (!desaturated) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 0.72, 0,
      ]),
      child: child,
    );
  }
}

class _EditorialBookJacket extends StatelessWidget {
  const _EditorialBookJacket({required this.colors, this.category});

  final AppSemanticColors colors;
  final String? category;

  ({List<Color> grad, Color accent, IconData icon}) _palette(bool isDark) {
    switch (category) {
      case 'Kamus':
        return (
          grad: isDark
              ? const [Color(0xFF1A2D46), Color(0xFF101D30)]
              : const [Color(0xFFE4EEF9), Color(0xFFCEDFF3)],
          accent: const Color(0xFF4F83BE),
          icon: Icons.translate_rounded,
        );
      case 'Novel':
        return (
          grad: isDark
              ? const [Color(0xFF1E2546), Color(0xFF111831)]
              : const [Color(0xFFE9ECFA), Color(0xFFD6DFF5)],
          accent: const Color(0xFF5D76B8),
          icon: Icons.auto_stories_outlined,
        );
      case 'Komik':
        return (
          grad: isDark
              ? const [Color(0xFF172D4B), Color(0xFF0E1D34)]
              : const [Color(0xFFE5F0FB), Color(0xFFCCE1F7)],
          accent: const Color(0xFF3E7BC4),
          icon: Icons.collections_bookmark_outlined,
        );
      default:
        return (
          grad: isDark
              ? const [Color(0xFF15294A), Color(0xFF0B182E)]
              : const [Color(0xFFE6EFFA), Color(0xFFD0E1F5)],
          accent: const Color(0xFF0B2245),
          icon: Icons.menu_book_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _palette(isDark);
    final lineTint = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF0B2245).withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.grad,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle architectural silver ring motif
          Positioned(
            right: -28,
            bottom: -28,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? colors.silverGlow : p.accent)
                      .withValues(alpha: 0.12),
                  width: 14,
                ),
              ),
            ),
          ),
          // Embossed book spine crease on the left
          Positioned(
            left: 11,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                Container(width: 1.2, color: lineTint),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.45),
                ),
              ],
            ),
          ),
          // Centered minimalist hardcover medallion
          Center(
            child: Container(
              width: 48,
              height: 58,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF0B2245).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Icon(
                p.icon,
                size: 22,
                color: isDark ? colors.silverGlow : p.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.isWishlisted,
    required this.onTap,
    this.onToggleWishlist,
    this.heroPrefix = 'grid',
  });

  final BookItem book;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback? onToggleWishlist;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unavailable = !book.isAvailable;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: semantic.border.withValues(alpha: isDark ? 0.9 : 0.85),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0B2245).withValues(alpha: 0.055),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: '$heroPrefix-cover-${book.id}',
                      child: BookCoverImage(
                        fotoUrl: book.fotoUrl,
                        title: book.judul,
                        category: book.kategori,
                        desaturated: unavailable,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _ListingStatusBadge(book: book),
                    ),
                    if (onToggleWishlist != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _HeartPillButton(
                          saved: isWishlisted,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onToggleWishlist!();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: unavailable
                              ? semantic.textMuted
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.isDonation ? 'Gratis' : formatRupiah(book.harga),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: unavailable
                              ? semantic.textMuted
                              : (book.isDonation
                                    ? semantic.donation
                                    : scheme.primary),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: semantic.subtleSurface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              book.kondisi,
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: semantic.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 12.5,
                            color: semantic.silverBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.namaPenjual,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: semantic.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartPillButton extends StatelessWidget {
  const _HeartPillButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    return IconButton(
      onPressed: onTap,
      tooltip: saved ? 'Hapus dari wishlist' : 'Simpan ke wishlist',
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
      icon: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.86),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 0.8,
              ),
            ),
            child: AnimatedScale(
              scale: saved ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: saved ? scheme.error : semantic.navy,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingStatusBadge extends StatelessWidget {
  const _ListingStatusBadge({required this.book});

  final BookItem book;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    late final Color bg;
    late final Color fg;
    late final String label;

    if (!book.isAvailable) {
      bg = const Color(0xFF334155);
      fg = Colors.white;
      label = book.status.label;
    } else if (book.isDonation) {
      bg = semantic.donation;
      fg = semantic.onDonation;
      label = 'Gratis';
    } else {
      bg = const Color(0xFF0B2245).withValues(alpha: 0.9);
      fg = Colors.white;
      label = 'Dijual';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}
