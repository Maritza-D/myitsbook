import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myitsbook/core/config/supabase_config.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/auth/auth_screen.dart';
import 'package:myitsbook/features/shell/app_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppRepository repository;
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    repository = SupabaseRepository(Supabase.instance.client);
  } else {
    repository = DemoRepository();
  }

  runApp(MyITSBookApp(repository: repository));
}

class MyITSBookApp extends StatefulWidget {
  const MyITSBookApp({super.key, required this.repository});

  final AppRepository repository;

  @override
  State<MyITSBookApp> createState() => _MyITSBookAppState();
}

class _MyITSBookAppState extends State<MyITSBookApp> {
  late AppRepository _repo;
  UserProfile? _profile;
  bool _restoring = true;
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository;
    _restore();
    if (SupabaseConfig.isConfigured && !_repo.isDemoMode) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        _restore();
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final restored = await _repo.restoreSession();
      if (mounted) {
        setState(() {
          _profile = restored;
          _restoring = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profile = null;
          _restoring = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _repo.signOut();
    if (mounted) {
      setState(() {
        _profile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_restoring) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_profile == null) {
      home = AuthScreen(
        repository: _repo,
        onAuthenticated: (p) => setState(() => _profile = p),
      );
    } else {
      home = AppShell(
        repository: _repo,
        profile: _profile!,
        onProfileUpdated: (p) => setState(() => _profile = p),
        onLogout: _handleLogout,
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      );
    }

    return MaterialApp(
      title: 'MyITSBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: home,
    );
  }
}
