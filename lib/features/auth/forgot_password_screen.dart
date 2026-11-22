import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_logo.dart';
import 'package:myitsbook/data/repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.repository});

  final AppRepository repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await widget.repository.requestPasswordReset(_emailCtrl.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapAppError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppHorizontalLogo(height: 40)),
                  const SizedBox(height: 22),
                  Text(
                    'Pemulihan Kata Sandi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masukkan alamat email yang terdaftar untuk menerima tautan pengaturan ulang kata sandi Anda.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: semantic.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                    .withValues(alpha: 0.08),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: _sent
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: semantic.donationContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 30,
                                    color: semantic.donation,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tautan Terkirim',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Periksa kotak masuk email ${_emailCtrl.text.trim()} untuk mengatur ulang kata sandi Anda.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: semantic.textMuted),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Kembali ke Halaman Masuk'),
                              ),
                            ],
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Email',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 7),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: validateEmail,
                                  decoration: const InputDecoration(
                                    hintText: 'nama@student.its.ac.id',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 20),
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
                                      : const Text('Kirim Tautan Pemulihan'),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah ingat kata sandi Anda? ',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
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
