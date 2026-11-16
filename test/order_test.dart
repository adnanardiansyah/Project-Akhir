import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/cart_item.dart';
import 'package:food_order_app/models/menu_item.dart';
import 'package:food_order_app/models/order.dart';
import 'package:food_order_app/services/order_service.dart';
import 'package:food_order_app/utils/format_date_time.dart';

// Data pesanan valid seperti yang ditulis order_service
Map<String, dynamic> _validOrderData() => {
  'customerUid': 'c1',
  'customerName': 'Rian',
  'restaurantId': 'resto1',
  'restaurantName': 'Mie Aceh Contoh',
  'items': [
    {'menuItemId': 'mie', 'name': 'Mie Aceh', 'price': 15000, 'qty': 2},
    {'menuItemId': 'teh', 'name': 'Teh Tarik', 'price': 8000, 'qty': 1},
  ],
  'total': 38000,
  'status': 'pending',
  'paymentMethod': null,
  'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 17, 7, 5)),
  'paidAt': null,
};

// Pesanan minimal dengan waktu buat tertentu, untuk tes urutan
FoodOrder _orderAt(String id, DateTime? createdAt) => FoodOrder(
  id: id,
  customerUid: 'c1',
  customerName: '',
  restaurantId: 'r',
  restaurantName: '',
  items: const [OrderItem(menuItemId: 'm', name: 'M', price: 1, qty: 1)],
  total: 1,
  status: OrderStatus.pending,
  createdAt: createdAt,
);

void main() {
  group('OrderItem', () {
    test('fromCartItem menyalin nama, harga, dan jumlah', () {
      const menu = MenuItem(id: 'mie', name: 'Mie Aceh', price: 15000);
      final item = OrderItem.fromCartItem(
        const CartItem(menuItem: menu, quantity: 3),
      );
      expect(item.toMap(), {
        'menuItemId': 'mie',
        'name': 'Mie Aceh',
        'price': 15000,
        'qty': 3,
      });
      expect(item.subtotal, 45000);
    });

    test('fromMap menolak harga atau jumlah tidak valid', () {
      expect(OrderItem.fromMap({'menuItemId': 'a', 'name': 'A'}), isNull);
      expect(
        OrderItem.fromMap({
          'menuItemId': 'a',
          'name': 'A',
          'price': 1000,
          'qty': 0,
        }),
        isNull,
      );
      expect(OrderItem.fromMap('bukan map'), isNull);
    });

    test('orderTotal menjumlah subtotal', () {
      const items = [
        OrderItem(menuItemId: 'a', name: 'A', price: 15000, qty: 2),
        OrderItem(menuItemId: 'b', name: 'B', price: 8000, qty: 1),
      ];
      expect(orderTotal(items), 38000);
      expect(orderTotal(const []), 0);
    });
  });

  group('FoodOrder.fromMap', () {
    test('membaca pesanan lengkap', () {
      final order = FoodOrder.fromMap('o1', _validOrderData());
      expect(order, isNotNull);
      expect(order!.id, 'o1');
      expect(order.customerName, 'Rian');
      expect(order.restaurantName, 'Mie Aceh Contoh');
      expect(order.items, hasLength(2));
      expect(order.total, 38000);
      expect(order.status, OrderStatus.pending);
      // Timestamp dibaca sebagai waktu lokal; yang dibandingkan momennya
      expect(
        order.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 17, 7, 5)),
        isTrue,
      );
      expect(order.paidAt, isNull);
    });

    test('createdAt kosong (menunggu waktu server) tetap terbaca', () {
      final data = _validOrderData()..['createdAt'] = null;
      expect(FoodOrder.fromMap('o1', data)!.createdAt, isNull);
    });

    test('status tidak dikenal, item rusak, atau tanpa item ditolak', () {
      expect(
        FoodOrder.fromMap('o', _validOrderData()..['status'] = 'kirim'),
        isNull,
      );
      expect(
        FoodOrder.fromMap(
          'o',
          _validOrderData()
            ..['items'] = [
              {'name': 'rusak'},
            ],
        ),
        isNull,
      );
      expect(FoodOrder.fromMap('o', _validOrderData()..['items'] = []), isNull);
    });

    test('label status dalam bahasa Indonesia', () {
      expect(OrderStatus.pending.label, 'Menunggu konfirmasi');
      expect(OrderStatus.paid.label, 'Sudah dibayar');
    });
  });

  group('sortNewestFirst', () {
    test('terbaru di atas, pesanan tanpa waktu dianggap paling baru', () {
      final sorted = sortNewestFirst([
        _orderAt('lama', DateTime(2026, 11, 1)),
        _orderAt('baru', DateTime(2026, 11, 17)),
        _orderAt('menunggu', null),
      ]);
      expect(sorted.map((o) => o.id), ['menunggu', 'baru', 'lama']);
    });
  });

  group('formatDateTime', () {
    test('format tanggal dan jam dengan nama bulan Indonesia', () {
      expect(
        formatDateTime(DateTime(2026, 11, 17, 14, 5)),
        '17 Nov 2026, 14.05',
      );
      expect(formatDateTime(DateTime(2026, 5, 3, 9, 0)), '3 Mei 2026, 09.00');
    });
  });
}
