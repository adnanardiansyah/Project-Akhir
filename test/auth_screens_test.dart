import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/screens/auth/login_screen.dart';
import 'package:food_order_app/screens/auth/register_screen.dart';
import 'package:food_order_app/services/auth_service.dart';

// Memasang layar dalam MaterialApp lalu menunggu animasi masuk selesai
Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

// Menggulir ke tombol utama bila di luar layar, lalu mengetuknya
Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  group('LoginScreen', () {
    testWidgets('form kosong menampilkan pesan wajib diisi', (tester) async {
      await _pumpScreen(tester, LoginScreen(authService: AuthService()));

      await _tapButton(tester, 'Masuk');

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('email salah format dan sandi pendek ditolak', (tester) async {
      await _pumpScreen(tester, LoginScreen(authService: AuthService()));

      await tester.enterText(find.byType(TextFormField).at(0), 'budi');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await _tapButton(tester, 'Masuk');

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
    });

    testWidgets('tautan daftar membuka layar pendaftaran', (tester) async {
      await _pumpScreen(tester, LoginScreen(authService: AuthService()));

      await tester.tap(find.text('Belum punya akun? Daftar sebagai pemesan'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('form kosong menampilkan semua pesan wajib', (tester) async {
      await _pumpScreen(tester, RegisterScreen(authService: AuthService()));

      await _tapButton(tester, 'Daftar');

      expect(find.text('Nama wajib diisi'), findsOneWidget);
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
      expect(find.text('Ulangi kata sandi'), findsNWidgets(2));
    });

    testWidgets('konfirmasi sandi berbeda ditolak', (tester) async {
      await _pumpScreen(tester, RegisterScreen(authService: AuthService()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Budi');
      await tester.enterText(fields.at(1), 'budi@example.com');
      await tester.enterText(fields.at(2), 'rahasia1');
      await tester.enterText(fields.at(3), 'rahasia2');
      await _tapButton(tester, 'Daftar');

      expect(find.text('Kata sandi tidak sama'), findsOneWidget);
      expect(find.text('Nama wajib diisi'), findsNothing);
    });
  });
}
