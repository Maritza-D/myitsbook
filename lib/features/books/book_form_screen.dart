import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/book_card.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.initialType,
    this.editingBook,
  });

  final AppRepository repository;
  final UserProfile profile;
  final ListingType initialType;
  final BookItem? editingBook;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late ListingType _type;
  late String _kategori;
  late String _kondisi;

  late final TextEditingController _judulCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _namaPenjualCtrl;
  late final TextEditingController _waCtrl;
  late final TextEditingController _lokasiCtrl;

  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _coverError;
  bool _saving = false;

  bool get _isEditing => widget.editingBook != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingBook;
    _type = editing?.jenisListing ?? widget.initialType;
    _kategori = editing?.kategori ?? kBookCategories.first;
    _kondisi = editing?.kondisi ?? kBookConditions.first;
    _judulCtrl = TextEditingController(text: editing?.judul ?? '');
    _hargaCtrl = TextEditingController(
      text: editing != null && editing.harga > 0 ? '${editing.harga}' : '',
    );
    _deskripsiCtrl = TextEditingController(text: editing?.deskripsi ?? '');
    _namaPenjualCtrl = TextEditingController(
      text: editing?.namaPenjual ?? widget.profile.nama,
    );
    _waCtrl = TextEditingController(
      text: editing?.kontakWa ?? widget.profile.telepon,
    );
    _lokasiCtrl = TextEditingController(
      text: editing?.lokasi ?? kCampusLocations.first,
    );
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _hargaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _namaPenjualCtrl.dispose();
    _waCtrl.dispose();
    _lokasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showAppBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final semantic = AppSemanticColors.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unggah Foto Sampul',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Format JPG atau PNG, maksimal ukuran 5 MB.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: semantic.border),
                ),
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: semantic.navy,
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: semantic.textMuted,
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: semantic.border),
                ),
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: semantic.navy,
                ),
                title: Text(
                  'Ambil Foto dengan Kamera',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: semantic.textMuted,
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final err = validateCoverImageMeta(
        fileName: picked.name,
        fileSizeBytes: bytes.length,
      );
      if (!mounted) return;
      if (err != null) {
        setState(() => _coverError = err);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      setState(() {
        _coverBytes = bytes;
        _coverFileName = picked.name;
        _coverError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat memuat foto: ${mapAppError(e)}')),
      );
    }
  }

  Future<void> _submit() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    final hasExistingPhoto =
        (widget.editingBook?.fotoUrl.isNotEmpty ?? false) ||
        widget.repository.isDemoMode;
    if (_coverBytes == null && !hasExistingPhoto) {
      setState(() => _coverError = 'Foto sampul buku wajib diunggah (JPG/PNG)');
      return;
    }
    if (!validForm) return;

    setState(() => _saving = true);
    try {
      final harga = _type == ListingType.donasi
          ? 0
          : int.parse(_hargaCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final payload = BookPayload(
        judul: _judulCtrl.text,
        kategori: _kategori,
        kondisi: _kondisi,
        deskripsi: _deskripsiCtrl.text,
        jenisListing: _type,
        harga: harga,
        namaPenjual: _namaPenjualCtrl.text,
        kontakWa: _waCtrl.text,
        lokasi: _lokasiCtrl.text,
        existingFotoUrl: widget.editingBook?.fotoUrl,
        coverBytes: _coverBytes,
        coverFileName: _coverFileName,
      );
      if (_isEditing) {
        await widget.repository.updateBook(widget.editingBook!.id, payload);
      } else {
        await widget.repository.createBook(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Perubahan buku disimpan.'
                : 'Buku berhasil dipublikasikan ke katalog.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final words = countWords(_deskripsiCtrl.text);
    final overLimit = words > kMaxDescriptionWords;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Buku'
              : (_type == ListingType.donasi ? 'Donasi Buku' : 'Jual Buku'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: semantic.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: semantic.subtleSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final opt in [
                      (ListingType.jual, 'Jual Buku', Icons.sell_outlined),
                      (
                        ListingType.donasi,
                        'Donasi (Gratis)',
                        Icons.volunteer_activism_outlined,
                      ),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: _saving
                              ? null
                              : () => setState(() => _type = opt.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _type == opt.$1
                                  ? scheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  opt.$3,
                                  size: 16.5,
                                  color: _type == opt.$1
                                      ? (opt.$1 == ListingType.donasi
                                            ? semantic.donation
                                            : scheme.primary)
                                      : semantic.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    opt.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 13,
                                      fontWeight: _type == opt.$1
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: _type == opt.$1
                                          ? (opt.$1 == ListingType.donasi
                                                ? semantic.donation
                                                : scheme.primary)
                                          : semantic.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Foto Sampul',
                subtitle: 'JPG/PNG maksimal 5 MB',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _saving ? null : _showPhotoSourceSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 158,
                        decoration: BoxDecoration(
                          color: semantic.subtleSurface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _coverError != null
                                ? scheme.error
                                : semantic.border,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _coverBytes != null
                            ? Image.memory(_coverBytes!, fit: BoxFit.cover)
                            : (widget.editingBook?.fotoUrl.isNotEmpty ?? false)
                            ? BookCoverImage(
                                fotoUrl: widget.editingBook!.fotoUrl,
                                title: widget.editingBook!.judul,
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: scheme.surface,
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: semantic.border,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 22,
                                        color: semantic.silverBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ketuk untuk unggah foto sampul',
                                      style: TextStyle(
                                        fontFamily: AppTheme.bodyFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pastikan sampul terlihat jelas',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    if (_coverError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _coverError!,
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactMediaButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Galeri',
                            onTap: _saving
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactMediaButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Kamera',
                            onTap: _saving
                                ? null
                                : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSectionCard(
                title: 'Informasi Buku',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('Judul Buku'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _judulCtrl,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textInputAction: TextInputAction.next,
                      validator: (v) => validateRequired(v, 'Judul buku'),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Rekayasa Perangkat Lunak Edisi 9',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Kategori'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in kBookCategories)
                          _SelectablePill(
                            label: cat,
                            selected: _kategori == cat,
                            onTap: _saving
                                ? null
                                : () => setState(() => _kategori = cat),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Kondisi Fisik'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cond in kBookConditions)
                          _SelectablePill(
                            label: cond,
                            selected: _kondisi == cond,
                            onTap: _saving
                                ? null
                                : () => setState(() => _kondisi = cond),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_type == ListingType.jual) ...[
                      const _FieldLabel('Harga Jual'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _hargaCtrl,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: scheme.onSurface,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => validateBookPrice(v, isSale: true),
                        decoration: const InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '50000',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: semantic.donationContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.volunteer_activism_outlined,
                              size: 18,
                              color: semantic.donation,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Buku donasi akan tampil dengan label Gratis di katalog.',
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        const Expanded(child: _FieldLabel('Deskripsi Singkat')),
                        Text(
                          '$words / $kMaxDescriptionWords kata',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11.5,
                            fontWeight: overLimit
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: overLimit
                                ? scheme.error
                                : semantic.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      validator: validateBookDescription,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Halaman bersih tanpa coretan, sampul rapi.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSectionCard(
                title: 'Kontak & Lokasi',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel(
                      _type == ListingType.donasi
                          ? 'Nama Donatur'
                          : 'Nama Penjual',
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaPenjualCtrl,
                      style: Theme.of(context).textTheme.bodyMedium,
                      validator: (v) => validateRequired(v, 'Nama penjual'),
                      decoration: const InputDecoration(
                        hintText: 'Nama lengkap mahasiswa',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Nomor WhatsApp'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _waCtrl,
                      style: Theme.of(context).textTheme.bodyMedium,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          validatePhone(v, label: 'Nomor WhatsApp'),
                      decoration: const InputDecoration(
                        hintText: '08xxxxxxxxxx',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Lokasi Serah Terima di Kampus ITS'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lokasiCtrl,
                      style: Theme.of(context).textTheme.bodyMedium,
                      validator: (v) =>
                          validateRequired(v, 'Lokasi serah terima'),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Gedung Sistem Informasi ITS',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final loc in kCampusLocations)
                          _SelectablePill(
                            label: loc,
                            selected: _lokasiCtrl.text == loc,
                            compact: true,
                            onTap: () =>
                                setState(() => _lokasiCtrl.text = loc),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: semantic.border)),
          ),
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            style: _type == ListingType.donasi
                ? FilledButton.styleFrom(
                    backgroundColor: semantic.donation,
                    foregroundColor: semantic.onDonation,
                  )
                : null,
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: scheme.onPrimary,
                    ),
                  )
                : Text(_isEditing ? 'Simpan Perubahan' : 'Publikasikan Buku'),
          ),
        ),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: semantic.textMuted,
      ),
    );
  }
}

class _CompactMediaButton extends StatelessWidget {
  const _CompactMediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: semantic.subtleSurface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: semantic.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: semantic.navy),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? semantic.silverFrost : scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.primary : semantic.border,
          width: selected ? 1.3 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 14,
            vertical: compact ? 6.5 : 8.5,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? scheme.primary : semantic.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
