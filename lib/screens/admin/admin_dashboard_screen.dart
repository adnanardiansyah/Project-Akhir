import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import 'partner_applications_tab.dart';
import '../../utils/format_date_time.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/courier_tracking_map.dart';
import '../../widgets/order_filter_bar.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/state_message.dart';
import '../../widgets/welcome_banner.dart';

// Dashboard admin untuk ringkasan, tinjauan resto, dan pemantauan pesanan.
class AdminDashboardScreen extends StatelessWidget {
  final AppUser user;
  final AppServices services;

  const AdminDashboardScreen({
    super.key,
    required this.user,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Admin'),
          actions: [LogoutButton(authService: services.auth)],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Ringkasan'),
              Tab(icon: Icon(Icons.storefront_outlined), text: 'Resto'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Pesanan'),
              Tab(icon: Icon(Icons.group_add_outlined), text: 'Pengajuan'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: TabBarView(
              children: [
                _AdminOverviewTab(user: user, services: services),
                _RestaurantReviewTab(user: user, services: services),
                _OrderMonitoringTab(services: services),
                PartnerApplicationsTab(user: user, services: services),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminOverviewTab extends StatefulWidget {
  final AppUser user;
  final AppServices services;

  const _AdminOverviewTab({required this.user, required this.services});

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  late final _restaurants = widget.services.admin.watchRestaurants();
  late final _orders = widget.services.admin.watchOrders();
  late final _couriers = widget.services.admin.watchCouriers();
  late final _customers = widget.services.admin.watchCustomers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: _restaurants,
      builder: (context, restaurantSnapshot) {
        if (restaurantSnapshot.hasError) {
          return const _AdminStreamError(kind: 'ringkasan resto');
        }
        if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<FoodOrder>>(
          stream: _orders,
          builder: (context, orderSnapshot) {
            if (orderSnapshot.hasError) {
              return const _AdminStreamError(kind: 'ringkasan pesanan');
            }
            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<List<AppUser>>(
              stream: _couriers,
              builder: (context, courierSnapshot) {
                if (courierSnapshot.hasError) {
                  return const _AdminStreamError(kind: 'daftar kurir');
                }
                if (courierSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<AppUser>>(
                  stream: _customers,
                  builder: (context, customerSnapshot) {
                    if (customerSnapshot.hasError) {
                      return const _AdminStreamError(kind: 'daftar customer');
                    }
                    if (customerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final restaurants = restaurantSnapshot.data ?? const [];
                    final orders = orderSnapshot.data ?? const [];
                    final couriers = courierSnapshot.data ?? const <AppUser>[];
                    final customers =
                        customerSnapshot.data ?? const <AppUser>[];
                    final pendingRestaurants = restaurants
                        .where(
                          (restaurant) =>
                              restaurant.reviewStatus ==
                              RestaurantReviewStatus.pending,
                        )
                        .length;
                    final approvedRestaurants = restaurants
                        .where(
                          (restaurant) =>
                              restaurant.reviewStatus ==
                              RestaurantReviewStatus.approved,
                        )
                        .length;
                    final ordersNeedingCourier = orders
                        .where(
                          (order) =>
                              order.status == OrderStatus.paid &&
                              order.assignedCourierUid == null,
                        )
                        .length;
                    final inTransit = orders
                        .where(
                          (order) =>
                              order.deliveryStatus == DeliveryStatus.inTransit,
                        )
                        .length;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        WelcomeBanner(
                          eyebrow: 'Monitoring aplikasi',
                          title: 'Halo, ${widget.user.displayName}',
                          subtitle:
                              'Tinjauan resto, pesanan, dan pengantaran dalam satu panel.',
                          icon: Icons.admin_panel_settings_rounded,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ringkasan operasional',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) => GridView.count(
                            crossAxisCount: constraints.maxWidth >= 1000
                                ? 4
                                : constraints.maxWidth >= 620
                                ? 3
                                : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: constraints.maxWidth >= 1000
                                ? 3.0
                                : constraints.maxWidth >= 620
                                ? 1.7
                                : 1.35,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _DashboardMetric(
                                label: 'Resto perlu ditinjau',
                                value: pendingRestaurants,
                                icon: Icons.rate_review_outlined,
                                color: const Color(0xFFB45309),
                              ),
                              _DashboardMetric(
                                label: 'Resto disetujui',
                                value: approvedRestaurants,
                                icon: Icons.storefront_rounded,
                                color: brandGreen,
                              ),
                              _DashboardMetric(
                                label: 'Akun customer',
                                value: customers.length,
                                icon: Icons.people_alt_outlined,
                                color: const Color(0xFF7C3AED),
                              ),
                              _DashboardMetric(
                                label: 'Akun kurir',
                                value: couriers.length,
                                icon: Icons.delivery_dining_rounded,
                                color: brandGreen,
                              ),
                              _DashboardMetric(
                                label: 'Total pesanan',
                                value: orders.length,
                                icon: Icons.receipt_long_outlined,
                                color: const Color(0xFF2563A6),
                              ),
                              _DashboardMetric(
                                label: 'Menunggu kurir',
                                value: ordersNeedingCourier,
                                icon: Icons.person_search_outlined,
                                color: const Color(0xFFB45309),
                              ),
                              _DashboardMetric(
                                label: 'Sedang diantar',
                                value: inTransit,
                                icon: Icons.route_outlined,
                                color: successGreen,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _OrderStatusBreakdown(orders: orders),
                        const SizedBox(height: 24),
                        Text(
                          'Pesanan terbaru',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (orders.isEmpty)
                          const _InlineEmpty(
                            icon: Icons.receipt_long_outlined,
                            message: 'Belum ada pesanan untuk dipantau.',
                          )
                        else
                          for (final order in orders.take(5))
                            _AdminOrderCard(
                              order: order,
                              services: widget.services,
                              allowCourierAssignment: false,
                            ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: text.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusBreakdown extends StatelessWidget {
  final List<FoodOrder> orders;

  const _OrderStatusBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = {
      OrderStatus.pending: const Color(0xFFB45309),
      OrderStatus.confirmed: const Color(0xFF2563A6),
      OrderStatus.paid: successGreen,
      OrderStatus.cancelled: scheme.error,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Status pesanan', style: text.titleMedium),
                ),
                Text('${orders.length} total', style: text.labelMedium),
              ],
            ),
            const SizedBox(height: 14),
            for (final status in OrderStatus.values) ...[
              Row(
                children: [
                  Expanded(child: Text(status.label, style: text.bodySmall)),
                  Text(
                    '${orders.where((order) => order.status == status).length}',
                    style: text.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: orders.isEmpty
                    ? 0
                    : orders.where((order) => order.status == status).length /
                          orders.length,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
                color: colors[status],
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              if (status != OrderStatus.cancelled) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

enum _RestaurantFilter { all, pending, approved, rejected, suspended }

extension _RestaurantFilterLabel on _RestaurantFilter {
  String get label => switch (this) {
    _RestaurantFilter.all => 'Semua',
    _RestaurantFilter.pending => 'Perlu ditinjau',
    _RestaurantFilter.approved => 'Disetujui',
    _RestaurantFilter.rejected => 'Ditolak',
    _RestaurantFilter.suspended => 'Ditangguhkan',
  };

  RestaurantReviewStatus? get status => switch (this) {
    _RestaurantFilter.all => null,
    _RestaurantFilter.pending => RestaurantReviewStatus.pending,
    _RestaurantFilter.approved => RestaurantReviewStatus.approved,
    _RestaurantFilter.rejected => RestaurantReviewStatus.rejected,
    _RestaurantFilter.suspended => RestaurantReviewStatus.suspended,
  };
}

class _RestaurantReviewTab extends StatefulWidget {
  final AppUser user;
  final AppServices services;

  const _RestaurantReviewTab({required this.user, required this.services});

  @override
  State<_RestaurantReviewTab> createState() => _RestaurantReviewTabState();
}

class _RestaurantReviewTabState extends State<_RestaurantReviewTab> {
  late final _restaurants = widget.services.admin.watchRestaurants();
  final _searchController = TextEditingController();
  _RestaurantFilter _filter = _RestaurantFilter.all;
  String _query = '';
  String? _updatingRestaurantId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reviewRestaurant(
    Restaurant restaurant,
    RestaurantReviewStatus status,
  ) async {
    if (_updatingRestaurantId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _ReviewConfirmationDialog(restaurant: restaurant, nextStatus: status),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _updatingRestaurantId = restaurant.id);
    try {
      await widget.services.admin.reviewRestaurant(
        restaurantId: restaurant.id,
        status: status,
        adminUid: widget.user.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${restaurant.name}: ${status.label}.')),
        );
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Status resto gagal disimpan. Periksa akses Firestore.',
        );
      }
    } finally {
      if (mounted) setState(() => _updatingRestaurantId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: _restaurants,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AdminStreamError(kind: 'daftar resto');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allRestaurants = snapshot.data ?? const [];
        final filtered = allRestaurants.where((restaurant) {
          final query = _query.trim().toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              restaurant.name.toLowerCase().contains(query) ||
              restaurant.address.toLowerCase().contains(query);
          final matchesStatus =
              _filter.status == null ||
              restaurant.reviewStatus == _filter.status;
          return matchesQuery && matchesStatus;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'Tinjau restoran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Resto yang belum disetujui tidak muncul di katalog pemesan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari nama atau alamat resto',
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
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _RestaurantFilter.values) ...[
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _InlineEmpty(
                icon: Icons.storefront_outlined,
                message: allRestaurants.isEmpty
                    ? 'Belum ada data resto untuk ditinjau.'
                    : 'Tidak ada resto yang cocok dengan filter ini.',
              )
            else
              for (final restaurant in filtered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RestaurantReviewCard(
                    restaurant: restaurant,
                    isUpdating: _updatingRestaurantId == restaurant.id,
                    isDisabled: _updatingRestaurantId != null,
                    onReview: (status) => _reviewRestaurant(restaurant, status),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _RestaurantReviewCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isUpdating;
  final bool isDisabled;
  final ValueChanged<RestaurantReviewStatus> onReview;

  const _RestaurantReviewCard({
    required this.restaurant,
    required this.isUpdating,
    required this.isDisabled,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final reviewStatus = restaurant.reviewStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RestaurantAvatar(
                  restaurantId: restaurant.id,
                  size: 48,
                  heroEnabled: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name, style: text.titleMedium),
                      if (restaurant.address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          restaurant.address,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ReviewStatusChip(status: reviewStatus),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${restaurant.location.latitude.toStringAsFixed(5)}, '
                    '${restaurant.location.longitude.toStringAsFixed(5)}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reviewActions(reviewStatus),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _reviewActions(RestaurantReviewStatus status) {
    final approve = _ReviewActionButton(
      label: 'Setujui',
      icon: Icons.check_rounded,
      isLoading: isUpdating,
      isDisabled: isDisabled,
      primary: true,
      onPressed: () => onReview(RestaurantReviewStatus.approved),
    );
    final reject = _ReviewActionButton(
      label: 'Tolak',
      icon: Icons.close_rounded,
      isLoading: isUpdating,
      isDisabled: isDisabled,
      onPressed: () => onReview(RestaurantReviewStatus.rejected),
    );
    final suspend = _ReviewActionButton(
      label: 'Tangguhkan',
      icon: Icons.pause_circle_outline_rounded,
      isLoading: isUpdating,
      isDisabled: isDisabled,
      onPressed: () => onReview(RestaurantReviewStatus.suspended),
    );

    return switch (status) {
      RestaurantReviewStatus.pending => [approve, reject],
      RestaurantReviewStatus.approved => [suspend, reject],
      RestaurantReviewStatus.rejected ||
      RestaurantReviewStatus.suspended => [approve],
    };
  }
}

class _ReviewActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isDisabled;
  final bool primary;
  final VoidCallback onPressed;

  const _ReviewActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 18);
    if (primary) {
      return FilledButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: child,
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: child,
      label: Text(label),
    );
  }
}

class _ReviewConfirmationDialog extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantReviewStatus nextStatus;

  const _ReviewConfirmationDialog({
    required this.restaurant,
    required this.nextStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = nextStatus == RestaurantReviewStatus.approved;
    final description = switch (nextStatus) {
      RestaurantReviewStatus.approved =>
        'Resto akan tampil di katalog pemesan dan dapat menerima pesanan.',
      RestaurantReviewStatus.rejected =>
        'Resto tidak akan tampil di katalog pemesan.',
      RestaurantReviewStatus.suspended =>
        'Resto akan disembunyikan sementara dari katalog pemesan.',
      RestaurantReviewStatus.pending =>
        'Resto akan kembali menunggu peninjauan admin.',
    };
    return AlertDialog(
      title: Text('${nextStatus.label} resto?'),
      content: Text('${restaurant.name}. $description'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(isApproved ? 'Setujui' : nextStatus.label),
        ),
      ],
    );
  }
}

class _ReviewStatusChip extends StatelessWidget {
  final RestaurantReviewStatus status;

  const _ReviewStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      RestaurantReviewStatus.pending => const Color(0xFFB45309),
      RestaurantReviewStatus.approved => brandGreen,
      RestaurantReviewStatus.rejected => scheme.error,
      RestaurantReviewStatus.suspended => scheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderMonitoringTab extends StatefulWidget {
  final AppServices services;

  const _OrderMonitoringTab({required this.services});

  @override
  State<_OrderMonitoringTab> createState() => _OrderMonitoringTabState();
}

class _OrderMonitoringTabState extends State<_OrderMonitoringTab> {
  late final _orders = widget.services.admin.watchOrders();
  late final _couriers = widget.services.admin.watchCouriers();
  final _searchController = TextEditingController();
  String _query = '';
  OrderStatus? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FoodOrder>>(
      stream: _orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AdminStreamError(kind: 'daftar pesanan');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<AppUser>>(
          stream: _couriers,
          builder: (context, courierSnapshot) {
            final orders = snapshot.data ?? const <FoodOrder>[];
            final counts = {
              for (final status in OrderStatus.values)
                status: orders.where((order) => order.status == status).length,
            };
            final query = _query.trim().toLowerCase();
            final visibleOrders = orders.where((order) {
              final matchesQuery =
                  query.isEmpty ||
                  order.restaurantName.toLowerCase().contains(query) ||
                  order.customerName.toLowerCase().contains(query) ||
                  order.id.toLowerCase().contains(query);
              return matchesQuery &&
                  (_status == null || order.status == _status);
            }).toList();
            final waitingForCourier = orders
                .where(
                  (order) =>
                      order.status == OrderStatus.paid &&
                      order.assignedCourierUid == null,
                )
                .length;
            final inTransit = orders
                .where(
                  (order) => order.deliveryStatus == DeliveryStatus.inTransit,
                )
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Text(
                  'Pantau pesanan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau pembayaran, penugasan kurir, dan perjalanan pesanan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) => GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: constraints.maxWidth >= 720 ? 2.8 : 1.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DashboardMetric(
                        label: 'Sudah dibayar, menunggu kurir',
                        value: waitingForCourier,
                        icon: Icons.person_search_outlined,
                        color: const Color(0xFFB45309),
                      ),
                      _DashboardMetric(
                        label: 'Pengantaran berlangsung',
                        value: inTransit,
                        icon: Icons.delivery_dining_rounded,
                        color: successGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OrderFilterBar(
                  controller: _searchController,
                  query: _query,
                  selectedStatus: _status,
                  statusCounts: counts,
                  totalCount: orders.length,
                  searchHint: 'Cari nama resto, pemesan, atau ID pesanan',
                  onQueryChanged: (value) => setState(() => _query = value),
                  onStatusChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 12),
                if (courierSnapshot.hasError)
                  const _InlineEmpty(
                    icon: Icons.warning_amber_rounded,
                    message:
                        'Daftar kurir gagal dimuat. Periksa Firestore Rules.',
                  )
                else if (courierSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    visibleOrders.any(
                      (order) =>
                          order.status == OrderStatus.paid &&
                          order.deliveryStatus == null,
                    ))
                  const LinearProgressIndicator(),
                if (visibleOrders.isEmpty)
                  const _InlineEmpty(
                    icon: Icons.receipt_long_outlined,
                    message: 'Ubah kata pencarian atau filter status.',
                  )
                else
                  for (final order in visibleOrders)
                    _AdminOrderCard(
                      order: order,
                      couriers: courierSnapshot.data ?? const <AppUser>[],
                      services: widget.services,
                      couriersLoaded:
                          !courierSnapshot.hasError &&
                          courierSnapshot.connectionState !=
                              ConnectionState.waiting,
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AdminOrderCard extends StatefulWidget {
  final FoodOrder order;
  final List<AppUser> couriers;
  final AppServices services;
  final bool couriersLoaded;
  final bool allowCourierAssignment;

  const _AdminOrderCard({
    required this.order,
    this.couriers = const <AppUser>[],
    required this.services,
    this.couriersLoaded = false,
    this.allowCourierAssignment = true,
  });

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _assigning = false;

  Future<void> _chooseCourier() async {
    final order = widget.order;
    if (widget.couriers.isEmpty) {
      showErrorSnackBar(
        context,
        widget.couriersLoaded
            ? 'Belum ada akun kurir. Buat akun Firebase Auth dan profil role courier.'
            : 'Daftar kurir belum selesai dimuat.',
      );
      return;
    }
    final courier = await showDialog<AppUser>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugaskan kurir'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final candidate in widget.couriers)
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.delivery_dining_rounded),
                  ),
                  title: Text(candidate.displayName),
                  subtitle: Text(
                    candidate.uid == order.assignedCourierUid
                        ? 'Kurir saat ini'
                        : 'Siap menerima tugas',
                  ),
                  onTap: () => Navigator.of(context).pop(candidate),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
    if (courier == null || !mounted) return;

    setState(() => _assigning = true);
    try {
      await widget.services.orders.assignCourier(
        orderId: order.id,
        courierUid: courier.uid,
        courierName: courier.displayName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan ditugaskan ke ${courier.displayName}.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Kurir gagal ditugaskan. Pastikan pesanan sudah dibayar dan Rules terbaru aktif.',
        );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = order.createdAt;
    final locationUpdatedAt = order.courierLocationUpdatedAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RestaurantAvatar(
                  restaurantId: order.restaurantId,
                  size: 44,
                  heroEnabled: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurantName, style: text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Pemesan: ${order.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(date),
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          OrderStatusChip(status: order.status),
                          Text(
                            formatRupiah(order.total),
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.assignedCourierName != null) ...[
              const SizedBox(height: 10),
              Text(
                '${order.deliveryStatus?.label ?? 'Kurir ditugaskan'}: '
                '${order.assignedCourierName}',
                style: text.bodySmall?.copyWith(color: scheme.primary),
              ),
            ],
            if (order.deliveryStatus == DeliveryStatus.inTransit) ...[
              const SizedBox(height: 4),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.location_searching_rounded,
                  color: scheme.primary,
                ),
                title: const Text('Pantau perjalanan kurir'),
                subtitle: Text(
                  locationUpdatedAt == null
                      ? 'Menunggu pembaruan lokasi GPS'
                      : 'Posisi diperbarui ${formatDateTime(locationUpdatedAt)}',
                ),
                children: [
                  if (order.courierLocation != null &&
                      order.deliveryLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CourierTrackingMap(
                        courierLocation: order.courierLocation,
                        destination: order.deliveryLocation,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Peta akan tampil setelah lokasi kurir dan tujuan tersedia.',
                      ),
                    ),
                ],
              ),
            ],
            if (widget.allowCourierAssignment &&
                order.status == OrderStatus.paid &&
                order.deliveryStatus != DeliveryStatus.inTransit &&
                order.deliveryStatus != DeliveryStatus.delivered) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _assigning ? null : _chooseCourier,
                icon: _assigning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delivery_dining_rounded),
                label: Text(
                  order.assignedCourierUid == null
                      ? 'Tugaskan kurir'
                      : 'Ganti kurir',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _AdminStreamError extends StatelessWidget {
  final String kind;

  const _AdminStreamError({required this.kind});

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.wifi_off_rounded,
      title: 'Gagal memuat $kind',
      message: 'Periksa koneksi atau akses admin di Firestore Rules.',
    );
  }
}
