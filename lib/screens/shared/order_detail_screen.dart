import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/payment_method.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_date_time.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/order_progress.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/route_distance_label.dart';
import '../../widgets/state_message.dart';
import '../customer/payment_screen.dart';
import 'chat_screen.dart';

// Detail satu pesanan yang diperbarui realtime; dipakai pemesan dan resto
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final AppUser user;
  final AppServices services;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.user,
    required this.services,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

// Menyimpan aliran pesanan dan status tujuan yang sedang diproses
class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<FoodOrder?> _orderStream = widget.services.orders
      .watchOrder(widget.orderId);
  OrderStatus? _updatingTo;

  bool get _isCustomer => widget.user.role == UserRole.customer;

  // Nama lawan transaksi: resto bagi pemesan, pemesan bagi resto
  String _counterpartName(FoodOrder order) =>
      _isCustomer ? order.restaurantName : order.customerName;

  // Membuka layar pembayaran simulasi untuk pesanan ini
  void _openPayment(FoodOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(order: order, services: widget.services),
      ),
    );
  }

  // Membuka chat pesanan ini
  void _openChat(FoodOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          orderId: order.id,
          user: widget.user,
          services: widget.services,
          title: _counterpartName(order),
        ),
      ),
    );
  }

  // Mengubah status pesanan; pembatalan meminta konfirmasi lebih dulu
  Future<void> _changeStatus(FoodOrder order, OrderStatus next) async {
    if (_updatingTo != null) return;
    if (next == OrderStatus.cancelled && !await _confirmCancel()) return;
    if (!mounted) return;
    setState(() => _updatingTo = next);
    try {
      await widget.services.orders.updateStatus(order.id, next);
    } on StateError catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Status gagal diubah. Periksa koneksi atau akses Firestore.',
        );
      }
    } finally {
      if (mounted) setState(() => _updatingTo = null);
    }
  }

  // Dialog konfirmasi pembatalan; mengembalikan true bila pengguna setuju
  Future<bool> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(
          _isCustomer
              ? 'Pesanan akan dibatalkan dan resto tidak akan memprosesnya.'
              : 'Pemesan akan melihat bahwa pesanan ini dibatalkan resto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: dialogButtonMinSize,
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

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
        message: 'Periksa koneksi atau akses Firestore.',
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
        FadeSlideIn(
          child: _OrderHeader(
            order: order,
            title: _counterpartName(order),
            // Jarak rute hanya bermakna dari perangkat pemesan (FR-5)
            distance: _isCustomer
                ? RouteDistanceLabel(
                    key: ValueKey('${order.id}:${order.restaurantId}'),
                    services: widget.services,
                    destinationKey: order.restaurantId,
                    loadDestination: () async =>
                        (await widget.services.restaurants.fetchRestaurant(
                          order.restaurantId,
                        ))?.location,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          index: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: OrderProgress(status: order.status),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(index: 2, child: _OrderItemsCard(order: order)),
        const SizedBox(height: 16),
        FadeSlideIn(
          index: 3,
          child: _OrderActions(
            status: order.status,
            isCustomer: _isCustomer,
            updatingTo: _updatingTo,
            onChange: (next) => _changeStatus(order, next),
            onPay: () => _openPayment(order),
          ),
        ),
        FadeSlideIn(
          index: 4,
          child: FilledButton.tonalIcon(
            onPressed: () => _openChat(order),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(
              _isCustomer ? 'Chat dengan resto' : 'Chat dengan pemesan',
            ),
          ),
        ),
      ],
    );
  }
}

// Kepala detail: nama lawan transaksi, waktu pesan, status, dan jarak bila pemesan
class _OrderHeader extends StatelessWidget {
  final FoodOrder order;
  final String title;
  final Widget? distance;

  const _OrderHeader({
    required this.order,
    required this.title,
    required this.distance,
  });

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
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    createdAt == null ? 'Baru saja' : formatDateTime(createdAt),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OrderStatusChip(status: order.status),
                  if (distance != null) ...[
                    const SizedBox(height: 8),
                    distance!,
                  ],
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
    final paymentMethod = paymentMethodFromName(order.paymentMethod);
    final paidAt = order.paidAt;
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
            if (paymentMethod != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(paymentMethod.icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paidAt == null
                          ? 'Dibayar lewat ${paymentMethod.label}'
                          : 'Dibayar lewat ${paymentMethod.label} · '
                                '${formatDateTime(paidAt)}',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Tombol aksi sesuai peran dan status: resto konfirmasi/batal, pemesan bayar/batal sebelum dibayar
class _OrderActions extends StatelessWidget {
  final OrderStatus status;
  final bool isCustomer;
  final OrderStatus? updatingTo;
  final ValueChanged<OrderStatus> onChange;
  final VoidCallback onPay;

  const _OrderActions({
    required this.status,
    required this.isCustomer,
    required this.updatingTo,
    required this.onChange,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canConfirm =
        !isCustomer && status.canTransitionTo(OrderStatus.confirmed);
    final canPay = isCustomer && status.canTransitionTo(OrderStatus.paid);
    final canCancel = status.canTransitionTo(OrderStatus.cancelled);
    final busy = updatingTo != null;
    return AnimatedSize(
      duration: motionMedium,
      curve: motionCurve,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canPay) ...[
            FilledButton.icon(
              onPressed: busy ? null : onPay,
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Bayar Sekarang'),
            ),
            const SizedBox(height: 12),
          ],
          if (canConfirm) ...[
            LoadingButton(
              label: 'Konfirmasi Pesanan',
              isLoading: updatingTo == OrderStatus.confirmed,
              onPressed: busy ? null : () => onChange(OrderStatus.confirmed),
            ),
            const SizedBox(height: 12),
          ],
          if (canCancel) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fieldRadius),
                ),
              ),
              onPressed: busy ? null : () => onChange(OrderStatus.cancelled),
              child: updatingTo == OrderStatus.cancelled
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(isCustomer ? 'Batalkan Pesanan' : 'Tolak / Batalkan'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
