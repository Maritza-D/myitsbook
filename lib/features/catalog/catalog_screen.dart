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

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.refreshTick,
    required this.wishlistIds,
    required this.onToggleWishlist,
    required this.onDataMutated,
    this.initialQuery,
    this.initialCategory,
    this.initialFilter,
  });

  final AppRepository repository;
  final UserProfile profile;
  final int refreshTick;
  final Set<String> wishlistIds;
  final ValueChanged<String> onToggleWishlist;
  final VoidCallback onDataMutated;
  final String? initialQuery;
  final String? initialCategory;
  final FilterSheetResult? initialFilter;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const int _pageSize = 12;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _category;
  ListingType? _jenis;
  String? _kondisi;
  int? _minPrice;
  int? _maxPrice;
  String? _lokasi;
  BookSort _sort = BookSort.terbaru;
  final List<BookItem> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery ?? '';
    _category = widget.initialCategory;
    if (widget.initialFilter != null) {
      _applyFilterResult(widget.initialFilter!, reloadNow: false);
    }
    _scrollCtrl.addListener(_onScroll);
    _reload();
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldReload = false;
    if (widget.initialQuery != null &&
        widget.initialQuery != oldWidget.initialQuery) {
      _searchCtrl.text = widget.initialQuery!;
      shouldReload = true;
    }
    if (widget.initialCategory != null &&
        widget.initialCategory != oldWidget.initialCategory) {
      _category = widget.initialCategory;
      shouldReload = true;
    }
    if (widget.initialFilter != null &&
        widget.initialFilter != oldWidget.initialFilter) {
      _applyFilterResult(widget.initialFilter!, reloadNow: false);
      shouldReload = true;
    }
    if (oldWidget.refreshTick != widget.refreshTick) {
      shouldReload = true;
    }
    if (shouldReload) {
      _reload();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _applyFilterResult(FilterSheetResult f, {bool reloadNow = true}) {
    setState(() {
      _jenis = f.jenis;
      _kondisi = f.kondisi;
      _minPrice = f.minPrice;
      _maxPrice = f.maxPrice;
      _lokasi = f.lokasi;
      _sort = f.sort;
    });
    if (reloadNow) _reload();
  }

  Future<void> _openFilterSheet() async {
    final result = await showBookFilterSheet(
      context: context,
      initialJenis: _jenis,
      initialKondisi: _kondisi,
      initialMinPrice: _minPrice,
      initialMaxPrice: _maxPrice,
      initialLokasi: _lokasi,
      initialSort: _sort,
    );
    if (result != null) {
      _applyFilterResult(result);
    }
  }

  void _onScroll() {
    if (_loading || _loadingMore || !_hasMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  BookFilter _buildFilter(int page) => BookFilter(
    query: _searchCtrl.text,
    category: _category,
    jenisListing: _jenis,
    kondisi: _kondisi,
    minPrice: _minPrice,
    maxPrice: _maxPrice,
    lokasi: _lokasi,
    sort: _sort,
    page: page,
    pageSize: _pageSize,
  );

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
    });
    try {
      final fetched = await widget.repository.fetchBooks(_buildFilter(0));
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(fetched);
        _hasMore = fetched.length == _pageSize;
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final fetched = await widget.repository.fetchBooks(_buildFilter(nextPage));
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _items.addAll(fetched);
        _hasMore = fetched.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _category = null;
      _jenis = null;
      _kondisi = null;
      _minPrice = null;
      _maxPrice = null;
      _lokasi = null;
      _sort = BookSort.terbaru;
    });
    _reload();
  }

  int get _activeFilterCount {
    var count = 0;
    if (_jenis != null) count++;
    if (_kondisi != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_lokasi != null && _lokasi!.isNotEmpty) count++;
    if (_sort != BookSort.terbaru) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Katalog Buku',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Filter & Urutkan',
                        onPressed: _openFilterSheet,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surface,
                          side: BorderSide(color: semantic.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(46, 46),
                        ),
                        icon: Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          backgroundColor: semantic.silverBlue,
                          label: Text('$_activeFilterCount'),
                          child: Icon(Icons.tune_rounded, color: semantic.navy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _reload(),
                    decoration: InputDecoration(
                      hintText: 'Cari judul buku di seluruh katalog...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Bersihkan pencarian',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _reload();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryPill(
                          label: 'Semua',
                          selected: _category == null,
                          onTap: () {
                            setState(() => _category = null);
                            _reload();
                          },
                        ),
                        const SizedBox(width: 8),
                        for (final cat in kBookCategories) ...[
                          _CategoryPill(
                            label: cat == 'Buku Kuliah' ? 'Buku' : cat,
                            selected: _category == cat,
                            onTap: () {
                              setState(
                                () => _category = _category == cat ? null : cat,
                              );
                              _reload();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${_items.length} buku ditemukan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: semantic.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _openFilterSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _sort.label,
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: BookGridSkeleton(itemCount: 4),
                    )
                  : _error != null
                  ? ErrorRetryView(message: _error!, onRetry: _reload)
                  : _items.isEmpty
                  ? EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'Buku tidak ditemukan',
                      subtitle:
                          'Tidak ada buku yang cocok dengan kata kunci atau filter yang dipilih.',
                      actionLabel: 'Reset Filter',
                      onAction: _resetFilters,
                    )
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: GridView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: _items.length + (_loadingMore ? 2 : 0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.61,
                            ),
                        itemBuilder: (_, idx) {
                          if (idx >= _items.length) {
                            return Card(
                              child: Container(color: semantic.subtleSurface),
                            );
                          }
                          final book = _items[idx];
                          return BookCard(
                            book: book,
                            heroPrefix: 'catalog',
                            isWishlisted: widget.wishlistIds.contains(book.id),
                            onToggleWishlist: () =>
                                widget.onToggleWishlist(book.id),
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => BookDetailScreen(
                                    repository: widget.repository,
                                    profile: widget.profile,
                                    bookId: book.id,
                                    initialBook: book,
                                    heroTag: 'catalog-cover-${book.id}',
                                    isWishlisted: widget.wishlistIds.contains(
                                      book.id,
                                    ),
                                    onToggleWishlist: () =>
                                        widget.onToggleWishlist(book.id),
                                    onBookChanged: widget.onDataMutated,
                                  ),
                                ),
                              );
                              _reload();
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
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
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
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
