import 'package:cloud_firestore/cloud_firestore.dart';

import 'field_parsers.dart';

// Status hasil peninjauan admin terhadap data resto.
enum RestaurantReviewStatus { pending, approved, rejected, suspended }

extension RestaurantReviewStatusLabel on RestaurantReviewStatus {
  String get label => switch (this) {
    RestaurantReviewStatus.pending => 'Perlu ditinjau',
    RestaurantReviewStatus.approved => 'Disetujui',
    RestaurantReviewStatus.rejected => 'Ditolak',
    RestaurantReviewStatus.suspended => 'Ditangguhkan',
  };
}

// Data resto dari dokumen restaurants/{restaurantId}
class Restaurant {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String ownerUid;
  final RestaurantReviewStatus reviewStatus;

  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.ownerUid,
    this.reviewStatus = RestaurantReviewStatus.pending,
  });

  // Membuat Restaurant dari data Firestore; null bila nama atau lokasi tidak ada
  static Restaurant? fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    final location = data['location'];
    if (name is! String || name.trim().isEmpty || location is! GeoPoint) {
      return null;
    }
    return Restaurant(
      id: id,
      name: name,
      address: stringOrEmpty(data['address']),
      location: location,
      ownerUid: stringOrEmpty(data['ownerUid']),
      reviewStatus:
          RestaurantReviewStatus.values.asNameMap()[data['reviewStatus']] ??
          RestaurantReviewStatus.pending,
    );
  }
}
