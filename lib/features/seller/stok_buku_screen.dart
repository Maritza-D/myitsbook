import 'package:flutter/material.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';

class StokBukuScreen extends StatefulWidget {
  const StokBukuScreen({
    super.key,
    required this.repository,
    required this.onDataMutated,
  });

  final AppRepository repository;
  final VoidCallback onDataMutated;

  @override
  State<StokBukuScreen> createState() => _StokBukuScreenState();
}

class _StokBukuScreenState extends State<StokBukuScreen> {
  late Future<List<BookItem>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    _booksFuture = widget.repository.fetchMyBooks();
  }

  Future<void> _refreshBooks() async {
    setState(() {
      _loadBooks();
    });

    await _booksFuture;
  }

  Future<void> _editStock(BookItem book) async {
    final controller = TextEditingController(
      text: book.stok.toString(),
    );

    final newStock = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Stok Buku'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.judul),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok',
                  hintText: 'Masukkan jumlah stok',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);

                if (value == null || value < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Masukkan jumlah stok berupa angka 0 atau lebih.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newStock == null) return;

    try {
      await widget.repository.updateBookStock(book.id, newStock);

      if (!mounted) return;

      setState(() {
        _loadBooks();
      });

      widget.onDataMutated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok buku berhasil diperbarui.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui stok: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Stok Buku',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<BookItem>>(
        future: _booksFuture,
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
                      'Gagal memuat daftar buku.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(_loadBooks);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada buku yang kamu jual.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshBooks,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Daftar Buku Saya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Atur jumlah stok buku yang tersedia untuk dijual.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                ...books.map((book) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.grey,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.judul,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stok: ${book.stok} buku',
                                  style: TextStyle(
                                    color: book.stok > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed: () => _editStock(book),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Ubah stok',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
