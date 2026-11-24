import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../widgets/order_card.dart';
import '../../widgets/stream_list_view.dart';
import '../shared/order_detail_screen.dart';

// Daftar pesanan milik pemesan, terbaru di atas dan diperbarui langsung dari Firestore
class MyOrdersScreen extends StatefulWidget {
  final AppUser user;
  final AppServices services;

  const MyOrdersScreen({super.key, required this.user, required this.services});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int _refreshToken = 0;

  // Membuka detail pesanan yang dipilih
  void _openOrder(BuildContext context, FoodOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          user: widget.user,
          services: widget.services,
        ),
      ),
    );
  }

  // Tarik ke bawah meminta aliran Firestore baru tanpa menunggu snapshot berikutnya
  Future<void> _refresh() async {
    setState(() => _refreshToken++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: _refresh,
        child: StreamListView<FoodOrder>(
          key: ValueKey(_refreshToken),
          streamFactory: () =>
              widget.services.orders.watchCustomerOrders(widget.user.uid),
          refreshToken: _refreshToken,
          emptyIcon: Icons.receipt_long_outlined,
          emptyMessage: 'Belum ada pesanan',
          errorMessage:
              'Pesanan gagal dimuat. Periksa koneksi atau akses Firestore.',
          itemBuilder: (context, order) => OrderCard(
            order: order,
            title: order.restaurantName,
            onTap: () => _openOrder(context, order),
          ),
        ),
      ),
    );
  }
}
