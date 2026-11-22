import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/core/utils/error_mapper.dart';
import 'package:myitsbook/core/utils/formatters.dart';
import 'package:myitsbook/core/widgets/app_logo.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/auth/forgot_password_screen.dart';
import 'package:myitsbook/features/auth/register_screen.dart';
import 'package:myitsbook/features/help/help_center_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final AppRepository repository;
  final ValueChanged<UserProfile> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final profile = await widget.repository.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      widget.onAuthenticated(profile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mapAppError(e))));
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
      body: Stack(
        children: [
          _AuthAmbientBackdrop(isDark: isDark, semantic: semantic),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppHorizontalLogo(height: 44)),
                      const SizedBox(height: 26),
                      Text(
                        'Masuk ke Akun ITS',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masuk untuk mencari, menjual, dan mendonasikan buku kuliah.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: semantic.textMuted),
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
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                        ),
                        child: Form(
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
                                textInputAction: TextInputAction.next,
                                validator: validateEmail,
                                decoration: const InputDecoration(
                                  hintText: 'nama@gmail.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kata Sandi',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 7),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: validatePassword,
                                decoration: InputDecoration(
                                  hintText: 'Minimal 6 karakter',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    tooltip: _obscurePassword
                                        ? 'Tampilkan kata sandi'
                                        : 'Sembunyikan kata sandi',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ForgotPasswordScreen(
                                                  repository: widget.repository,
                                                ),
                                          ),
                                        ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: semantic.silverBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text('Lupa Kata Sandi?'),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                    : const Text('Masuk'),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Belum memiliki akun? ',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: semantic.textMuted),
                                  ),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RegisterScreen(
                                                repository: widget.repository,
                                                onRegistered:
                                                    widget.onAuthenticated,
                                              ),
                                            ),
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: semantic.silverBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),
                                    child: const Text('Daftar Sekarang'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const HelpCenterScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Pusat Bantuan'),
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
        ],
      ),
    );
  }
}

class _AuthAmbientBackdrop extends StatelessWidget {
  const _AuthAmbientBackdrop({required this.isDark, required this.semantic});

  final bool isDark;
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    final tint = isDark
        ? semantic.silverBlue.withValues(alpha: 0.08)
        : semantic.silverBlue.withValues(alpha: 0.12);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: isDark ? 0.06 : 0.09),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            right: 24,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: isDark ? 0.05 : 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
