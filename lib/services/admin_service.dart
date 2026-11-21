import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import '../models/restaurant.dart';
import 'order_service.dart';

// Akses dashboard, tinjauan resto, dan pemantauan pesanan admin.
class AdminService {
  const AdminService();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _restaurants =>
      _firestore.collection('restaurants');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  // Admin melihat semua resto, termasuk yang belum disetujui.
  Stream<List<Restaurant>> watchRestaurants() {
    return _restaurants.orderBy('name').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Restaurant.fromMap(doc.id, doc.data()))
          .whereType<Restaurant>()
          .toList(),
    );
  }

  // Admin memantau semua pesanan untuk ringkasan status dan daftar terbaru.
  Stream<List<FoodOrder>> watchOrders() {
    return _orders.snapshots().map(
      (snapshot) => sortNewestFirst(
        snapshot.docs
            .map((doc) => FoodOrder.fromMap(doc.id, doc.data()))
            .whereType<FoodOrder>(),
      ),
    );
  }

  // Menyimpan keputusan admin dan jejak akun/waktu peninjauan.
  Future<void> reviewRestaurant({
    required String restaurantId,
    required RestaurantReviewStatus status,
    required String adminUid,
  }) {
    return _restaurants.doc(restaurantId).update({
      'reviewStatus': status.name,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
