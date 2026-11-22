import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.conversation,
    this.initialDraft,
    this.onBookStatusUpdated,
  });

  final AppRepository repository;
  final UserProfile profile;
  final ConversationSummary conversation;
  final String? initialDraft;
  final VoidCallback? onBookStatusUpdated;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late BookStatus _bookStatus;
  bool _sending = false;

  bool get _isSeller => widget.conversation.sellerId == widget.profile.id;

  @override
  void initState() {
    super.initState();
    _bookStatus = widget.conversation.bookStatus;
    if (widget.initialDraft != null && widget.initialDraft!.isNotEmpty) {
      _msgCtrl.text = widget.initialDraft!;
    }
    widget.repository.markConversationRead(widget.conversation.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await widget.repository.sendMessage(widget.conversation.id, text);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _msgCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickBookStatus() async {
    final isDonasi = widget.conversation.bookJenis == ListingType.donasi;
    final options = [
      BookStatus.tersedia,
      BookStatus.dalamProses,
      isDonasi ? BookStatus.selesai : BookStatus.terjual,
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
                widget.conversation.bookTitle,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final s in options) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: s == _bookStatus
                          ? scheme.primary
                          : semantic.border,
                      width: s == _bookStatus ? 1.5 : 1,
                    ),
                  ),
                  tileColor: s == _bookStatus
                      ? semantic.silverFrost
                      : scheme.surface,
                  title: Text(
                    s.label,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  trailing: s == _bookStatus
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
    if (chosen == null || chosen == _bookStatus) return;
    try {
      await widget.repository.updateBookStatus(
        widget.conversation.bookId,
        chosen,
      );
      if (!mounted) return;
      setState(() => _bookStatus = chosen);
      widget.onBookStatusUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status buku diubah ke ${chosen.label}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    }
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  List<String> get _quickReplies => _isSeller
      ? const [
          'Halo, buku ini masih tersedia.',
          'Serah terima dapat dilakukan di Perpustakaan ITS.',
          'Baik, penawaran disepakati.',
        ]
      : const [
          'Halo, apakah buku ini masih tersedia?',
          'Apakah serah terima dapat dilakukan di kampus ITS?',
          'Baik, saya berminat dengan buku ini.',
        ];

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conv = widget.conversation;
    final isDonasi = conv.bookJenis == ListingType.donasi;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: semantic.silverFrost,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                conv.otherUserName.isNotEmpty
                    ? conv.otherUserName[0].toUpperCase()
                    : 'M',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: semantic.navy,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: semantic.donation,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isSeller ? 'Pembeli · ITS' : 'Penjual · ITS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: semantic.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isSeller)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Ubah Status Buku',
                onPressed: _pickBookStatus,
                style: IconButton.styleFrom(
                  backgroundColor: semantic.silverFrost,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.sync_alt_rounded, color: semantic.navy),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: semantic.border),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF0B2245)
                              .withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 58,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BookCoverImage(
                        fotoUrl: conv.bookFotoUrl,
                        title: conv.bookTitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buku Terkait',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: semantic.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conv.bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              isDonasi ? 'Gratis' : formatRupiah(conv.bookHarga),
                              style: TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: isDonasi
                                    ? semantic.donation
                                    : scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '· ${_bookStatus.label}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: semantic.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isSeller)
                    TextButton(
                      onPressed: _pickBookStatus,
                      child: const Text('Status'),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.repository.watchMessages(conv.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.any(
                  (m) => m.senderId != widget.profile.id && !m.isRead,
                )) {
                  widget.repository.markConversationRead(conv.id);
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kirim pesan untuk menanyakan kondisi buku atau menyepakati lokasi serah terima di kampus ITS.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: semantic.textMuted,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  itemCount: messages.length + 1,
                  itemBuilder: (_, idx) {
                    if (idx == 0) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.subtleSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Hari ini',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: semantic.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      );
                    }
                    final msg = messages[idx - 1];
                    final isMine = msg.senderId == widget.profile.id;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                        ),
                        decoration: BoxDecoration(
                          gradient: isMine
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [semantic.navyMid, semantic.navyDeep]
                                      : [semantic.navyMid, semantic.navy],
                                )
                              : null,
                          color: isMine ? null : scheme.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMine ? 18 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 18),
                          ),
                          border: isMine
                              ? null
                              : Border.all(color: semantic.border),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF0B2245)
                                        .withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg.isi,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isMine
                                        ? Colors.white
                                        : scheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatClock(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isMine
                                        ? const Color(0xFFBFD7F2)
                                        : semantic.textMuted,
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.isRead
                                        ? Icons.done_all_rounded
                                        : Icons.check_rounded,
                                    size: 13,
                                    color: const Color(0xFFBFD7F2),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: semantic.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, idx) {
                        final reply = _quickReplies[idx];
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          label: Text(
                            reply,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _msgCtrl.text = reply;
                            _msgCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: reply.length),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan Anda...',
                            fillColor: semantic.subtleSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _sending ? null : _send,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
