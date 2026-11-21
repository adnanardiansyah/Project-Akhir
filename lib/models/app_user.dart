// Peran pengguna di aplikasi
enum UserRole { customer, restaurant, courier, admin }

// Profil pengguna dari dokumen users/{uid}
class AppUser {
  final String uid;
  final UserRole role;
  final String displayName;
  final String? restaurantId;

  const AppUser({
    required this.uid,
    required this.role,
    required this.displayName,
    this.restaurantId,
  });

  // Membuat AppUser dari data Firestore; peran tak dikenal dianggap null
  static AppUser? fromMap(String uid, Map<String, dynamic> data) {
    final role = switch (data['role']) {
      'customer' => UserRole.customer,
      'restaurant' => UserRole.restaurant,
      'courier' => UserRole.courier,
      'admin' => UserRole.admin,
      _ => null,
    };
    if (role == null) return null;
    return AppUser(
      uid: uid,
      role: role,
      displayName: (data['displayName'] as String?) ?? '',
      restaurantId: data['restaurantId'] as String?,
    );
  }
}
