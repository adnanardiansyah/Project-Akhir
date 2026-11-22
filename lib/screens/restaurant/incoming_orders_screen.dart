import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_message.dart';
import '../../widgets/stream_list_view.dart';
import '../../widgets/welcome_banner.dart';
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
          : Column(
              children: [
                StreamBuilder<Restaurant?>(
                  stream: services.restaurants.watchRestaurant(restaurantId),
                  builder: (context, snapshot) {
                    final restaurant = snapshot.data;
                    if (restaurant == null ||
                        restaurant.reviewStatus ==
                            RestaurantReviewStatus.approved) {
                      return const SizedBox.shrink();
                    }
                    return _RestaurantReviewNotice(
                      status: restaurant.reviewStatus,
                    );
                  },
                ),
                Expanded(
                  child: StreamListView<FoodOrder>(
                    streamFactory: () =>
                        services.orders.watchRestaurantOrders(restaurantId),
                    emptyIcon: Icons.receipt_long_outlined,
                    emptyMessage:
                        'Belum ada pesanan masuk untuk ${user.displayName}',
                    errorMessage:
                        'Pesanan gagal dimuat. Periksa koneksi atau akses Firestore.',
                    header: _Header(name: user.displayName),
                    itemBuilder: (context, order) => OrderCard(
                      order: order,
                      title: order.customerName,
                      onTap: () => _openOrder(context, order),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RestaurantReviewNotice extends StatelessWidget {
  final RestaurantReviewStatus status;

  const _RestaurantReviewNotice({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (title, message, color) = switch (status) {
      RestaurantReviewStatus.pending => (
        'Listing restoran menunggu tinjauan',
        'Admin akan menyetujui restoran sebelum muncul di katalog pemesan. '
            'Menu restoran perlu disiapkan melalui pengelola.',
        const Color(0xFFB45309),
      ),
      RestaurantReviewStatus.rejected => (
        'Listing restoran ditolak',
        'Hubungi admin untuk mengetahui data yang perlu diperbaiki.',
        scheme.error,
      ),
      RestaurantReviewStatus.suspended => (
        'Listing restoran ditangguhkan',
        'Hubungi admin untuk mengaktifkan kembali restoran.',
        scheme.onSurfaceVariant,
      ),
      RestaurantReviewStatus.approved => ('', '', scheme.primary),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Banner resto di atas daftar pesanan.
class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WelcomeBanner(
        eyebrow: 'Panel resto',
        title: name,
        subtitle: 'Pantau pesanan dan chat pelanggan di sini.',
        icon: Icons.storefront_rounded,
      ),
    );
  }
}
