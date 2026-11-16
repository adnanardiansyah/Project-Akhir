import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_date_time.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/state_message.dart';

// Detail satu pesanan yang diperbarui realtime
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final AppServices services;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.services,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

// Menyimpan aliran pesanan agar tidak dibuat ulang tiap build
class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<FoodOrder?> _orderStream = widget.services.orders
      .watchOrder(widget.orderId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: StreamBuilder<FoodOrder?>(
        stream: _orderStream,
        builder: (context, snapshot) => AnimatedSwitcher(
          duration: motionMedium,
          child: _buildContent(snapshot),
        ),
      ),
    );
  }

  // Memilih tampilan sesuai keadaan aliran
  Widget _buildContent(AsyncSnapshot<FoodOrder?> snapshot) {
    if (snapshot.hasError) {
      return const StateMessage(
        key: ValueKey('error'),
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat pesanan',
        message: 'Periksa koneksi internet.',
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    final order = snapshot.data;
    if (order == null) {
      return const StateMessage(
        key: ValueKey('missing'),
        icon: Icons.receipt_long_outlined,
        title: 'Pesanan tidak ditemukan',
      );
    }
    return ListView(
      key: const ValueKey('order'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        FadeSlideIn(child: _OrderHeader(order: order)),
        const SizedBox(height: 16),
        FadeSlideIn(index: 1, child: _OrderItemsCard(order: order)),
      ],
    );
  }
}

// Kepala detail: resto, waktu pesan, dan status
class _OrderHeader extends StatelessWidget {
  final FoodOrder order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final createdAt = order.createdAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            RestaurantAvatar(
              restaurantId: order.restaurantId,
              size: 52,
              heroEnabled: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.restaurantName, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    createdAt == null ? 'Baru saja' : formatDateTime(createdAt),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OrderStatusChip(status: order.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Rincian menu yang dipesan beserta total
class _OrderItemsCard extends StatelessWidget {
  final FoodOrder order;

  const _OrderItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rincian pesanan', style: text.titleMedium),
            const SizedBox(height: 12),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Lebar tetap agar nama menu sejajar walau jumlah berbeda digit
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${item.qty}×',
                        style: text.titleSmall?.copyWith(color: scheme.primary),
                      ),
                    ),
                    Expanded(child: Text(item.name, style: text.bodyLarge)),
                    Text(formatRupiah(item.subtotal), style: text.bodyLarge),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: Text('Total', style: text.titleMedium)),
                Text(
                  formatRupiah(order.total),
                  style: text.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
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
