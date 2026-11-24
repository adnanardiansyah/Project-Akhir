import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_message.dart';
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
      backgroundColor: EmeraldColors.background,
      body: SafeArea(
        child: restaurantId == null
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
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                              children: [
                                _Header(
                                  name: widget.user.displayName,
                                  authService: widget.services.auth,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Ringkasan Pesanan',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: EmeraldColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) =>
                                      GridView.count(
                                        crossAxisCount:
                                            constraints.maxWidth >= 720 ? 4 : 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio:
                                            constraints.maxWidth >= 720
                                            ? 1.9
                                            : 1.25,
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
                                            color: EmeraldColors.warning,
                                          ),
                                          _RestaurantMetric(
                                            label: 'Dikonfirmasi',
                                            value:
                                                counts[_RestaurantOrderFilter
                                                    .processing]!,
                                            icon: Icons.restaurant_outlined,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          _RestaurantMetric(
                                            label: 'Sudah dibayar',
                                            value:
                                                counts[_RestaurantOrderFilter
                                                    .paid]!,
                                            icon: Icons.payments_outlined,
                                            color: EmeraldColors.success,
                                          ),
                                          _RestaurantMetric(
                                            label: 'Sudah diantar',
                                            value:
                                                counts[_RestaurantOrderFilter
                                                    .delivered]!,
                                            icon: Icons.task_alt_rounded,
                                            color: EmeraldColors.primary,
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
    return Container(
      decoration: BoxDecoration(
        color: EmeraldColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmeraldColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: EmeraldColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: EmeraldColors.textSecondary,
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
    final (title, message, color) = switch (status) {
      RestaurantReviewStatus.pending => (
        'Listing restoran menunggu tinjauan',
        'Admin akan menyetujui restoran sebelum muncul di katalog pemesan. '
            'Menu restoran perlu disiapkan melalui pengelola.',
        EmeraldColors.warning,
      ),
      RestaurantReviewStatus.rejected => (
        'Listing restoran ditolak',
        'Hubungi admin untuk mengetahui data yang perlu diperbaiki.',
        EmeraldColors.error,
      ),
      RestaurantReviewStatus.suspended => (
        'Listing restoran ditangguhkan',
        'Hubungi admin untuk mengaktifkan kembali restoran.',
        EmeraldColors.textSecondary,
      ),
      RestaurantReviewStatus.approved => ('', '', EmeraldColors.primary),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: EmeraldColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Banner resto modern di atas daftar pesanan
class _Header extends StatelessWidget {
  final String name;
  final AuthService authService;

  const _Header({required this.name, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EmeraldColors.primaryDeep, EmeraldColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: EmeraldColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel Restoran',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          LogoutButton(authService: authService),
        ],
      ),
    );
  }
}
