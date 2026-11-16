import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/services/auth_service.dart';

void main() {
  group('authErrorMessage', () {
    test('kredensial salah', () {
      expect(
        authErrorMessage('invalid-credential'),
        'Email atau kata sandi salah',
      );
      expect(authErrorMessage('wrong-password'), 'Email atau kata sandi salah');
      expect(authErrorMessage('user-not-found'), 'Email atau kata sandi salah');
    });

    test('email sudah terdaftar', () {
      expect(authErrorMessage('email-already-in-use'), 'Email sudah terdaftar');
    });

    test('kode tidak dikenal memberi pesan umum', () {
      expect(authErrorMessage('kode-baru'), genericErrorMessage);
    });
  });

  group('errorMessageFor', () {
    test('galat Firebase Auth memakai pesan sesuai kode', () {
      expect(
        errorMessageFor(FirebaseAuthException(code: 'email-already-in-use')),
        'Email sudah terdaftar',
      );
    });

    test('galat lain memakai pesan umum', () {
      expect(errorMessageFor(Exception('apa saja')), genericErrorMessage);
    });
  });
}
