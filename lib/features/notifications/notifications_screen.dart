import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/state_views.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_detail_screen.dart';
import 'package:myitsbook/features/chat/chat_room_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
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

  Future<void> _handleTap(BuildContext context, AppNotification notif) async {
    if (!notif.isRead) {
      await repository.markNotificationRead(notif.id);
    }
    if (notif.refId == null || !context.mounted) return;
    if (notif.tipe == 'status_buku') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(
            repository: repository,
            profile: profile,
            bookId: notif.refId!,
            isWishlisted: wishlistIds.contains(notif.refId!),
            onToggleWishlist: () => onToggleWishlist(notif.refId!),
            onBookChanged: onDataMutated,
          ),
        ),
      );
      return;
    }
    if (notif.tipe == 'pesan') {
      final list = await repository.watchConversations().first;
      final match = list.where((c) => c.id == notif.refId).toList();
      if (match.isNotEmpty && context.mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              repository: repository,
              profile: profile,
              conversation: match.first,
              onBookStatusUpdated: onDataMutated,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () => repository.markAllNotificationsRead(),
            style: TextButton.styleFrom(foregroundColor: semantic.silverBlue),
            child: const Text('Tandai Dibaca'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: repository.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: 'Belum ada notifikasi',
              subtitle:
                  'Pesan masuk dan pembaruan status buku yang Anda ikuti akan tampil di sini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final notif = items[idx];
              final isMsg = notif.tipe == 'pesan';
              return Material(
                color: notif.isRead
                    ? Theme.of(context).colorScheme.surface
                    : semantic.silverFrost,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: semantic.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _handleTap(context, notif),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isMsg
                                ? semantic.silverFrost
                                : semantic.donationContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isMsg
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.sync_alt_rounded,
                            color: isMsg ? semantic.navy : semantic.donation,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.judul,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: notif.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatRelativeTime(notif.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: semantic.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.isi,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
