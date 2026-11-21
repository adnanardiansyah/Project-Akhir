import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_date_time.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/courier_tracking_map.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/state_message.dart';
import '../../widgets/welcome_banner.dart';

// Tugas kurir dan berbagi GPS selama layar ini aktif.
class CourierDashboardScreen extends StatefulWidget {
  final AppUser user;
  final AppServices services;

  const CourierDashboardScreen({
    super.key,
    required this.user,
    required this.services,
  });

  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardScreenState();
}

class _CourierDashboardScreenState extends State<CourierDashboardScreen> {
  late final Stream<List<FoodOrder>> _orders = widget.services.orders
      .watchCourierOrders(widget.user.uid);
  StreamSubscription<GeoPoint>? _locationSubscription;
  String? _trackingOrderId;
  String? _busyOrderId;

  @override
  void dispose() {
    unawaited(_locationSubscription?.cancel());
    super.dispose();
  }

  Future<void> _startOrResumeTracking(FoodOrder order) async {
    if (_busyOrderId != null ||
        (_trackingOrderId != null && _trackingOrderId != order.id)) {
      return;
    }
    setState(() => _busyOrderId = order.id);
    try {
      final positions = await widget.services.location.watchPositionStream();
      final current = await widget.services.location.refreshCurrentLocation();
      final location = current.location;
      if (location == null) {
        throw StateError(_locationIssueMessage(current.issue));
      }

      if (order.deliveryStatus == DeliveryStatus.assigned) {
        await widget.services.orders.startCourierDelivery(
          order.id,
          widget.user.uid,
        );
      } else if (order.deliveryStatus != DeliveryStatus.inTransit) {
        throw StateError('Pesanan ini tidak sedang menunggu pengantaran.');
      }
      await widget.services.orders.updateCourierLocation(order.id, location);
      await _locationSubscription?.cancel();
      _locationSubscription = positions.listen(
        (nextLocation) => unawaited(_publishLocation(order.id, nextLocation)),
        onError: (Object error) {
          if (mounted) {
            showErrorSnackBar(
              context,
              'GPS terputus. Ketuk lanjutkan untuk mengirim lokasi lagi.',
            );
          }
        },
      );
      if (mounted) {
        setState(() => _trackingOrderId = order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pelacakan dimulai. Biarkan aplikasi kurir terbuka.'),
          ),
        );
      }
    } on StateError catch (error) {
      if (mounted) showErrorSnackBar(context, error.message);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Pelacakan gagal dimulai. Periksa internet, GPS, dan akses Firestore.',
        );
      }
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  String _locationIssueMessage(LocationIssue? issue) => switch (issue) {
    LocationIssue.serviceDisabled => 'Aktifkan GPS perangkat kurir.',
    LocationIssue.permissionDenied => 'Izinkan akses lokasi untuk kurir.',
    LocationIssue.permissionDeniedForever =>
      'Izinkan lokasi aplikasi lewat Pengaturan.',
    LocationIssue.unavailable || null => 'Lokasi GPS belum tersedia.',
  };

  Future<void> _publishLocation(String orderId, GeoPoint location) async {
    try {
      await widget.services.orders.updateCourierLocation(orderId, location);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Lokasi belum terkirim. Periksa koneksi internet.',
        );
      }
    }
  }

  Future<void> _completeDelivery(FoodOrder order) async {
    if (_busyOrderId != null) return;
    setState(() => _busyOrderId = order.id);
    try {
      await widget.services.orders.completeCourierDelivery(
        order.id,
        widget.user.uid,
      );
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      if (mounted) {
        setState(() => _trackingOrderId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengantaran ditandai selesai.')),
        );
      }
    } on StateError catch (error) {
      if (mounted) showErrorSnackBar(context, error.message);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Status pengantaran gagal diperbarui. Periksa koneksi atau akses.',
        );
      }
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Kurir'),
        actions: [LogoutButton(authService: widget.services.auth)],
      ),
      body: StreamBuilder<List<FoodOrder>>(
        stream: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const StateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Tugas gagal dimuat',
              message: 'Periksa koneksi dan akses Firestore.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? const <FoodOrder>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              WelcomeBanner(
                eyebrow: 'Panel kurir',
                title: 'Halo, ${widget.user.displayName}',
                subtitle: 'Tugas dan posisi pengantaran diperbarui langsung.',
                icon: Icons.delivery_dining_rounded,
              ),
              const SizedBox(height: 12),
              const _ForegroundTrackingNotice(),
              const SizedBox(height: 20),
              Text(
                'Pesanan ditugaskan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (orders.isEmpty)
                const _NoCourierOrders()
              else
                for (final order in orders)
                  _CourierOrderCard(
                    order: order,
                    isTracking: _trackingOrderId == order.id,
                    isBusy: _busyOrderId == order.id,
                    anotherOrderIsTracking:
                        _trackingOrderId != null &&
                        _trackingOrderId != order.id,
                    onStartOrResume: () => _startOrResumeTracking(order),
                    onComplete: () => _completeDelivery(order),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _ForegroundTrackingNotice extends StatelessWidget {
  const _ForegroundTrackingNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gps_fixed_rounded),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Berbagi lokasi berjalan saat aplikasi kurir terbuka. '
              'Ketuk lanjutkan lagi jika aplikasi sempat ditutup.',
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCourierOrders extends StatelessWidget {
  const _NoCourierOrders();

  @override
  Widget build(BuildContext context) {
    return const StateMessage(
      icon: Icons.assignment_outlined,
      title: 'Belum ada tugas',
      message: 'Admin akan menugaskan pesanan yang sudah dibayar kepadamu.',
    );
  }
}

class _CourierOrderCard extends StatelessWidget {
  final FoodOrder order;
  final bool isTracking;
  final bool isBusy;
  final bool anotherOrderIsTracking;
  final VoidCallback onStartOrResume;
  final VoidCallback onComplete;

  const _CourierOrderCard({
    required this.order,
    required this.isTracking,
    required this.isBusy,
    required this.anotherOrderIsTracking,
    required this.onStartOrResume,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final deliveryStatus = order.deliveryStatus;
    final canTrack =
        deliveryStatus == DeliveryStatus.assigned ||
        deliveryStatus == DeliveryStatus.inTransit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurantName, style: text.titleSmall),
                      Text(
                        'Pemesan: ${order.customerName}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(formatRupiah(order.total), style: text.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OrderStatusChip(status: order.status),
                if (deliveryStatus != null)
                  Chip(
                    avatar: Icon(
                      deliveryStatus == DeliveryStatus.delivered
                          ? Icons.check_circle_rounded
                          : Icons.delivery_dining_rounded,
                      size: 18,
                    ),
                    label: Text(deliveryStatus.label),
                  ),
              ],
            ),
            if (order.deliveryLocation case final destination?) ...[
              const SizedBox(height: 8),
              Text(
                'Tujuan: ${destination.latitude.toStringAsFixed(5)}, '
                '${destination.longitude.toStringAsFixed(5)}',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (deliveryStatus == DeliveryStatus.inTransit &&
                order.courierLocation != null &&
                order.deliveryLocation != null) ...[
              const SizedBox(height: 12),
              CourierTrackingMap(
                courierLocation: order.courierLocation,
                destination: order.deliveryLocation,
              ),
              if (order.courierLocationUpdatedAt case final updatedAt?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Lokasi dikirim ${formatDateTime(updatedAt)}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            if (canTrack) ...[
              const SizedBox(height: 12),
              if (isTracking)
                FilledButton.icon(
                  onPressed: isBusy ? null : onComplete,
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt_rounded),
                  label: const Text('Selesaikan pengantaran'),
                )
              else
                FilledButton.icon(
                  onPressed: isBusy || anotherOrderIsTracking
                      ? null
                      : onStartOrResume,
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          deliveryStatus == DeliveryStatus.assigned
                              ? Icons.play_arrow_rounded
                              : Icons.my_location_rounded,
                        ),
                  label: Text(
                    deliveryStatus == DeliveryStatus.assigned
                        ? 'Mulai pengantaran'
                        : 'Lanjutkan berbagi lokasi',
                  ),
                ),
              if (anotherOrderIsTracking)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selesaikan tugas yang sedang berjalan terlebih dahulu.',
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
            ],
            if (deliveryStatus == DeliveryStatus.delivered)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Tugas ini sudah selesai.'),
              ),
          ],
        ),
      ),
    );
  }
}
