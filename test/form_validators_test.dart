import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/utils/form_validators.dart';

void main() {
  group('validateEmail', () {
    test('menolak email kosong', () {
      expect(validateEmail(''), 'Email wajib diisi');
      expect(validateEmail(null), 'Email wajib diisi');
      expect(validateEmail('   '), 'Email wajib diisi');
    });

    test('menolak format salah', () {
      expect(validateEmail('budi'), 'Format email tidak valid');
      expect(validateEmail('budi@'), 'Format email tidak valid');
      expect(validateEmail('budi@mail'), 'Format email tidak valid');
      expect(validateEmail('bu di@mail.com'), 'Format email tidak valid');
    });

    test('menerima email valid, termasuk spasi di tepi', () {
      expect(validateEmail('budi@mail.com'), isNull);
      expect(validateEmail('  budi@mail.com '), isNull);
    });
  });

  group('validatePassword', () {
    test('menolak kosong', () {
      expect(validatePassword(''), 'Kata sandi wajib diisi');
      expect(validatePassword(null), 'Kata sandi wajib diisi');
    });

    test('menolak kurang dari 6 karakter', () {
      expect(validatePassword('12345'), 'Kata sandi minimal 6 karakter');
    });

    test('menerima tepat 6 karakter', () {
      expect(validatePassword('123456'), isNull);
    });
  });

  group('validateDisplayName', () {
    test('menolak kosong atau spasi saja', () {
      expect(validateDisplayName(''), 'Nama wajib diisi');
      expect(validateDisplayName('   '), 'Nama wajib diisi');
      expect(validateDisplayName(null), 'Nama wajib diisi');
    });

    test('menerima nama', () {
      expect(validateDisplayName('Budi'), isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('menolak kosong', () {
      expect(validatePasswordConfirmation('', 'rahasia1'), 'Ulangi kata sandi');
    });

    test('menolak bila tidak sama', () {
      expect(
        validatePasswordConfirmation('rahasia2', 'rahasia1'),
        'Kata sandi tidak sama',
      );
    });

    test('menerima bila sama', () {
      expect(validatePasswordConfirmation('rahasia1', 'rahasia1'), isNull);
    });
  });
}
