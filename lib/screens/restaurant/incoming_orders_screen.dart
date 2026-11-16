import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_message.dart';
import '../../widgets/stream_list_view.dart';
import '../shared/order_detail_screen.dart';

// Beranda resto: pesanan masuk untuk resto miliknya saja, realtime
class IncomingOrdersScreen extends StatelessWidget {
  final AppUser user;
  final AppServices services;

  const IncomingOrdersScreen({
    super.key,
    required this.user,
    required this.services,
  });

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
    final restaurantId = user.restaurantId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        actions: [LogoutButton(authService: services.auth)],
      ),
      body: restaurantId == null
          ? const StateMessage(
              icon: Icons.link_off_rounded,
              title: 'Akun belum terhubung ke resto',
              message: 'Hubungi pengelola aplikasi untuk mengisi restaurantId.',
            )
          : StreamListView<FoodOrder>(
              streamFactory: () =>
                  services.orders.watchRestaurantOrders(restaurantId),
              emptyIcon: Icons.receipt_long_outlined,
              emptyMessage: 'Belum ada pesanan masuk',
              errorMessage: 'Pesanan gagal dimuat. Periksa koneksi internet.',
              header: _Header(name: user.displayName),
              itemBuilder: (context, order) => OrderCard(
                order: order,
                title: order.customerName,
                onTap: () => _openOrder(context, order),
              ),
            ),
    );
  }
}

// Nama resto di atas daftar pesanan
class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resto',
            style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(name, style: text.headlineMedium),
        ],
      ),
    );
  }
}
