// Data menu dari dokumen restaurants/{restaurantId}/menuItems/{itemId}
class MenuItem {
  final String id;
  final String name;
  final int price;

  const MenuItem({required this.id, required this.name, required this.price});

  // Membuat MenuItem dari data Firestore; null bila nama atau harga tidak valid
  static MenuItem? fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    final price = data['price'];
    if (name is! String || name.trim().isEmpty) return null;
    // Harga dari Console bisa tersimpan sebagai double; hanya bilangan bulat terhingga >= 0 diterima
    if (price is! num ||
        !price.isFinite ||
        price < 0 ||
        price != price.roundToDouble()) {
      return null;
    }
    return MenuItem(id: id, name: name, price: price.toInt());
  }
}
