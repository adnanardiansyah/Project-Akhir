import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/app_user.dart';

void main() {
  group('AppUser.fromMap', () {
    test('membaca peran pemesan', () {
      final user = AppUser.fromMap('u1', {
        'role': 'customer',
        'displayName': 'Budi',
      });
      expect(user, isNotNull);
      expect(user!.uid, 'u1');
      expect(user.role, UserRole.customer);
      expect(user.displayName, 'Budi');
      expect(user.restaurantId, isNull);
    });

    test('membaca peran resto beserta restaurantId', () {
      final user = AppUser.fromMap('r1', {
        'role': 'restaurant',
        'displayName': 'Resto Contoh 1',
        'restaurantId': 'resto1',
      });
      expect(user!.role, UserRole.restaurant);
      expect(user.restaurantId, 'resto1');
    });

    test('membaca peran admin', () {
      final user = AppUser.fromMap('a1', {'role': 'admin'});
      expect(user!.role, UserRole.admin);
      expect(user.displayName, '');
    });

    test('peran tidak dikenal atau kosong menghasilkan null', () {
      expect(AppUser.fromMap('x', {'role': 'superadmin'}), isNull);
      expect(AppUser.fromMap('x', {}), isNull);
    });

    test('displayName kosong menjadi string kosong', () {
      final user = AppUser.fromMap('u1', {'role': 'customer'});
      expect(user!.displayName, '');
    });
  });
}
