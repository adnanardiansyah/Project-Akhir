import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/menu_item.dart';
import 'package:food_order_app/models/restaurant.dart';

void main() {
  group('Restaurant.fromMap', () {
    test('membaca semua field', () {
      final restaurant = Restaurant.fromMap('resto1', {
        'name': 'Resto Contoh 1',
        'address': 'Lhokseumawe',
        'location': const GeoPoint(5.1801, 97.1507),
        'ownerUid': 'abc',
      });
      expect(restaurant!.id, 'resto1');
      expect(restaurant.name, 'Resto Contoh 1');
      expect(restaurant.address, 'Lhokseumawe');
      expect(restaurant.location.latitude, 5.1801);
      expect(restaurant.location.longitude, 97.1507);
      expect(restaurant.ownerUid, 'abc');
    });

    test('alamat dan ownerUid kosong diganti string kosong', () {
      final restaurant = Restaurant.fromMap('r', {
        'name': 'Resto',
        'location': const GeoPoint(0, 0),
      });
      expect(restaurant!.address, '');
      expect(restaurant.ownerUid, '');
    });

    test('alamat atau ownerUid bertipe lain tidak menjatuhkan parsing', () {
      final restaurant = Restaurant.fromMap('r', {
        'name': 'Resto',
        'location': const GeoPoint(0, 0),
        'address': 123,
        'ownerUid': true,
      });
      expect(restaurant!.address, '');
      expect(restaurant.ownerUid, '');
    });

    test('tanpa nama atau lokasi menghasilkan null', () {
      expect(
        Restaurant.fromMap('r', {'location': const GeoPoint(0, 0)}),
        isNull,
      );
      expect(Restaurant.fromMap('r', {'name': '  '}), isNull);
      expect(Restaurant.fromMap('r', {'name': 'Resto'}), isNull);
    });
  });

  group('MenuItem.fromMap', () {
    test('membaca nama dan harga bilangan bulat', () {
      final item = MenuItem.fromMap('m1', {'name': 'Mie Aceh', 'price': 15000});
      expect(item!.id, 'm1');
      expect(item.name, 'Mie Aceh');
      expect(item.price, 15000);
    });

    test('harga double bulat dari Console diterima', () {
      final item = MenuItem.fromMap('m1', {'name': 'Teh', 'price': 5000.0});
      expect(item!.price, 5000);
    });

    test('harga pecahan, negatif, teks, atau kosong ditolak', () {
      expect(MenuItem.fromMap('m', {'name': 'A', 'price': 1500.5}), isNull);
      expect(MenuItem.fromMap('m', {'name': 'A', 'price': -1}), isNull);
      expect(MenuItem.fromMap('m', {'name': 'A', 'price': '15000'}), isNull);
      expect(MenuItem.fromMap('m', {'name': 'A'}), isNull);
    });

    test('harga tak hingga atau NaN ditolak tanpa galat', () {
      expect(
        MenuItem.fromMap('m', {'name': 'A', 'price': double.infinity}),
        isNull,
      );
      expect(MenuItem.fromMap('m', {'name': 'A', 'price': double.nan}), isNull);
    });

    test('tanpa nama ditolak', () {
      expect(MenuItem.fromMap('m', {'price': 1000}), isNull);
    });
  });
}
