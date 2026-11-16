import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../widgets/order_card.dart';
import '../../widgets/stream_list_view.dart';
import '../shared/order_detail_screen.dart';

// Daftar pesanan milik pemesan, terbaru di atas
class MyOrdersScreen extends StatelessWidget {
  final AppUser user;
  final AppServices services;

  const MyOrdersScreen({super.key, required this.user, required this.services});

  // Membuka detail pesanan yang dipilih
  void _openOrder(BuildContext context, FoodOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          user: user,
          services: services,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: StreamListView<FoodOrder>(
        streamFactory: () => services.orders.watchCustomerOrders(user.uid),
        emptyIcon: Icons.receipt_long_outlined,
        emptyMessage: 'Belum ada pesanan',
        errorMessage: 'Pesanan gagal dimuat. Periksa koneksi internet.',
        itemBuilder: (context, order) => OrderCard(
          order: order,
          title: order.restaurantName,
          onTap: () => _openOrder(context, order),
        ),
      ),
    );
  }
}
