import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item.dart';
import '../models/restaurant.dart';

// Akses data resto dan menu di Firestore
class RestaurantService {
  // Instance Firestore diambil saat dipakai agar layar bisa dites tanpa Firebase
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Aliran daftar resto urut nama; dokumen tidak valid dilewati
  Stream<List<Restaurant>> watchRestaurants() {
    return _firestore
        .collection('restaurants')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Restaurant.fromMap(doc.id, doc.data()))
              .whereType<Restaurant>()
              .toList(),
        );
  }

  // Aliran menu satu resto urut nama; dokumen tidak valid dilewati
  Stream<List<MenuItem>> watchMenuItems(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menuItems')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
              .whereType<MenuItem>()
              .toList(),
        );
  }
}
