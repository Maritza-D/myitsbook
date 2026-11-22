
import 'package:flutter/material.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<HistoryItem> _items = [];

  bool _loading = true;
  String? _error;
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ==========================================================
  // PART 1 — LOAD DATA DARI SUPABASE
  // ==========================================================

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.repository.fetchHistory();

      if (!mounted) return;

      setState(() {
        _items = data;
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

  // ==========================================================
  // PART 2 — FILTER DATA
  // ==========================================================

  List<HistoryItem> get _filteredItems {
    if (_filter == 'Transaksi') {
      return _items
          .where((item) =>
              item.type == HistoryType.transaction)
          .toList();
    }

    if (_filter == 'Donasi') {
      return _items
          .where((item) =>
              item.type == HistoryType.donation)
          .toList();
    }

    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // PART 3 — HEADER
          // ==================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivitas Kamu',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pantau riwayat transaksi dan donasi bukumu.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: semantic.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // PART 4 — FILTER
          // ==================================================

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Semua', 'Transaksi', 'Donasi']
                  .map((filter) {
                final selected = _filter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _filter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ==================================================
          // PART 5 — DATA RIWAYAT
          // ==================================================

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _loadHistory,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? _emptyState(theme)
                        : RefreshIndicator(
                            onRefresh: _loadHistory,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20, 0, 20, 24,
                              ),
                              itemCount: _filteredItems.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _historyCard(
                                  _filteredItems[index],
                                  theme,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PART 6 — HISTORY CARD
  // ==========================================================

  Widget _historyCard(
    HistoryItem item,
    ThemeData theme,
  ) {
    final isDonation =
        item.type == HistoryType.donation;

    final color = isDonation
        ? const Color(0xFF15803D)
        : const Color(0xFF4F83BE);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDonation
                      ? Icons.volunteer_activism_rounded
                      : Icons.receipt_long_rounded,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  isDonation ? 'DONASI BUKU' : 'TRANSAKSI',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _statusBadge(item.status, theme),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 65,
                    height: 82,
                    color: color.withValues(alpha: 0.10),
                    child: item.coverUrl.isNotEmpty
                        ? Image.network(
                            item.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Icon(Icons.menu_book, color: color),
                          )
                        : Icon(
                            Icons.menu_book_rounded,
                            color: color,
                            size: 30,
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bookTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.category,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDonation
                            ? 'Gratis'
                            : _rupiah(item.price),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.role}: ${item.otherUserName}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16),
                const SizedBox(width: 8),
                Text(
                  _date(item.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PART 7 — STATUS
  // ==========================================================

  Widget _statusBadge(
    String status,
    ThemeData theme,
  ) {
    final color = switch (status) {
      'selesai' => const Color(0xFF15803D),
      'dalam_proses' => const Color(0xFFD97706),
      'dibatalkan' => const Color(0xFFDC2626),
      _ => theme.colorScheme.onSurfaceVariant,
    };

    final label = switch (status) {
      'selesai' => 'Selesai',
      'dalam_proses' => 'Dalam Proses',
      'dibatalkan' => 'Dibatalkan',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================================
  // PART 8 — EMPTY STATE
  // ==========================================================

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 65,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Belum Ada Riwayat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aktivitasmu akan muncul di sini.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PART 9 — FORMAT DATA
  // ==========================================================

  String _rupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  String _date(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret',
      'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September',
      'Oktober', 'November', 'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
