import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_form_screen.dart';
import 'package:myitsbook/features/catalog/catalog_screen.dart';
import 'package:myitsbook/features/chat/conversations_screen.dart';
import 'package:myitsbook/features/home/home_screen.dart';
import 'package:myitsbook/features/profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.profile,
    required this.onProfileUpdated,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final AppRepository repository;
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileUpdated;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _refreshTick = 0;
  String? _catalogInitialQuery;
  String? _catalogInitialCategory;
  FilterSheetResult? _catalogInitialFilter;
  Set<String> _wishlistIds = {};
  int _unreadChatCount = 0;
  int _unreadNotifCount = 0;
  StreamSubscription<List<ConversationSummary>>? _convSub;
  StreamSubscription<List<AppNotification>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
    _convSub = widget.repository.watchConversations().listen((items) {
      if (!mounted) return;
      final total = items.fold<int>(0, (acc, c) => acc + c.unreadCount);
      setState(() => _unreadChatCount = total);
    });
    _notifSub = widget.repository.watchNotifications().listen((items) {
      if (!mounted) return;
      final total = items.where((n) => !n.isRead).length;
      setState(() => _unreadNotifCount = total);
    });
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadWishlist() async {
    try {
      final ids = await widget.repository.fetchWishlistIds();
      if (mounted) setState(() => _wishlistIds = ids);
    } catch (_) {}
  }

  Future<void> _toggleWishlist(String bookId) async {
    final wasSaved = _wishlistIds.contains(bookId);
    setState(() {
      if (wasSaved) {
        _wishlistIds.remove(bookId);
      } else {
        _wishlistIds.add(bookId);
      }
    });
    try {
      await widget.repository.toggleWishlist(bookId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _wishlistIds.add(bookId);
        } else {
          _wishlistIds.remove(bookId);
        }
      });
    }
  }

  void _openCatalog({
    String? query,
    String? category,
    FilterSheetResult? filter,
  }) {
    setState(() {
      _catalogInitialQuery = query;
      _catalogInitialCategory = category;
      _catalogInitialFilter = filter;
      _index = 1;
    });
  }

  Future<void> _openBookForm(ListingType type) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookFormScreen(
          repository: widget.repository,
          profile: widget.profile,
          initialType: type,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() => _refreshTick++);
    }
  }

  Future<void> _showPublishChooser() async {
    HapticFeedback.selectionClick();
    final chosen = await showAppBottomSheet<ListingType>(
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
                'Tambahkan Buku ke Katalog',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih jenis penawaran untuk buku yang akan Anda publikasikan.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: semantic.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              _PublishOptionCard(
                icon: Icons.sell_outlined,
                iconBg: semantic.silverFrost,
                iconColor: semantic.navy,
                title: 'Jual Buku',
                subtitle: 'Tentukan harga penawaran bagi sesama mahasiswa ITS',
                borderColor: semantic.border,
                surfaceColor: scheme.surface,
                onTap: () => Navigator.of(ctx).pop(ListingType.jual),
              ),
              const SizedBox(height: 12),
              _PublishOptionCard(
                icon: Icons.volunteer_activism_rounded,
                iconBg: semantic.donationContainer,
                iconColor: semantic.donation,
                title: 'Donasi Buku (Gratis)',
                subtitle: 'Bagikan buku secara gratis untuk sivitas akademika ITS',
                borderColor: semantic.border,
                surfaceColor: scheme.surface,
                onTap: () => Navigator.of(ctx).pop(ListingType.donasi),
              ),
            ],
          ),
        );
      },
    );
    if (chosen != null) {
      await _openBookForm(chosen);
    }
  }

  Widget _buildActiveScreen() {
    switch (_index) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('tab-home'),
          child: HomeScreen(
            repository: widget.repository,
            profile: widget.profile,
            refreshTick: _refreshTick,
            wishlistIds: _wishlistIds,
            unreadNotifCount: _unreadNotifCount,
            onToggleWishlist: _toggleWishlist,
            onSearchSubmit: (q) => _openCatalog(query: q),
            onCategoryTap: (cat) => _openCatalog(category: cat),
            onFilterApplied: (f) => _openCatalog(filter: f),
            onDonateNowTap: () => _openBookForm(ListingType.donasi),
            onDataMutated: () => setState(() => _refreshTick++),
          ),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('tab-catalog'),
          child: CatalogScreen(
            repository: widget.repository,
            profile: widget.profile,
            refreshTick: _refreshTick,
            initialQuery: _catalogInitialQuery,
            initialCategory: _catalogInitialCategory,
            initialFilter: _catalogInitialFilter,
            wishlistIds: _wishlistIds,
            onToggleWishlist: _toggleWishlist,
            onDataMutated: () => setState(() => _refreshTick++),
          ),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('tab-chat'),
          child: ConversationsScreen(
            repository: widget.repository,
            profile: widget.profile,
            onDataMutated: () => setState(() => _refreshTick++),
          ),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('tab-profile'),
          child: ProfileScreen(
            repository: widget.repository,
            profile: widget.profile,
            wishlistIds: _wishlistIds,
            onToggleWishlist: _toggleWishlist,
            onProfileUpdated: widget.onProfileUpdated,
            onLogout: widget.onLogout,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            onDataMutated: () => setState(() => _refreshTick++),
          ),
        );
    }
  }

  int get _navBarSelectedIndex {
    if (_index <= 1) return _index;
    return _index + 1;
  }

  void _onNavSelected(int navPos) {
    if (navPos == 2) {
      _showPublishChooser();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (navPos < 2) {
        _index = navPos;
      } else {
        _index = navPos - 1;
      }
      if (_index != 1) {
        _catalogInitialQuery = null;
        _catalogInitialCategory = null;
        _catalogInitialFilter = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    final bodyContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _buildActiveScreen(),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _navBarSelectedIndex,
              onDestinationSelected: _onNavSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Beranda'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: Text('Kategori'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.add_box_outlined),
                  selectedIcon: Icon(Icons.add_box_rounded),
                  label: Text('Tambah'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: _unreadChatCount > 0,
                    label: Text('$_unreadChatCount'),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _unreadChatCount > 0,
                    label: Text('$_unreadChatCount'),
                    child: const Icon(Icons.chat_bubble_rounded),
                  ),
                  label: const Text('Pesan'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profil'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      body: bodyContent,
      bottomNavigationBar: _FloatingMidnightDock(
        selectedIndex: _navBarSelectedIndex,
        unreadChatCount: _unreadChatCount,
        onSelected: _onNavSelected,
      ),
    );
  }
}

class _FloatingMidnightDock extends StatelessWidget {
  const _FloatingMidnightDock({
    required this.selectedIndex,
    required this.unreadChatCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int unreadChatCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? 0.96 : 0.98),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? semantic.silverBlue.withValues(alpha: 0.22)
                  : semantic.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07162E).withValues(
                  alpha: isDark ? 0.45 : 0.10,
                ),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _DockTabItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Beranda',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _DockTabItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                label: 'Kategori',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(2),
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [scheme.primary, semantic.silverBlue]
                                : [semantic.navyMid, semantic.navyDeep],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: semantic.silverGlow.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? scheme.primary : semantic.navy)
                                  .withValues(alpha: 0.34),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: scheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _DockTabItem(
                icon: Icons.chat_bubble_outline_rounded,
                selectedIcon: Icons.chat_bubble_rounded,
                label: 'Pesan',
                badgeCount: unreadChatCount,
                selected: selectedIndex == 3,
                onTap: () => onSelected(3),
              ),
              _DockTabItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profil',
                selected: selectedIndex == 4,
                onTap: () => onSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockTabItem extends StatelessWidget {
  const _DockTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : semantic.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: selected ? semantic.silverFrost : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Badge(
                  isLabelVisible: badgeCount > 0,
                  backgroundColor: semantic.silverBlue,
                  label: Text('$badgeCount'),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: color,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 2.5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishOptionCard extends StatelessWidget {
  const _PublishOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.surfaceColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color surfaceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Material(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
