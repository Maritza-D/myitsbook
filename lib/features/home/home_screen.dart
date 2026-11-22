import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/app_logo.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_detail_screen.dart';
import 'package:myitsbook/features/notifications/notifications_screen.dart';
import 'package:myitsbook/features/profile/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.refreshTick,
    required this.wishlistIds,
    required this.unreadNotifCount,
    required this.onToggleWishlist,
    required this.onSearchSubmit,
    required this.onCategoryTap,
    required this.onFilterApplied,
    required this.onDonateNowTap,
    required this.onDataMutated,
  });

  final AppRepository repository;
  final UserProfile profile;
  final int refreshTick;
  final Set<String> wishlistIds;
  final int unreadNotifCount;
  final ValueChanged<String> onToggleWishlist;
  final ValueChanged<String> onSearchSubmit;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<FilterSheetResult> onFilterApplied;
  final VoidCallback onDonateNowTap;
  final VoidCallback onDataMutated;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  ListingType? _tabFilter;
  List<BookItem> _books = [];
  List<BookItem> _spotlight = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.fetchBooks(
          BookFilter(jenisListing: _tabFilter, pageSize: 12),
        ),
        if (_spotlight.isEmpty || _tabFilter == null)
          widget.repository.fetchBooks(const BookFilter(pageSize: 5)),
      ]);
      if (!mounted) return;
      setState(() {
        _books = results[0];
        if (results.length > 1) {
          _spotlight = results[1].where((b) => b.isAvailable).take(4).toList();
        }
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

  Future<void> _openFilterSheet() async {
    HapticFeedback.selectionClick();
    final result = await showBookFilterSheet(
      context: context,
      initialJenis: _tabFilter,
    );
    if (result != null) {
      widget.onFilterApplied(result);
    }
  }

  Future<void> _openDetail(BookItem book, {String heroPrefix = 'home'}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(
          repository: widget.repository,
          profile: widget.profile,
          bookId: book.id,
          initialBook: book,
          heroTag: '$heroPrefix-cover-${book.id}',
          isWishlisted: widget.wishlistIds.contains(book.id),
          onToggleWishlist: () => widget.onToggleWishlist(book.id),
          onBookChanged: widget.onDataMutated,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Row(
                children: [
                  const AppHorizontalLogo(height: 31),
                  const Spacer(),
                  _HeaderActionButton(
                    tooltip: 'Wishlist',
                    icon: Icons.favorite_border_rounded,
                    badgeCount: widget.wishlistIds.length,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WishlistScreen(
                          repository: widget.repository,
                          profile: widget.profile,
                          wishlistIds: widget.wishlistIds,
                          onToggleWishlist: widget.onToggleWishlist,
                          onDataMutated: widget.onDataMutated,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderActionButton(
                    tooltip: 'Notifikasi',
                    icon: Icons.notifications_none_rounded,
                    badgeCount: widget.unreadNotifCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(
                          repository: widget.repository,
                          profile: widget.profile,
                          wishlistIds: widget.wishlistIds,
                          onToggleWishlist: widget.onToggleWishlist,
                          onDataMutated: widget.onDataMutated,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat datang, ${widget.profile.firstName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: semantic.textMuted,
                  fontWeight: FontWeight.w400,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.65,
                  ),
                  children: [
                    const TextSpan(text: 'Temukan buku '),
                    TextSpan(
                      text: 'pilihan Anda.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: semantic.silverBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: semantic.border),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF0B2245)
                                .withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          widget.onSearchSubmit(value);
                          _searchCtrl.clear();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Cari judul buku kuliah, kamus, atau novel...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    Material(
                      color: isDark ? scheme.primary : semantic.navy,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        onTap: _openFilterSheet,
                        borderRadius: BorderRadius.circular(13),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.tune_rounded,
                            color: scheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DonationHeroBanner(
                onTap: widget.onDonateNowTap,
                semantic: semantic,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kategori Buku',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onSearchSubmit(''),
                    style: TextButton.styleFrom(
                      foregroundColor: semantic.silverBlue,
                    ),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < kBookCategories.length; i++) ...[
                    Expanded(
                      child: _CategoryTile(
                        category: kBookCategories[i],
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onCategoryTap(kBookCategories[i]);
                        },
                      ),
                    ),
                    if (i < kBookCategories.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
              if (_tabFilter == null && _spotlight.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Listing Terbaru',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${_spotlight.length} tersedia',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: semantic.silverBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _spotlight.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, idx) {
                      final book = _spotlight[idx];
                      return _SpotlightBookCard(
                        book: book,
                        onTap: () => _openDetail(book, heroPrefix: 'spot'),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rekomendasi Buku',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filter & Urutkan',
                    onPressed: _openFilterSheet,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surface,
                      side: BorderSide(color: semantic.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      color: semantic.navy,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ListingSegmentedTabs(
                selected: _tabFilter,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _tabFilter = val);
                  _load();
                },
              ),
              const SizedBox(height: 14),
              if (_loading)
                const BookGridSkeleton(itemCount: 4)
              else if (_error != null)
                ErrorRetryView(message: _error!, onRetry: _load)
              else if (_books.isEmpty)
                EmptyStateView(
                  icon: Icons.menu_book_outlined,
                  title: 'Belum ada buku tersedia',
                  subtitle:
                      'Silakan pilih kategori penawaran lain atau tambahkan buku Anda.',
                  actionLabel: 'Tampilkan Semua',
                  onAction: () {
                    setState(() => _tabFilter = null);
                    _load();
                  },
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _books.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.61,
                  ),
                  itemBuilder: (_, index) {
                    final book = _books[index];
                    return BookCard(
                      book: book,
                      heroPrefix: 'home',
                      isWishlisted: widget.wishlistIds.contains(book.id),
                      onTap: () => _openDetail(book, heroPrefix: 'home'),
                      onToggleWishlist: () => widget.onToggleWishlist(book.id),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightBookCard extends StatelessWidget {
  const _SpotlightBookCard({required this.book, required this.onTap});

  final BookItem book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0B2245).withValues(alpha: 0.05),
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
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'spot-cover-${book.id}',
                      child: BookCoverImage(
                        fotoUrl: book.fotoUrl,
                        title: book.judul,
                        category: book.kategori,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: book.isDonation
                              ? semantic.donationContainer
                              : semantic.silverFrost,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.isDonation ? 'Donasi' : book.kondisi,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: book.isDonation
                                ? semantic.donation
                                : semantic.silverBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            book.isDonation
                                ? 'Gratis'
                                : formatRupiah(book.harga),
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
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
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: semantic.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        side: BorderSide(color: semantic.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(46, 46),
      ),
      icon: Badge(
        isLabelVisible: badgeCount > 0,
        backgroundColor: semantic.silverBlue,
        label: Text('$badgeCount'),
        child: Icon(icon, color: semantic.navy, size: 22),
      ),
    );
  }
}

class _DonationHeroBanner extends StatelessWidget {
  const _DonationHeroBanner({
    required this.onTap,
    required this.semantic,
  });

  final VoidCallback onTap;
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [semantic.navyDeep, semantic.navy, semantic.navyMid],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: semantic.silverGlow.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07162E).withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft moonlight silver-blue radial aura behind stacked books
          Positioned(
            right: -24,
            top: -28,
            child: IgnorePointer(
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8AB8E8).withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 3D layered tilted book spines
          Positioned(
            right: -12,
            bottom: -18,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.17,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _HeroBookSpine(
                      width: 34,
                      height: 92,
                      color: const Color(0xFFE8F1FB),
                      bandColor: const Color(0xFF9AC3EE),
                    ),
                    const SizedBox(width: 6),
                    _HeroBookSpine(
                      width: 38,
                      height: 114,
                      color: const Color(0xFF8AB8E8),
                      bandColor: Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 6),
                    _HeroBookSpine(
                      width: 34,
                      height: 82,
                      color: const Color(0xFFF3B85A),
                      bandColor: Colors.white.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 120, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satu buku, sejuta cerita.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Donasikan buku kuliah layak pakai Anda untuk sivitas akademika ITS.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD2E4F8),
                    fontWeight: FontWeight.w400,
                    height: 1.44,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B2245),
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Mulai Donasi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBookSpine extends StatelessWidget {
  const _HeroBookSpine({
    required this.width,
    required this.height,
    required this.color,
    required this.bandColor,
  });

  final double width;
  final double height;
  final Color color;
  final Color bandColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(height: 4, color: bandColor),
          const SizedBox(height: 4),
          Container(height: 2, color: bandColor.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _styleFor(category, isDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.bg, style.bgEnd],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: style.fg.withValues(alpha: isDark ? 0.28 : 0.16),
                ),
              ),
              child: Icon(style.icon, color: style.fg, size: 25),
            ),
            const SizedBox(height: 7),
            Text(
              category == 'Buku Kuliah' ? 'Buku' : category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: semantic.navy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color bg, Color bgEnd, Color fg}) _styleFor(
    String cat,
    bool isDark,
  ) {
    switch (cat) {
      case 'Buku Kuliah':
        return (
          icon: Icons.school_outlined,
          bg: isDark ? const Color(0xFF183158) : const Color(0xFFEAF2FC),
          bgEnd: isDark ? const Color(0xFF112340) : const Color(0xFFDCEAF9),
          fg: isDark ? const Color(0xFF8AB8E8) : const Color(0xFF0B2245),
        );
      case 'Kamus':
        return (
          icon: Icons.translate_rounded,
          bg: isDark ? const Color(0xFF332815) : const Color(0xFFFEF6E4),
          bgEnd: isDark ? const Color(0xFF241C0E) : const Color(0xFFFCEBC7),
          fg: isDark ? const Color(0xFFF5C469) : const Color(0xFFB4690E),
        );
      case 'Novel':
        return (
          icon: Icons.auto_stories_outlined,
          bg: isDark ? const Color(0xFF291F3D) : const Color(0xFFF4EFFD),
          bgEnd: isDark ? const Color(0xFF1D162C) : const Color(0xFFE8DFFA),
          fg: isDark ? const Color(0xFFC4A7F2) : const Color(0xFF6B3FA0),
        );
      default:
        return (
          icon: Icons.collections_bookmark_outlined,
          bg: isDark ? const Color(0xFF3A1E28) : const Color(0xFFFDEEF2),
          bgEnd: isDark ? const Color(0xFF28141B) : const Color(0xFFFADCE4),
          fg: isDark ? const Color(0xFFF29CB3) : const Color(0xFFBE3455),
        );
    }
  }
}

class _ListingSegmentedTabs extends StatelessWidget {
  const _ListingSegmentedTabs({
    required this.selected,
    required this.onChanged,
  });

  final ListingType? selected;
  final ValueChanged<ListingType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = <(ListingType?, String)>[
      (null, 'Semua'),
      (ListingType.jual, 'Dijual'),
      (ListingType.donasi, 'Donasi'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: semantic.subtleSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected == item.$1
                        ? scheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected == item.$1
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0B2245)
                                  .withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      fontWeight: selected == item.$1
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected == item.$1
                          ? scheme.primary
                          : semantic.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
