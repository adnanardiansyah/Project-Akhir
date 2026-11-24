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
    required GeoPoint deliveryLocation,
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
        'deliveryLocation': deliveryLocation,
        'items': items.map((item) => item.toMap()).toList(),
        'total': orderTotal(items),
        'status': OrderStatus.pending.name,
        'paymentMethod': null,
        'paymentStatus': PaymentStatus.unpaid.name,
        'createdAt': FieldValue.serverTimestamp(),
        'paidAt': null,
        'codCollectedByUid': null,
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
    if (method == PaymentMethod.cod) {
      throw ArgumentError('COD tidak dibayar di layar pembayaran');
    }
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final data = (await transaction.get(ref)).data();
      if (data == null ||
          data['status'] != OrderStatus.confirmed.name ||
          data['paymentMethod'] != null ||
          data['paymentStatus'] == PaymentStatus.paid.name ||
          data['deliveryStatus'] != null) {
        throw StateError('Pembayaran hanya bisa pada pesanan dikonfirmasi.');
      }
      checkTransition(OrderStatus.confirmed, OrderStatus.paid);
      transaction.update(ref, {
        'status': OrderStatus.paid.name,
        'paymentMethod': method.name,
        'paymentStatus': PaymentStatus.paid.name,
        'paidAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Memilih COD tidak mengubah status; uang diterima kurir saat pengantaran selesai
  Future<void> chooseCodPayment(String orderId) {
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null ||
          data['status'] != OrderStatus.confirmed.name ||
          data['paymentMethod'] != null ||
          data['paymentStatus'] == PaymentStatus.paid.name) {
        throw StateError(
          'Metode COD hanya bisa dipilih pada pesanan dikonfirmasi.',
        );
      }
      transaction.update(ref, {
        'paymentMethod': PaymentMethod.cod.name,
        'paymentStatus': PaymentStatus.unpaid.name,
        'paidAt': null,
      });
    });
  }

  // Admin menugaskan pesanan lunas atau COD yang siap dikirim.
  Future<void> assignCourier({
    required String orderId,
    required String courierUid,
    required String courierName,
  }) {
    return _orders.doc(orderId).update({
      'assignedCourierUid': courierUid,
      'assignedCourierName': courierName,
      'deliveryStatus': DeliveryStatus.assigned.name,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  // Kurir memulai pengantaran setelah admin menugaskan pesanan.
  Future<void> startCourierDelivery(String orderId, String courierUid) {
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      final readyForCourier =
          data != null &&
          (data['status'] == OrderStatus.paid.name ||
              (isCodMethodName(data['paymentMethod'] as String?) &&
                  data['status'] == OrderStatus.confirmed.name &&
                  data['paymentStatus'] != PaymentStatus.paid.name));
      if (data == null ||
          data['assignedCourierUid'] != courierUid ||
          data['deliveryStatus'] != DeliveryStatus.assigned.name ||
          !readyForCourier) {
        throw StateError('Pesanan ini belum siap untuk diantar.');
      }
      transaction.update(ref, {
        'deliveryStatus': DeliveryStatus.inTransit.name,
        'deliveryStartedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Lokasi terbaru hanya dikirim oleh kurir yang sedang ditugaskan.
  Future<void> updateCourierLocation(String orderId, GeoPoint location) {
    return _orders.doc(orderId).update({
      'courierLocation': location,
      'courierLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Kurir menandai pengantaran selesai.
  Future<void> completeCourierDelivery(String orderId, String courierUid) {
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null ||
          data['assignedCourierUid'] != courierUid ||
          data['deliveryStatus'] != DeliveryStatus.inTransit.name) {
        throw StateError('Pengantaran ini tidak sedang berjalan.');
      }
      if (isCodMethodName(data['paymentMethod'] as String?)) {
        throw StateError(
          'COD harus diselesaikan lewat tombol terima pembayaran.',
        );
      }
      transaction.update(ref, {
        'deliveryStatus': DeliveryStatus.delivered.name,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // COD: kurir menandai selesai sekaligus mencatat uang yang diterima.
  Future<void> collectCodPayment(String orderId, String courierUid) {
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null ||
          data['assignedCourierUid'] != courierUid ||
          data['deliveryStatus'] != DeliveryStatus.inTransit.name ||
          !isCodMethodName(data['paymentMethod'] as String?) ||
          data['paymentStatus'] == PaymentStatus.paid.name) {
        throw StateError('Pembayaran COD ini tidak siap diterima.');
      }
      transaction.update(ref, {
        'deliveryStatus': DeliveryStatus.delivered.name,
        'deliveredAt': FieldValue.serverTimestamp(),
        'status': OrderStatus.paid.name,
        'paymentStatus': PaymentStatus.paid.name,
        'paymentMethod': PaymentMethod.cod.name,
        'paidAt': FieldValue.serverTimestamp(),
        'codCollectedByUid': courierUid,
      });
    });
  }

  // Deteksi tiba otomatis memakai transaksi yang sama dengan penyelesaian manual.
  Future<void> autoArrive(String orderId, String courierUid) {
    final ref = _orders.doc(orderId);
    return _firestore.runTransaction((transaction) async {
      final data = (await transaction.get(ref)).data();
      if (data == null ||
          data['assignedCourierUid'] != courierUid ||
          data['deliveryStatus'] != DeliveryStatus.inTransit.name) {
        throw StateError('Pengantaran ini tidak sedang berjalan.');
      }
      if (isCodMethodName(data['paymentMethod'] as String?)) {
        throw StateError('COD wajib dikonfirmasi kurir setelah uang diterima.');
      }
      if (data['status'] != OrderStatus.paid.name) {
        throw StateError('Pesanan belum lunas.');
      }
      transaction.update(ref, {
        'deliveryStatus': DeliveryStatus.delivered.name,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
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

  // Kurir hanya menerima pesanan yang ditugaskan ke UID miliknya.
  Stream<List<FoodOrder>> watchCourierOrders(String courierUid) =>
      _watchOrdersWhere('assignedCourierUid', courierUid);

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
