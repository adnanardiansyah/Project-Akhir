import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

// Keranjang di memori untuk satu resto; memberi tahu tampilan setiap ada perubahan
class CartController extends ChangeNotifier {
  Restaurant? _restaurant;
  // Map bawaan Dart menjaga urutan menu sesuai saat ditambahkan
  final Map<String, CartItem> _items = {};
  DateTime? _orderSubmissionStartedAt;

  // Resto asal isi keranjang; null bila keranjang kosong
  Restaurant? get restaurant => _restaurant;

  List<CartItem> get items => List.unmodifiable(_items.values);

  bool get isEmpty => _items.isEmpty;

  bool get isSubmittingOrder => _orderSubmissionStartedAt != null;

  DateTime? get orderSubmissionStartedAt => _orderSubmissionStartedAt;

  // Jumlah semua porsi di keranjang
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  // Total harga dari semua baris keranjang
  int get total => _items.values.fold(0, (sum, item) => sum + item.subtotal);

  // Jumlah porsi satu menu; 0 bila belum ada di keranjang
  int quantityOf(String menuItemId) => _items[menuItemId]?.quantity ?? 0;

  // Benar bila menu dari resto ini boleh masuk tanpa mengganti keranjang
  bool canAddFrom(Restaurant restaurant) =>
      _restaurant == null || _restaurant!.id == restaurant.id;

  // Mengunci keranjang selama satu penulisan pesanan menunggu konfirmasi server.
  bool beginOrderSubmission() {
    if (isSubmittingOrder || isEmpty || _restaurant == null) return false;
    _orderSubmissionStartedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  // Sukses mengosongkan keranjang; kegagalan melepas kunci agar bisa dicoba lagi.
  void finishOrderSubmission({required bool succeeded}) {
    if (!isSubmittingOrder) return;
    if (succeeded) {
      _items.clear();
      _restaurant = null;
    }
    _orderSubmissionStartedAt = null;
    notifyListeners();
  }

  // Menambah satu porsi; menu dari resto lain ditolak agar satu pesanan satu resto
  void add(Restaurant restaurant, MenuItem menuItem) {
    if (isSubmittingOrder) {
      throw StateError('Pesanan sedang dikirim');
    }
    if (!canAddFrom(restaurant)) {
      throw StateError('Keranjang berisi menu dari resto lain');
    }
    _restaurant = restaurant;
    final current = _items[menuItem.id];
    _items[menuItem.id] = current == null
        ? CartItem(menuItem: menuItem, quantity: 1)
        : current.withQuantity(current.quantity + 1);
    notifyListeners();
  }

  // Mengosongkan keranjang lalu menambah menu dari resto baru
  void replaceWith(Restaurant restaurant, MenuItem menuItem) {
    if (isSubmittingOrder) {
      throw StateError('Pesanan sedang dikirim');
    }
    _items.clear();
    _restaurant = null;
    add(restaurant, menuItem);
  }

  // Mengurangi satu porsi; baris dihapus bila jumlahnya habis
  void decrement(String menuItemId) {
    if (isSubmittingOrder) return;
    final current = _items[menuItemId];
    if (current == null) return;
    if (current.quantity <= 1) {
      _items.remove(menuItemId);
    } else {
      _items[menuItemId] = current.withQuantity(current.quantity - 1);
    }
    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }

  // Mengosongkan keranjang, misalnya setelah pesanan dibuat
  void clear() {
    if (isSubmittingOrder) return;
    if (_items.isEmpty && _restaurant == null) return;
    _items.clear();
    _restaurant = null;
    notifyListeners();
  }
}
