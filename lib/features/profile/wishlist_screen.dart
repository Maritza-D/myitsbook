import 'package:flutter/material.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
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
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<BookItem> _items = [];
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
      final fetched = await widget.repository.fetchWishlistBooks();
      if (!mounted) return;
      setState(() {
        _items = fetched;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist Saya')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: BookGridSkeleton(itemCount: 4),
            )
          : _error != null
          ? ErrorRetryView(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? const EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'Wishlist masih kosong',
              subtitle:
                  'Ketuk ikon hati pada kartu atau halaman detail buku untuk menyimpannya di sini.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.61,
                ),
                itemBuilder: (_, idx) {
                  final book = _items[idx];
                  return BookCard(
                    book: book,
                    heroPrefix: 'wish',
                    isWishlisted: true,
                    onToggleWishlist: () {
                      widget.onToggleWishlist(book.id);
                      setState(() => _items.removeWhere((b) => b.id == book.id));
                    },
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => BookDetailScreen(
                            repository: widget.repository,
                            profile: widget.profile,
                            bookId: book.id,
                            initialBook: book,
                            heroTag: 'wish-cover-${book.id}',
                            isWishlisted: widget.wishlistIds.contains(book.id),
                            onToggleWishlist: () => widget.onToggleWishlist(book.id),
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
    );
  }
}
