import 'package:cloud_firestore/cloud_firestore.dart';

import 'field_parsers.dart';

// Data resto dari dokumen restaurants/{restaurantId}
class Restaurant {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String ownerUid;

  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.ownerUid,
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
    );
  }
}
