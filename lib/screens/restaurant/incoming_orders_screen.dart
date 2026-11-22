import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_message.dart';
import '../../widgets/welcome_banner.dart';
import '../shared/order_detail_screen.dart';

enum _RestaurantOrderFilter {
  all,
  newOrders,
  processing,
  paid,
  delivered,
  cancelled,
}

extension on _RestaurantOrderFilter {
  String get label => switch (this) {
    _RestaurantOrderFilter.all => 'Semua',
    _RestaurantOrderFilter.newOrders => 'Baru',
    _RestaurantOrderFilter.processing => 'Diproses',
    _RestaurantOrderFilter.paid => 'Sudah dibayar',
    _RestaurantOrderFilter.delivered => 'Selesai',
    _RestaurantOrderFilter.cancelled => 'Dibatalkan',
  };

  bool matches(FoodOrder order) => switch (this) {
    _RestaurantOrderFilter.all => true,
    _RestaurantOrderFilter.newOrders => order.status == OrderStatus.pending,
    _RestaurantOrderFilter.processing => order.status == OrderStatus.confirmed,
    _RestaurantOrderFilter.paid =>
      order.status == OrderStatus.paid &&
          order.deliveryStatus != DeliveryStatus.delivered,
    _RestaurantOrderFilter.delivered =>
      order.deliveryStatus == DeliveryStatus.delivered,
    _RestaurantOrderFilter.cancelled => order.status == OrderStatus.cancelled,
  };

  int count(Iterable<FoodOrder> orders) => orders.where(matches).length;
}

// Beranda resto: pesanan masuk untuk resto miliknya saja, realtime
class IncomingOrdersScreen extends StatefulWidget {
  final AppUser user;
  final AppServices services;

  const IncomingOrdersScreen({
    super.key,
    required this.user,
    required this.services,
  });

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _RestaurantOrderFilter _filter = _RestaurantOrderFilter.all;
  Stream<List<FoodOrder>>? _orders;

  @override
  void initState() {
    super.initState();
    final restaurantId = widget.user.restaurantId;
    if (restaurantId != null) {
      _orders = widget.services.orders.watchRestaurantOrders(restaurantId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Membuka rincian, tindakan pesanan, dan chat pemesan.
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

  @override
  Widget build(BuildContext context) {
    final restaurantId = widget.user.restaurantId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        actions: [LogoutButton(authService: widget.services.auth)],
      ),
      body: restaurantId == null
          ? const StateMessage(
              icon: Icons.link_off_rounded,
              title: 'Akun belum terhubung ke resto',
              message: 'Hubungi pengelola aplikasi untuk mengisi restaurantId.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  children: [
                    StreamBuilder<Restaurant?>(
                      stream: widget.services.restaurants.watchRestaurant(
                        restaurantId,
                      ),
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
                      child: StreamBuilder<List<FoodOrder>>(
                        stream: _orders,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const StateMessage(
                              icon: Icons.wifi_off_rounded,
                              title: 'Pesanan gagal dimuat',
                              message:
                                  'Periksa koneksi atau akses Firestore, lalu coba lagi.',
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final orders = snapshot.data ?? const <FoodOrder>[];
                          final counts = {
                            for (final filter in _RestaurantOrderFilter.values)
                              filter: filter.count(orders),
                          };
                          final query = _query.trim().toLowerCase();
                          final visible = orders.where((order) {
                            final matchesQuery =
                                query.isEmpty ||
                                order.customerName.toLowerCase().contains(
                                  query,
                                ) ||
                                order.id.toLowerCase().contains(query);
                            return matchesQuery && _filter.matches(order);
                          }).toList();

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                            children: [
                              _Header(name: widget.user.displayName),
                              const SizedBox(height: 18),
                              Text(
                                'Ringkasan pesanan',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (context, constraints) =>
                                    GridView.count(
                                      crossAxisCount:
                                          constraints.maxWidth >= 720 ? 4 : 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio:
                                          constraints.maxWidth >= 720
                                          ? 2.5
                                          : 1.8,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                        _RestaurantMetric(
                                          label: 'Pesanan baru',
                                          value:
                                              counts[_RestaurantOrderFilter
                                                  .newOrders]!,
                                          icon: Icons
                                              .notifications_active_outlined,
                                          color: const Color(0xFFB45309),
                                        ),
                                        _RestaurantMetric(
                                          label: 'Dikonfirmasi',
                                          value:
                                              counts[_RestaurantOrderFilter
                                                  .processing]!,
                                          icon: Icons.restaurant_outlined,
                                          color: const Color(0xFF2563A6),
                                        ),
                                        _RestaurantMetric(
                                          label: 'Sudah dibayar',
                                          value:
                                              counts[_RestaurantOrderFilter
                                                  .paid]!,
                                          icon: Icons.payments_outlined,
                                          color: successGreen,
                                        ),
                                        _RestaurantMetric(
                                          label: 'Sudah diantar',
                                          value:
                                              counts[_RestaurantOrderFilter
                                                  .delivered]!,
                                          icon: Icons.task_alt_rounded,
                                          color: successGreen,
                                        ),
                                      ],
                                    ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Cari nama pemesan atau ID pesanan',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Hapus pencarian',
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _query = '');
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final filter
                                        in _RestaurantOrderFilter.values) ...[
                                      ChoiceChip(
                                        label: Text(
                                          '${filter.label} (${counts[filter]})',
                                        ),
                                        selected: _filter == filter,
                                        onSelected: (_) =>
                                            setState(() => _filter = filter),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pesanan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buka pesanan untuk melihat rincian, mengonfirmasi, atau chat dengan pemesan.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              if (visible.isEmpty)
                                StateMessage(
                                  icon: Icons.receipt_long_outlined,
                                  title: orders.isEmpty
                                      ? 'Belum ada pesanan'
                                      : 'Pesanan tidak ditemukan',
                                  message: orders.isEmpty
                                      ? 'Pesanan baru akan muncul di sini secara langsung.'
                                      : 'Ubah kata pencarian atau filter status.',
                                )
                              else
                                for (final order in visible)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: OrderCard(
                                      order: order,
                                      title: order.customerName,
                                      onTap: () => _openOrder(context, order),
                                    ),
                                  ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RestaurantMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _RestaurantMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                Text(message, style: TextStyle(color: scheme.onSurfaceVariant)),
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
