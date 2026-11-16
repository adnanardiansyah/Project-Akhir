import 'menu_item.dart';

// Satu baris keranjang: menu dan jumlahnya
class CartItem {
  final MenuItem menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  // Harga menu dikali jumlah
  int get subtotal => menuItem.price * quantity;

  // Salinan dengan jumlah baru
  CartItem withQuantity(int newQuantity) =>
      CartItem(menuItem: menuItem, quantity: newQuantity);
}
