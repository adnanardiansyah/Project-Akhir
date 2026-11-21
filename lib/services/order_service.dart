import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../models/restaurant.dart';
import 'firestore_write.dart';

// Akses data pesanan di koleksi orders
class OrderService {
  // Instance Firestore diambil saat dipakai agar layar bisa dites tanpa Firebase
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

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
    await waitForServerAck(
      doc.set({
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
      }),
    );
    return doc.id;
  }

  // Konfirmasi atau batal lewat transaksi; status dibaca ulang agar perubahan yang tidak sah ditolak
  Future<void> updateStatus(String orderId, OrderStatus next) {
    // Status dibayar wajib disertai data pembayaran, jadi tidak lewat jalur ini
    if (next == OrderStatus.paid) {
      throw ArgumentError('Pembayaran memakai jalur bayar tersendiri');
    }
    return _transition(orderId, next, {'status': next.name});
  }

  // Bayar simulasi lewat transaksi: hanya dari confirmed, status dan data bayar ditulis sekaligus
  Future<void> payOrder(String orderId, PaymentMethod method) {
    return _transition(orderId, OrderStatus.paid, {
      'status': OrderStatus.paid.name,
      'paymentMethod': method.name,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  // Transaksi bersama: baca status terkini, cek perpindahan, lalu tulis perubahan sekaligus
  Future<void> _transition(
    String orderId,
    OrderStatus next,
    Map<String, Object> changes,
  ) {
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      checkTransition(
        OrderStatus.values.asNameMap()[snapshot.data()?['status']],
        next,
      );
      transaction.update(ref, changes);
    });
  }

  // Aliran satu pesanan; null bila dokumen tidak ada atau tidak valid
  Stream<FoodOrder?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : FoodOrder.fromMap(doc.id, data);
    });
  }

  // Aliran pesanan milik pemesan, terbaru di atas
  Stream<List<FoodOrder>> watchCustomerOrders(String customerUid) =>
      _watchOrdersWhere('customerUid', customerUid);

  // Aliran pesanan untuk satu resto, terbaru di atas
  Stream<List<FoodOrder>> watchRestaurantOrders(String restaurantId) =>
      _watchOrdersWhere('restaurantId', restaurantId);

  // Pesanan dengan satu field sama dengan nilai; diurutkan di aplikasi agar tanpa indeks gabungan
  Stream<List<FoodOrder>> _watchOrdersWhere(String field, String value) {
    return _orders
        .where(field, isEqualTo: value)
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
