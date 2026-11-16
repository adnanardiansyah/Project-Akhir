import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/controllers/cart_controller.dart';
import 'package:food_order_app/models/menu_item.dart';
import 'package:food_order_app/models/restaurant.dart';

// Resto dan menu contoh untuk tes
const _restoA = Restaurant(
  id: 'a',
  name: 'Resto A',
  address: '',
  location: GeoPoint(0, 0),
  ownerUid: '',
);
const _restoB = Restaurant(
  id: 'b',
  name: 'Resto B',
  address: '',
  location: GeoPoint(0, 0),
  ownerUid: '',
);
const _mie = MenuItem(id: 'mie', name: 'Mie Aceh', price: 15000);
const _teh = MenuItem(id: 'teh', name: 'Teh Tarik', price: 8000);
const _kopi = MenuItem(id: 'kopi', name: 'Kopi', price: 7000);

void main() {
  group('CartController', () {
    late CartController cart;

    setUp(() => cart = CartController());
    tearDown(() => cart.dispose());

    test('keranjang baru kosong dengan total nol', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.total, 0);
      expect(cart.totalQuantity, 0);
      expect(cart.restaurant, isNull);
    });

    test('total dihitung dari harga dikali jumlah tiap menu', () {
      cart.add(_restoA, _mie);
      cart.add(_restoA, _mie);
      cart.add(_restoA, _teh);
      expect(cart.quantityOf('mie'), 2);
      expect(cart.quantityOf('teh'), 1);
      expect(cart.totalQuantity, 3);
      expect(cart.total, 2 * 15000 + 8000);
      expect(cart.restaurant, _restoA);
    });

    test('urutan baris mengikuti urutan menu ditambahkan', () {
      cart.add(_restoA, _teh);
      cart.add(_restoA, _mie);
      cart.add(_restoA, _teh);
      expect(cart.items.map((i) => i.menuItem.id), ['teh', 'mie']);
    });

    test('mengurangi jumlah dan menghapus baris saat habis', () {
      cart.add(_restoA, _mie);
      cart.add(_restoA, _mie);
      cart.decrement('mie');
      expect(cart.quantityOf('mie'), 1);
      cart.decrement('mie');
      expect(cart.quantityOf('mie'), 0);
      expect(cart.isEmpty, isTrue);
      expect(cart.restaurant, isNull);
    });

    test('mengurangi menu yang tidak ada tidak berbuat apa-apa', () {
      cart.add(_restoA, _mie);
      cart.decrement('tidak-ada');
      expect(cart.total, 15000);
    });

    test('menu dari resto lain ditolak tanpa mengubah keranjang', () {
      cart.add(_restoA, _mie);
      expect(cart.canAddFrom(_restoB), isFalse);
      expect(() => cart.add(_restoB, _kopi), throwsStateError);
      expect(cart.total, 15000);
      expect(cart.restaurant, _restoA);
    });

    test('replaceWith mengganti isi dengan menu resto baru', () {
      cart.add(_restoA, _mie);
      cart.replaceWith(_restoB, _kopi);
      expect(cart.restaurant, _restoB);
      expect(cart.items.single.menuItem, _kopi);
      expect(cart.total, 7000);
    });

    test('clear mengosongkan keranjang', () {
      cart.add(_restoA, _mie);
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.total, 0);
      expect(cart.restaurant, isNull);
    });

    test('pendengar diberi tahu setiap perubahan', () {
      var notified = 0;
      cart.addListener(() => notified++);
      cart.add(_restoA, _mie);
      cart.decrement('mie');
      cart.add(_restoA, _teh);
      cart.clear();
      expect(notified, 4);
    });

    test('daftar baris tidak bisa diubah dari luar', () {
      cart.add(_restoA, _mie);
      expect(() => cart.items.clear(), throwsUnsupportedError);
    });
  });
}
