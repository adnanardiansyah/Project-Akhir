import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/partner_application.dart';
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

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('partnerApplications');

  // Admin melihat semua resto, termasuk yang belum disetujui.
  Stream<List<Restaurant>> watchRestaurants() {
    return _restaurants
        .orderBy('name')
        .snapshots()
        .map(
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

  // Daftar akun kurir yang dapat dipilih admin saat menugaskan pesanan.
  Stream<List<AppUser>> watchCouriers() {
    return _users
        .where('role', isEqualTo: 'courier')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.id, doc.data()))
              .whereType<AppUser>()
              .toList(),
        );
  }

  // Jumlah akun pemesan untuk ringkasan dashboard admin.
  Stream<List<AppUser>> watchCustomers() {
    return _users
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.id, doc.data()))
              .whereType<AppUser>()
              .toList(),
        );
  }

  Stream<List<PartnerApplication>> watchPartnerApplications() {
    return _applications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PartnerApplication.fromMap(doc.id, doc.data()))
              .whereType<PartnerApplication>()
              .toList(),
        );
  }

  Future<void> reviewPartnerApplication({
    required PartnerApplication application,
    required PartnerApplicationStatus status,
    required String adminUid,
    String rejectionReason = '',
  }) async {
    if (status == PartnerApplicationStatus.pending) {
      throw ArgumentError.value(
        status,
        'status',
        'Status tinjauan tidak valid',
      );
    }

    final applicationRef = _applications.doc(application.applicantUid);
    final userRef = _users.doc(application.applicantUid);
    final restaurantRef = _restaurants.doc(application.applicantUid);
    await _firestore.runTransaction((transaction) async {
      final applicationSnapshot = await transaction.get(applicationRef);
      final userSnapshot = await transaction.get(userRef);
      final restaurantSnapshot =
          application.type == PartnerApplicationType.restaurant
          ? await transaction.get(restaurantRef)
          : null;
      final data = applicationSnapshot.data();
      final current = data == null
          ? null
          : PartnerApplication.fromMap(application.applicantUid, data);

      if (current == null ||
          current.status != PartnerApplicationStatus.pending ||
          current.type != application.type) {
        throw StateError('Pengajuan sudah ditinjau atau tidak ditemukan.');
      }
      if (!userSnapshot.exists || userSnapshot.data()?['role'] != 'customer') {
        throw StateError(
          'Profil calon mitra tidak tersedia atau sudah berubah.',
        );
      }

      if (status == PartnerApplicationStatus.approved &&
          current.type == PartnerApplicationType.restaurant &&
          restaurantSnapshot!.exists) {
        throw StateError('Dokumen restoran untuk akun ini sudah tersedia.');
      }

      transaction.update(applicationRef, {
        'status': status.name,
        'reviewedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': status == PartnerApplicationStatus.rejected
            ? rejectionReason.trim()
            : null,
      });

      if (status != PartnerApplicationStatus.approved) return;

      if (current.type == PartnerApplicationType.courier) {
        transaction.update(userRef, {'role': 'courier'});
        return;
      }

      transaction.update(userRef, {
        'role': 'restaurant',
        'restaurantId': current.applicantUid,
      });
      transaction.set(restaurantRef, {
        'name': current.restaurantName,
        'address': current.address,
        'location': current.location,
        'ownerUid': current.applicantUid,
        'reviewStatus': 'pending',
        'reviewedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
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
