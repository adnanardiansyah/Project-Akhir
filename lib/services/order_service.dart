import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/restaurant.dart';

// Akses data pesanan di koleksi orders
class OrderService {
  // Instance Firestore diambil saat dipakai agar layar bisa dites tanpa Firebase
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  // Batas tunggu konfirmasi server; setelahnya Firestore tetap mengirim saat kembali online
  static const Duration _writeTimeout = Duration(seconds: 10);

  // Menulis pesanan baru berstatus pending dan mengembalikan id-nya
  Future<String> createOrder({
    required String customerUid,
    required String customerName,
    required Restaurant restaurant,
    required List<CartItem> cartItems,
  }) async {
    if (cartItems.isEmpty) {
      throw ArgumentError('Keranjang kosong');
    }
    final items = cartItems.map(OrderItem.fromCartItem).toList();
    // Id dibuat di perangkat agar pesanan bisa langsung dibuka walau koneksi lambat
    final doc = _orders.doc();
    await doc
        .set({
          'customerUid': customerUid,
          'customerName': customerName,
          'restaurantId': restaurant.id,
          'restaurantName': restaurant.name,
          'items': items.map((item) => item.toMap()).toList(),
          'total': orderTotal(items),
          'status': OrderStatus.pending.name,
          'paymentMethod': null,
          'createdAt': FieldValue.serverTimestamp(),
          'paidAt': null,
        })
        .timeout(_writeTimeout, onTimeout: () {});
    return doc.id;
  }

  // Aliran satu pesanan; null bila dokumen tidak ada atau tidak valid
  Stream<FoodOrder?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : FoodOrder.fromMap(doc.id, data);
    });
  }

  // Aliran pesanan milik pemesan, terbaru di atas; diurutkan di aplikasi agar tanpa indeks gabungan
  Stream<List<FoodOrder>> watchCustomerOrders(String customerUid) {
    return _orders
        .where('customerUid', isEqualTo: customerUid)
        .snapshots()
        .map(
          (snapshot) => sortNewestFirst(
            snapshot.docs
                .map((doc) => FoodOrder.fromMap(doc.id, doc.data()))
                .whereType<FoodOrder>(),
          ),
        );
  }
}

// Mengurutkan pesanan terbaru di atas; waktu kosong (baru dibuat) dianggap paling baru
List<FoodOrder> sortNewestFirst(Iterable<FoodOrder> orders) {
  final sorted = orders.toList();
  sorted.sort((a, b) {
    final aTime = a.createdAt, bTime = b.createdAt;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return -1;
    if (bTime == null) return 1;
    return bTime.compareTo(aTime);
  });
  return sorted;
}
