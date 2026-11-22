import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_bottom_sheet.dart';
import 'package:myitsbook/core/widgets/app_logo.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.repository,
    required this.onRegistered,
  });

  final AppRepository repository;
  final ValueChanged<UserProfile> onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _nrpCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController(text: 'Sistem Informasi');
  final _teleponCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nrpCtrl.dispose();
    _jurusanCtrl.dispose();
    _teleponCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final profile = await widget.repository.registerStudent(
        nama: _namaCtrl.text,
        nrp: _nrpCtrl.text,
        jurusan: _jurusanCtrl.text,
        telepon: _teleponCtrl.text,
        email: email,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      if (profile != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onRegistered(profile);
        return;
      }

      setState(() => _loading = false);
      final verified = await _showEmailVerificationSheet(email);
      if (!mounted || verified == null) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onRegistered(verified);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<UserProfile?> _showEmailVerificationSheet(String email) {
    return showAppBottomSheet<UserProfile>(
      context: context,
      builder: (ctx) => _EmailVerificationSheet(
        email: email,
        repository: widget.repository,
        onBackToLogin: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppHorizontalLogo(height: 38)),
                  const SizedBox(height: 18),
                  Text(
                    'Daftar Akun',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lengkapi data identitas mahasiswa ITS untuk membuat akun MyITSBook.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: semantic.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: semantic.border),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF0B2245)
                                    .withValues(alpha: 0.07),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Nama Lengkap',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _namaCtrl,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                validateRequired(v, 'Nama lengkap'),
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Nadia Putri',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NRP',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 7),
                                    TextFormField(
                                      controller: _nrpCtrl,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      validator: validateNrp,
                                      decoration: const InputDecoration(
                                        hintText: '50262...',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jurusan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 7),
                                    TextFormField(
                                      controller: _jurusanCtrl,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) =>
                                          validateRequired(v, 'Jurusan'),
                                      decoration: const InputDecoration(
                                        hintText: 'Sistem Informasi',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Nomor Telepon / WhatsApp',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _teleponCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: validatePhone,
                            decoration: const InputDecoration(
                              hintText: '08xx xxxx xxxx',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: validateEmail,
                            decoration: const InputDecoration(
                              hintText: 'nama@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined),
                              helperText:
                                  'Kode/tautan verifikasi akan dikirim ke email ini.',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Kata Sandi',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            validator: validatePassword,
                            decoration: InputDecoration(
                              hintText: 'Minimal 6 karakter',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Text('Daftar Akun'),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Sudah memiliki akun? ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: semantic.silverBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: const Text('Masuk'),
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
          ),
        ),
      ),
    );
  }
}

class _EmailVerificationSheet extends StatefulWidget {
  const _EmailVerificationSheet({
    required this.email,
    required this.repository,
    required this.onBackToLogin,
  });

  final String email;
  final AppRepository repository;
  final VoidCallback onBackToLogin;

  @override
  State<_EmailVerificationSheet> createState() =>
      _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<_EmailVerificationSheet> {
  final _otpCtrl = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _errorText;
  String? _infoText;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorText = 'Masukkan kode verifikasi 6–8 digit dari email Anda.';
        _infoText = null;
      });
      return;
    }
    setState(() {
      _verifying = true;
      _errorText = null;
      _infoText = null;
    });
    try {
      final profile = await widget.repository.verifySignupOtp(
        email: widget.email,
        token: code,
      );
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = mapAppError(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _errorText = null;
      _infoText = null;
    });
    try {
      await widget.repository.resendSignupVerification(widget.email);
      if (!mounted) return;
      setState(
        () => _infoText =
            'Email verifikasi baru telah dikirim. Periksa kotak masuk atau folder spam.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = mapAppError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 6, 22, 22 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: semantic.silverFrost,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: semantic.navy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi Email Anda',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: semantic.silverBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kami telah mengirimkan kode dan tautan konfirmasi ke Gmail Anda. Masukkan kode verifikasi di bawah ini, atau klik tautan di email lalu masuk kembali.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: semantic.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
              color: scheme.onSurface,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.error,
              ),
            ),
          ],
          if (_infoText != null) ...[
            const SizedBox(height: 8),
            Text(
              _infoText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: semantic.donation,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _verifying ? null : _verify,
            child: _verifying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Text('Verifikasi & Masuk'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_verifying || _resending) ? null : _resend,
                  child: Text(_resending ? 'Mengirim...' : 'Kirim Ulang'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: _verifying ? null : widget.onBackToLogin,
                  child: const Text('Ke Halaman Masuk'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
