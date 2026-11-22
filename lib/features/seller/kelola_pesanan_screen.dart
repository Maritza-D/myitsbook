import 'package:flutter/material.dart';
import 'package:myitsbook/data/repository.dart';

class KelolaPesananScreen extends StatefulWidget {
  const KelolaPesananScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<KelolaPesananScreen> createState() =>
      _KelolaPesananScreenState();
}

class _KelolaPesananScreenState extends State<KelolaPesananScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  final Set<String> _updatingOrders = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = widget.repository.fetchSellerTransactions();
  }

  Future<void> _refreshOrders() async {
    setState(_loadOrders);
    await _ordersFuture;
  }

  String _formatPrice(dynamic price) {
    final value = double.tryParse(price.toString()) ?? 0;
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';

    final parsedDate = DateTime.tryParse(date.toString());
    if (parsedDate == null) return '-';

    final localDate = parsedDate.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'dalam_proses':
        return 'Dalam Proses';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      case 'dalam_proses':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(
    Map<String, dynamic> order,
    String status,
  ) async {
    final orderId = order['id']?.toString();

    if (orderId == null || orderId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: Text(
          'Apakah kamu yakin ingin mengubah status pesanan menjadi '
          '"${_statusLabel(status)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _updatingOrders.add(orderId);
    });

    try {
      await widget.repository.updateSellerTransactionStatus(
        orderId,
        status,
      );

      if (!mounted) return;

      setState(() {
        _loadOrders();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status pesanan berhasil diperbarui.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui pesanan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrders.remove(orderId);
        });
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final bookData = order['books'];

    final book = bookData is Map
        ? Map<String, dynamic>.from(bookData)
        : <String, dynamic>{};

    final title = book['judul']?.toString() ?? 'Buku tidak diketahui';
    final price = order['price'];
    final date = order['created_at'];
    final orderId = order['id']?.toString() ?? '';
    final isUpdating = _updatingOrders.contains(orderId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pesanan Masuk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Divider(height: 24),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'ID Pesanan: $orderId',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            if (status == 'dalam_proses') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isUpdating
                          ? null
                          : () => _updateStatus(
                                order,
                                'dibatalkan',
                              ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Batalkan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isUpdating
                          ? null
                          : () => _updateStatus(
                                order,
                                'selesai',
                              ),
                      child: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Selesaikan'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat pesanan.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(_loadOrders);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshOrders,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Belum ada pesanan masuk.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Daftar Pesanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau dan kelola pesanan dari pembeli.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                ...orders.map(_buildOrderCard),
              ],
            ),
          );
        },
      ),
    );
  }
}
