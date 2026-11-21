import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item.dart';
import 'field_parsers.dart';

// Status pesanan sesuai usulan U5
enum OrderStatus { pending, confirmed, paid, cancelled }

// Label status dalam bahasa Indonesia untuk tampilan
extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Menunggu konfirmasi',
    OrderStatus.confirmed => 'Dikonfirmasi resto',
    OrderStatus.paid => 'Sudah dibayar',
    OrderStatus.cancelled => 'Dibatalkan',
  };
}

// Aturan perpindahan status: pending -> confirmed/cancelled, confirmed -> paid/cancelled
extension OrderStatusTransition on OrderStatus {
  bool canTransitionTo(OrderStatus next) => switch ((this, next)) {
    (OrderStatus.pending, OrderStatus.confirmed) => true,
    (OrderStatus.pending, OrderStatus.cancelled) => true,
    (OrderStatus.confirmed, OrderStatus.paid) => true,
    (OrderStatus.confirmed, OrderStatus.cancelled) => true,
    _ => false,
  };
}

// Memastikan perpindahan sah; StateError berisi pesan yang siap ditampilkan bila tidak
void checkTransition(OrderStatus? current, OrderStatus next) {
  if (current == null) {
    throw StateError('Pesanan tidak ditemukan');
  }
  if (!current.canTransitionTo(next)) {
    throw StateError('Status pesanan sudah berubah. Coba lagi.');
  }
}

// Salinan satu menu di pesanan; nama dan harga dibekukan saat dipesan
class OrderItem {
  final String menuItemId;
  final String name;
  final int price;
  final int qty;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.qty,
  });

  // Membuat baris pesanan dari baris keranjang
  factory OrderItem.fromCartItem(CartItem item) => OrderItem(
    menuItemId: item.menuItem.id,
    name: item.menuItem.name,
    price: item.menuItem.price,
    qty: item.quantity,
  );

  int get subtotal => price * qty;

  // Bentuk data untuk disimpan di Firestore
  Map<String, dynamic> toMap() => {
    'menuItemId': menuItemId,
    'name': name,
    'price': price,
    'qty': qty,
  };

  // Membaca baris pesanan; null bila ada field yang tidak valid
  static OrderItem? fromMap(Object? data) {
    if (data is! Map) return null;
    final menuItemId = data['menuItemId'];
    final name = data['name'];
    final price = data['price'];
    final qty = data['qty'];
    if (menuItemId is! String || name is! String) return null;
    if (price is! int || price < 0 || qty is! int || qty <= 0) return null;
    return OrderItem(
      menuItemId: menuItemId,
      name: name,
      price: price,
      qty: qty,
    );
  }
}

// Total pesanan: jumlah subtotal semua baris
int orderTotal(Iterable<OrderItem> items) =>
    items.fold(0, (runningTotal, item) => runningTotal + item.subtotal);

// Data pesanan dari dokumen orders/{orderId}
class FoodOrder {
  final String id;
  final String customerUid;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final GeoPoint? deliveryLocation;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final String? paymentMethod;
  // Null sesaat setelah dibuat, sebelum waktu server tercatat
  final DateTime? createdAt;
  final DateTime? paidAt;

  const FoodOrder({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.restaurantId,
    required this.restaurantName,
    this.deliveryLocation,
    required this.items,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.createdAt,
    this.paidAt,
  });

  // Membaca pesanan dari Firestore; null bila field inti tidak valid
  static FoodOrder? fromMap(String id, Map<String, dynamic> data) {
    final customerUid = data['customerUid'];
    final restaurantId = data['restaurantId'];
    final total = data['total'];
    final rawItems = data['items'];
    final status = OrderStatus.values.asNameMap()[data['status']];
    if (customerUid is! String || restaurantId is! String) return null;
    if (total is! int || rawItems is! List || status == null) return null;
    final items = rawItems.map(OrderItem.fromMap).toList();
    if (items.isEmpty || items.contains(null)) return null;
    return FoodOrder(
      id: id,
      customerUid: customerUid,
      customerName: stringOrEmpty(data['customerName']),
      restaurantId: restaurantId,
      restaurantName: stringOrEmpty(data['restaurantName']),
      deliveryLocation: data['deliveryLocation'] is GeoPoint
          ? data['deliveryLocation'] as GeoPoint
          : null,
      items: items.whereType<OrderItem>().toList(),
      total: total,
      status: status,
      paymentMethod: stringOrNull(data['paymentMethod']),
      createdAt: _dateOrNull(data['createdAt']),
      paidAt: _dateOrNull(data['paidAt']),
    );
  }

  static DateTime? _dateOrNull(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
