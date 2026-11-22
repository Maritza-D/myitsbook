import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/history/sales_history_screen.dart';
import 'package:myitsbook/features/profile/my_books_screen.dart';
import 'package:myitsbook/features/profile/wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.wishlistIds,
    required this.onToggleWishlist,
    required this.onProfileUpdated,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onDataMutated,
  });

  final AppRepository repository;
  final UserProfile profile;
  final Set<String> wishlistIds;
  final ValueChanged<String> onToggleWishlist;
  final ValueChanged<UserProfile> onProfileUpdated;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onDataMutated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _jualCount = 0;
  int _donasiCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final myBooks = await widget.repository.fetchMyBooks();
      if (!mounted) return;
      setState(() {
        _jualCount = myBooks
            .where((b) => b.jenisListing == ListingType.jual)
            .length;
        _donasiCount = myBooks
            .where((b) => b.jenisListing == ListingType.donasi)
            .length;
      });
    } catch (_) {}
  }

  Future<void> _editProfileSheet() async {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: widget.profile.nama);
    final jurusanCtrl = TextEditingController(text: widget.profile.jurusan);
    final telCtrl = TextEditingController(text: widget.profile.telepon);
    bool saving = false;

    final updated = await showAppBottomSheet<UserProfile>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final scheme = Theme.of(ctx).colorScheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ubah Profil',
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Perbarui informasi profil yang ditampilkan pada daftar buku Anda.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: namaCtrl,
                    validator: (v) => validateRequired(v, 'Nama lengkap'),
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: jurusanCtrl,
                    validator: (v) => validateRequired(v, 'Jurusan'),
                    decoration: const InputDecoration(labelText: 'Jurusan'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    validator: validatePhone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon / WhatsApp',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final res = await widget.repository.updateProfile(
                                nama: namaCtrl.text,
                                jurusan: jurusanCtrl.text,
                                telepon: telCtrl.text,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(res);
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(mapAppError(e))),
                                );
                              }
                            }
                          },
                    child: saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    namaCtrl.dispose();
    jurusanCtrl.dispose();
    telCtrl.dispose();

    if (updated != null) {
      widget.onProfileUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
        );
      }
    }
  }

  Future<void> _showThemeSheet() async {
    final chosen = await showAppBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) {
        final semantic = AppSemanticColors.of(ctx);
        final scheme = Theme.of(ctx).colorScheme;
        final options = [
          (ThemeMode.system, 'Ikuti Sistem', Icons.brightness_auto_rounded),
          (ThemeMode.light, 'Tema Terang (Silver)', Icons.light_mode_outlined),
          (ThemeMode.dark, 'Tema Gelap (Midnight)', Icons.dark_mode_outlined),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tema Tampilan',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih preferensi tema tampilan aplikasi Anda.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final opt in options) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: widget.themeMode == opt.$1
                          ? scheme.primary
                          : semantic.border,
                      width: widget.themeMode == opt.$1 ? 1.6 : 1,
                    ),
                  ),
                  tileColor: widget.themeMode == opt.$1
                      ? semantic.silverFrost
                      : scheme.surface,
                  leading: Icon(opt.$3, color: semantic.navy),
                  title: Text(
                    opt.$2,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  trailing: widget.themeMode == opt.$1
                      ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(opt.$1),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
    if (chosen != null) widget.onThemeModeChanged(chosen);
  }

  Future<void> _confirmLogout() async {
    final ok = await showConfirmBottomSheet(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Anda perlu masuk kembali menggunakan akun ITS untuk mengakses katalog dan pesan.',
      confirmLabel: 'Keluar',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (ok) widget.onLogout();
  }

  String get _themeLabel {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Midnight Gelap';
      case ThemeMode.system:
        return 'Ikuti Sistem';
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.profile;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      semantic.navyDeep,
                      semantic.navy,
                      semantic.navyMid,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      right: -46,
                      top: -42,
                      child: IgnorePointer(
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF9AC3EE).withValues(alpha: 0.24),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -36,
                      bottom: -44,
                      child: IgnorePointer(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 68),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Profil Saya',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Tema Tampilan',
                                  onPressed: _showThemeSheet,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.12,
                                    ),
                                    minimumSize: const Size(44, 44),
                                  ),
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 74,
                                      height: 74,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: const Color(0xFF9AC3EE),
                                          width: 2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        profile.nama.isNotEmpty
                                            ? profile.nama[0].toUpperCase()
                                            : 'M',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.displayFont,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -4,
                                      bottom: -4,
                                      child: GestureDetector(
                                        onTap: _editProfileSheet,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.18,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 15,
                                            color: Color(0xFF0B2245),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 20,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.school_outlined,
                                            size: 14,
                                            color: Color(0xFFBFD7F2),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              '${profile.jurusan} · NRP ${profile.nrp}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFFD2E4F8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Color(0xFFFACC15),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            profile.ratingRata2.toStringAsFixed(
                                              1,
                                            ),
                                            style: const TextStyle(
                                              fontFamily: AppTheme.displayFont,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFFACC15),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.14,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              profile.statusVerifikasi,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFE8F1FB),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: -36,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: semantic.border),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF0B2245)
                                  .withValues(alpha: 0.09),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      _ProfileStatColumn(value: '$_jualCount', label: 'Dijual'),
                      Container(width: 1, height: 34, color: semantic.border),
                      _ProfileStatColumn(
                        value: '$_donasiCount',
                        label: 'Donasi',
                      ),
                      Container(width: 1, height: 34, color: semantic.border),
                      _ProfileStatColumn(
                        value: '${widget.wishlistIds.length}',
                        label: 'Wishlist',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 52),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.email_outlined,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Email',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        subtitle: Text(
                          profile.email,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Divider(height: 1, indent: 70, color: semantic.border),
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.phone_outlined,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Nomor Telepon',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        subtitle: Text(
                          profile.telepon,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.schedule_rounded,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Daftar Buku Saya',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'Kelola daftar buku terjual, donasi, dan status',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: semantic.textMuted,
                        ),
                        onTap: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => MyBooksScreen(
                                repository: widget.repository,
                                profile: profile,
                                wishlistIds: widget.wishlistIds,
                                onToggleWishlist: widget.onToggleWishlist,
                                onDataMutated: widget.onDataMutated,
                              ),
                            ),
                          );
                          _loadStats();
                        },
                      ),
                      Divider(height: 1, indent: 70, color: semantic.border),
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.history_rounded,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Riwayat Dijual & Donasi',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'Lihat buku yang sudah terjual dan didonasikan',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: semantic.textMuted,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SalesHistoryScreen(
                              repository: widget.repository,
                              profile: profile,
                              wishlistIds: widget.wishlistIds,
                              onToggleWishlist: widget.onToggleWishlist,
                              onDataMutated: widget.onDataMutated,
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, indent: 70, color: semantic.border),
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.favorite_border_rounded,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Daftar Wishlist',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${widget.wishlistIds.length} buku tersimpan',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: semantic.textMuted,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WishlistScreen(
                              repository: widget.repository,
                              profile: profile,
                              wishlistIds: widget.wishlistIds,
                              onToggleWishlist: widget.onToggleWishlist,
                              onDataMutated: widget.onDataMutated,
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, indent: 70, color: semantic.border),
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.person_outline_rounded,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Ubah Profil',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'Perbarui nama, departemen, dan kontak',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: semantic.textMuted,
                        ),
                        onTap: _editProfileSheet,
                      ),
                      Divider(height: 1, indent: 70, color: semantic.border),
                      ListTile(
                        leading: _ProfileIconBox(
                          icon: Icons.palette_outlined,
                          semantic: semantic,
                        ),
                        title: Text(
                          'Tema Tampilan',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          _themeLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: semantic.textMuted,
                        ),
                        onTap: _showThemeSheet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    backgroundColor: scheme.error.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.25),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text('Keluar Akun'),
                ),
                const SizedBox(height: 16),
                Text(
                  'MyITSBook · Versi 1.0.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: semantic.textMuted),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatColumn extends StatelessWidget {
  const _ProfileStatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: semantic.navy,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: semantic.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileIconBox extends StatelessWidget {
  const _ProfileIconBox({required this.icon, required this.semantic});

  final IconData icon;
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: semantic.silverFrost,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: semantic.silverBlue, size: 21),
    );
  }
}
