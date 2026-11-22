import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/chat/chat_room_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.onDataMutated,
  });

  final AppRepository repository;
  final UserProfile profile;
  final VoidCallback onDataMutated;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchCtrl = TextEditingController();
  bool _unreadOnly = false;
  _ChatRole _role = _ChatRole.semua;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<ConversationSummary>>(
          stream: widget.repository.watchConversations(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final unreadConvCount = all.where((c) => c.unreadCount > 0).length;
            final q = _searchCtrl.text.trim().toLowerCase();
            final filtered = all.where((c) {
              if (_unreadOnly && c.unreadCount == 0) return false;
              if (_role == _ChatRole.membeli &&
                  c.buyerId != widget.profile.id) {
                return false;
              }
              if (_role == _ChatRole.menjual &&
                  c.sellerId != widget.profile.id) {
                return false;
              }
              if (q.isNotEmpty) {
                final matchName = c.otherUserName.toLowerCase().contains(q);
                final matchBook = c.bookTitle.toLowerCase().contains(q);
                if (!matchName && !matchBook) return false;
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              'Pesan',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: _showSearch
                                ? 'Tutup pencarian'
                                : 'Cari percakapan',
                            onPressed: () {
                              setState(() {
                                _showSearch = !_showSearch;
                                if (!_showSearch) _searchCtrl.clear();
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: semantic.silverFrost,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size(46, 46),
                            ),
                            icon: Icon(
                              _showSearch
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              color: semantic.navy,
                            ),
                          ),
                        ],
                      ),
                      if (_showSearch) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Cari nama kontak atau judul buku...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _UnderlineCountTab(
                            label: 'Semua',
                            count: all.length,
                            selected: !_unreadOnly,
                            onTap: () => setState(() => _unreadOnly = false),
                          ),
                          const SizedBox(width: 22),
                          _UnderlineCountTab(
                            label: 'Belum Dibaca',
                            count: unreadConvCount,
                            selected: _unreadOnly,
                            onTap: () => setState(() => _unreadOnly = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final r in _ChatRole.values)
                            ChoiceChip(
                              label: Text(
                                r.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _role == r,
                              onSelected: (_) => setState(() => _role = r),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: semantic.border),
                Expanded(
                  child:
                      snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError
                      ? ErrorRetryView(
                          message: '${snapshot.error}',
                          onRetry: () => setState(() {}),
                        )
                      : filtered.isEmpty
                      ? EmptyStateView(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: _unreadOnly
                              ? 'Tidak ada pesan belum dibaca'
                              : 'Belum ada percakapan',
                          subtitle: 'Buka halaman detail buku untuk mulai menghubungi penjual atau donatur.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 84,
                            endIndent: 18,
                            color: semantic.border,
                          ),
                          itemBuilder: (_, idx) {
                            final conv = filtered[idx];
                            final hasUnread = conv.unreadCount > 0;
                            return InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                    repository: widget.repository,
                                    profile: widget.profile,
                                    conversation: conv,
                                    onBookStatusUpdated: widget.onDataMutated,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        SizedBox(
                                          width: 54,
                                          height: 54,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: BookCoverImage(
                                              fotoUrl: conv.bookFotoUrl,
                                              title: conv.bookTitle,
                                            ),
                                          ),
                                        ),
                                        if (hasUnread)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 13,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                color: semantic.donation,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: scheme.surface,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  conv.otherUserName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight: hasUnread
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                formatRelativeTime(
                                                  conv.updatedAt,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: semantic.textMuted,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${conv.sellerId == widget.profile.id ? 'Menjual' : 'Membeli'} · ${conv.bookTitle}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: semantic.silverBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  conv.lastMessage.isEmpty
                                                      ? 'Belum ada pesan pada percakapan ini'
                                                      : conv.lastMessage,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight: hasUnread
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                        color: hasUnread
                                                            ? scheme.onSurface
                                                            : semantic
                                                                  .textMuted,
                                                      ),
                                                ),
                                              ),
                                              if (hasUnread) ...[
                                                const SizedBox(width: 10),
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 22,
                                                        minHeight: 22,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: semantic.silverBlue,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${conv.unreadCount}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _ChatRole {
  semua('Semua'),
  membeli('Sebagai Pembeli'),
  menjual('Sebagai Penjual');

  const _ChatRole(this.label);
  final String label;
}

class _UnderlineCountTab extends StatelessWidget {
  const _UnderlineCountTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? scheme.primary : semantic.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? semantic.silverFrost
                        : semantic.subtleSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.primary : semantic.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2.5,
            width: selected ? 68 : 0,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
