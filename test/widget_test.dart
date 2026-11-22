import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myitsbook/core/theme/app_theme.dart';
import 'package:myitsbook/data/models.dart';
import 'package:myitsbook/data/repository.dart';
import 'package:myitsbook/features/books/book_detail_screen.dart';
import 'package:myitsbook/features/books/book_form_screen.dart';
import 'package:myitsbook/features/profile/profile_screen.dart';
import 'package:myitsbook/main.dart';

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('AuthScreen fokus Seller/Buyer tanpa fitur Admin dan tanpa pratinjau', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final repo = DemoRepository();
    await tester.pumpWidget(MyITSBookApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke Akun ITS'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Portal Admin MyITSBook'), findsNothing);
    expect(find.text('Mode Pratinjau Mahasiswa'), findsNothing);
    expect(find.text('Masuk Mode Pratinjau UI'), findsNothing);
  });

  testWidgets('RegisterScreen membuka Bottom Sheet verifikasi email 2 langkah', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final repo = DemoRepository(requireEmailVerification: true);
    await tester.pumpWidget(MyITSBookApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nadia Putri');
    await tester.enterText(fields.at(1), '5026241100');
    await tester.enterText(fields.at(3), '081234567890');
    await tester.enterText(fields.at(4), 'nadia.putri@gmail.com');
    await tester.enterText(fields.at(5), 'rahasia123');

    final submitBtn = find.text('Daftar Akun').last;
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Email Anda'), findsOneWidget);
    expect(find.text('nadia.putri@gmail.com'), findsWidgets);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Verifikasi Kode & Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang, Nadia'), findsOneWidget);
  });

  testWidgets(
    'Beranda menampilkan buku, filter bottom sheet, dan tab Semua/Dijual/Donasi',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      final repo = DemoRepository(initialUser: DemoRepository.defaultStudent);
      await tester.pumpWidget(MyITSBookApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Selamat datang, Michael'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(find.text('Rekayasa Perangkat Lunak Edisi 9'), findsWidgets);

      await tester.tap(find.text('Donasi').first);
      await tester.pumpAndSettle();
      expect(find.text('Kalkulus Purcell Jilid 1'), findsWidgets);
      expect(find.text('Rekayasa Perangkat Lunak Edisi 9'), findsNothing);

      // Buka Filter & Urutkan Bottom Sheet dari ikon filter
      await tester.drag(find.byType(ListView).first, const Offset(0, 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Filter & Urutkan'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);
    },
  );

  testWidgets(
    'BR-05 & BR-07 Detail buku menonaktifkan beli untuk buku terjual atau milik sendiri',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      final repo = DemoRepository(initialUser: DemoRepository.defaultStudent);
      final soldBook = (await repo.fetchBookById('book-5'))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BookDetailScreen(
            key: const ValueKey('sold-book'),
            repository: repo,
            profile: DemoRepository.defaultStudent,
            bookId: soldBook.id,
            initialBook: soldBook,
            isWishlisted: false,
            onToggleWishlist: () {},
            onBookChanged: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tidak Tersedia (Terjual)'), findsOneWidget);

      final ownBook = (await repo.fetchBookById('book-6'))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: BookDetailScreen(
            key: const ValueKey('own-book'),
            repository: repo,
            profile: DemoRepository.defaultStudent,
            bookId: ownBook.id,
            initialBook: ownBook,
            isWishlisted: false,
            onToggleWishlist: () {},
            onBookChanged: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ubah Status'), findsOneWidget);
      expect(find.text('Hubungi Penjual'), findsNothing);
    },
  );

  testWidgets('ProfileScreen tanpa Hubungi Admin dan logout memakai Bottom Sheet', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final repo = DemoRepository(initialUser: DemoRepository.defaultStudent);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(412, 915),
            textScaler: TextScaler.linear(1.2),
          ),
          child: ProfileScreen(
            repository: repo,
            profile: DemoRepository.defaultStudent,
            wishlistIds: const {'book-2'},
            onToggleWishlist: (_) {},
            onProfileUpdated: (_) {},
            onLogout: () {},
            themeMode: ThemeMode.light,
            onThemeModeChanged: (_) {},
            onDataMutated: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hubungi Admin'), findsNothing);
    expect(find.text('Daftar Buku Saya'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar Akun'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Keluar dari Akun?'), findsOneWidget);
  });

  testWidgets('BookFormScreen memvalidasi batas 15 kata deskripsi', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final repo = DemoRepository(initialUser: DemoRepository.defaultStudent);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BookFormScreen(
          repository: repo,
          profile: DemoRepository.defaultStudent,
          initialType: ListingType.jual,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Struktur Data');
    await tester.enterText(fields.at(1), '45000');
    await tester.enterText(
      fields.at(2),
      'a b c d e f g h i j k l m n o p q', // 17 kata
    );

    final publishBtn = find.text('Publikasikan Buku');
    await tester.ensureVisible(publishBtn);
    await tester.tap(publishBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('maksimal 15 kata'), findsOneWidget);
  });
}
