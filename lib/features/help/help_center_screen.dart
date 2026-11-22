
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<_HelpGuide> _guides = [
    _HelpGuide(
      icon: Icons.menu_book_outlined,
      title: 'Panduan Penggunaan MyITSBook',
      description: 'Mengenal fitur dan navigasi aplikasi.',
      steps: [
        'Buka aplikasi MyITSBook melalui perangkat Anda.',
        'Jelajahi katalog untuk melihat buku yang tersedia.',
        'Gunakan kategori dan pencarian untuk menemukan buku.',
        'Gunakan fitur wishlist untuk menyimpan buku yang diminati.',
        'Gunakan menu Profil untuk mengelola informasi akun.',
      ],
    ),
    _HelpGuide(
      icon: Icons.shopping_bag_outlined,
      title: 'Cara Membeli Buku',
      description: 'Langkah memperoleh buku dari pengguna lain.',
      steps: [
        'Buka halaman katalog dan pilih buku yang diinginkan.',
        'Periksa informasi, harga, kondisi, dan identitas penjual.',
        'Hubungi penjual melalui fitur chat yang tersedia.',
        'Diskusikan metode pembayaran dan lokasi pertemuan.',
        'Pastikan kesepakatan transaksi dipahami kedua pihak.',
      ],
    ),
    _HelpGuide(
      icon: Icons.sell_outlined,
      title: 'Cara Menjual Buku',
      description: 'Panduan menawarkan buku milik Anda.',
      steps: [
        'Masuk ke akun MyITSBook.',
        'Pilih menu untuk menambahkan buku.',
        'Lengkapi judul, kategori, deskripsi, kondisi, dan harga.',
        'Tambahkan foto buku yang jelas.',
        'Periksa kembali informasi sebelum menerbitkan listing.',
        'Tanggapi pesan calon pembeli melalui fitur chat.',
      ],
    ),
    _HelpGuide(
      icon: Icons.volunteer_activism_outlined,
      title: 'Cara Mendonasikan Buku',
      description: 'Membagikan buku kepada mahasiswa lain.',
      steps: [
        'Pilih menu untuk menambahkan buku.',
        'Pilih jenis listing donasi.',
        'Lengkapi informasi dan foto buku.',
        'Pastikan kondisi buku dijelaskan secara jujur.',
        'Tanggapi pesan pengguna yang berminat menerima donasi.',
        'Sepakati cara dan lokasi penyerahan buku.',
      ],
    ),
    _HelpGuide(
      icon: Icons.chat_outlined,
      title: 'Panduan Chat dan Transaksi',
      description: 'Berkomunikasi dengan pengguna lain.',
      steps: [
        'Buka fitur chat dengan penjual atau calon pembeli.',
        'Sampaikan pertanyaan atau kesepakatan dengan jelas.',
        'Konfirmasikan harga, kondisi buku, dan lokasi pertemuan.',
        'Jangan membagikan kata sandi atau kode verifikasi akun.',
        'Periksa kembali kesepakatan sebelum menyelesaikan transaksi.',
      ],
    ),
  ];

  static const List<_HelpQuestion> _faqs = [
    _HelpQuestion(
      question: 'Apakah satu akun bisa menjadi pembeli dan penjual?',
      answer:
          'Ya. Satu akun MyITSBook dapat digunakan untuk mencari buku, '
          'menjual buku, maupun menawarkan buku untuk didonasikan.',
    ),
    _HelpQuestion(
      question: 'Apakah MyITSBook menyediakan layanan peminjaman buku?',
      answer:
          'Tidak. MyITSBook berfokus pada penjualan dan donasi buku, '
          'bukan layanan peminjaman.',
    ),
    _HelpQuestion(
      question: 'Bagaimana cara menghubungi penjual?',
      answer:
          'Gunakan fitur chat yang tersedia untuk berkomunikasi dan '
          'mendiskusikan kesepakatan dengan penjual.',
    ),
    _HelpQuestion(
      question: 'Bagaimana jika informasi buku tidak sesuai?',
      answer:
          'Sebaiknya konfirmasikan kondisi buku secara langsung kepada '
          'penjual melalui chat sebelum menyepakati transaksi.',
    ),
    _HelpQuestion(
      question: 'Apakah lokasi penyerahan buku ditentukan aplikasi?',
      answer:
          'Lokasi penyerahan dapat didiskusikan dan disepakati langsung '
          'oleh pembeli dan penjual.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 34,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ada yang bisa kami bantu?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Temukan panduan penggunaan MyITSBook dan jawaban '
                  'atas pertanyaan yang sering diajukan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Panduan Penggunaan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ..._guides.map(
            (guide) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Icon(guide.icon, color: scheme.primary),
                title: Text(
                  guide.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(guide.description),
                childrenPadding:
                    const EdgeInsets.fromLTRB(18, 0, 18, 16),
                children: [
                  const Divider(),
                  ...List.generate(
                    guide.steps.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              guide.steps[index],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pertanyaan yang Sering Diajukan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < _faqs.length; i++) ...[
                  ExpansionTile(
                    leading: Icon(
                      Icons.help_outline_rounded,
                      color: scheme.primary,
                    ),
                    title: Text(
                      _faqs[i].question,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _faqs[i].answer,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  if (i != _faqs.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    color: scheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masih membutuhkan bantuan?',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Informasi kontak bantuan resmi MyITSBook '
                          'akan diumumkan oleh pengelola aplikasi.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    height: 1.45,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'MyITSBook · Pusat Bantuan',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpGuide {
  const _HelpGuide({
    required this.icon,
    required this.title,
    required this.description,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> steps;
}

class _HelpQuestion {
  const _HelpQuestion({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}
