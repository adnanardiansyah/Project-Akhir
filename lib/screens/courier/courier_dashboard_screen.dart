import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/route_distance_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/arrival_detector.dart';
import '../../utils/format_date_time.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/courier_tracking_map.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/route_api_key_button.dart';
import '../../widgets/state_message.dart';

enum _CourierTaskFilter { active, history, all }

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
  StreamSubscription<CourierPosition>? _locationSubscription;
  Future<void> _publishQueue = Future.value();
  FoodOrder? _trackingOrder;
  String? _trackingOrderId;
  String? _busyOrderId;
  final ArrivalDetector _arrivalDetector = ArrivalDetector();
  bool _autoArriving = false;
  bool _completionDialogOpen = false;
  bool _locationErrorShown = false;
  int _trackingGeneration = 0;
  _CourierTaskFilter _filter = _CourierTaskFilter.active;

  @override
  void dispose() {
    unawaited(_stopTracking(clearState: false));
    super.dispose();
  }

  Future<void> _stopTracking({bool clearState = true}) async {
    _trackingGeneration++;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _trackingOrder = null;
    _arrivalDetector.reset();
    if (clearState && mounted) setState(() => _trackingOrderId = null);
  }

  Future<void> _startOrResumeTracking(FoodOrder order) async {
    if (_busyOrderId != null ||
        _autoArriving ||
        (_trackingOrderId != null && _trackingOrderId != order.id)) {
      return;
    }
    final generation = ++_trackingGeneration;
    setState(() => _busyOrderId = order.id);
    try {
      final positions = await widget.services.location.watchPositionStream();
      if (!mounted || generation != _trackingGeneration) return;
      final current = await widget.services.location.refreshCurrentLocation();
      if (!mounted || generation != _trackingGeneration) return;
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
      if (!mounted || generation != _trackingGeneration) return;
      await widget.services.orders.updateCourierLocation(order.id, location);
      if (!mounted || generation != _trackingGeneration) return;
      await _locationSubscription?.cancel();
      _trackingOrder = order;
      _arrivalDetector.reset();
      _locationErrorShown = false;
      _publishQueue = Future.value();
      _locationSubscription = positions.listen(
        (position) {
          _publishQueue = _publishQueue.then(
            (_) => _publishLocation(position, generation),
          );
          unawaited(_publishQueue);
        },
        onError: (Object error) {
          if (mounted && !_locationErrorShown) {
            _locationErrorShown = true;
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
            content: Text(
              'Pelacakan berjalan di latar belakang lewat notifikasi.',
            ),
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
      if (mounted && generation == _trackingGeneration) {
        setState(() => _busyOrderId = null);
      }
    }
  }

  String _locationIssueMessage(LocationIssue? issue) => switch (issue) {
    LocationIssue.serviceDisabled => 'Aktifkan GPS perangkat kurir.',
    LocationIssue.permissionDenied => 'Izinkan akses lokasi untuk kurir.',
    LocationIssue.permissionDeniedForever =>
      'Izinkan lokasi aplikasi lewat Pengaturan.',
    LocationIssue.unavailable || null => 'Lokasi GPS belum tersedia.',
  };

  Future<void> _publishLocation(
    CourierPosition position,
    int generation,
  ) async {
    final order = _trackingOrder;
    if (!mounted ||
        generation != _trackingGeneration ||
        order == null ||
        _autoArriving ||
        _busyOrderId != null ||
        _completionDialogOpen) {
      return;
    }
    try {
      await widget.services.orders.updateCourierLocation(
        order.id,
        position.location,
      );
      _locationErrorShown = false;
      final destination = order.deliveryLocation;
      if (destination == null) return;
      final arrived = _arrivalDetector.observe(
        courierLatitude: position.location.latitude,
        courierLongitude: position.location.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        speedMetersPerSecond: position.speedMetersPerSecond,
        now: DateTime.now(),
      );
      if (arrived &&
          !_autoArriving &&
          _busyOrderId == null &&
          !_completionDialogOpen &&
          generation == _trackingGeneration) {
        _autoArriving = true;
        await _autoComplete(order);
      }
    } catch (_) {
      if (mounted && !_locationErrorShown) {
        _locationErrorShown = true;
        showErrorSnackBar(
          context,
          'Lokasi belum terkirim. Periksa koneksi internet.',
        );
      }
    }
  }

  Future<void> _autoComplete(FoodOrder order) async {
    try {
      if (order.isCodPayment) {
        _arrivalDetector.reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terdeteksi tiba. Konfirmasi penerimaan COD.'),
            ),
          );
          await _completeDelivery(order, fromAuto: true);
        }
        return;
      }
      if (_busyOrderId != null || _completionDialogOpen) return;
      if (mounted) setState(() => _busyOrderId = order.id);
      await widget.services.orders.autoArrive(order.id, widget.user.uid);
      await _stopTracking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terdeteksi tiba. Pengantaran selesai.'),
          ),
        );
      }
    } on StateError catch (error) {
      _arrivalDetector.reset();
      if (mounted) showErrorSnackBar(context, error.message);
    } catch (_) {
      _arrivalDetector.reset();
      if (mounted) {
        showErrorSnackBar(
          context,
          'Gagal menandai tiba otomatis. Silakan selesaikan manual.',
        );
      }
    } finally {
      _autoArriving = false;
      if (mounted && _busyOrderId == order.id) {
        setState(() => _busyOrderId = null);
      }
    }
  }

  Future<void> _completeDelivery(
    FoodOrder order, {
    bool fromAuto = false,
  }) async {
    if (_busyOrderId != null ||
        _completionDialogOpen ||
        (_autoArriving && !fromAuto)) {
      return;
    }
    _completionDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          order.isCodPayment
              ? 'Terima pembayaran COD?'
              : 'Selesaikan pengantaran?',
        ),
        content: Text(
          order.isCodPayment
              ? 'Pastikan ${formatRupiah(order.total)} tunai sudah diterima sebelum menandai pesanan selesai.'
              : 'Tandai tugas selesai setelah pesanan diterima di tujuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, selesai'),
          ),
        ],
      ),
    );
    _completionDialogOpen = false;
    if (confirmed != true || !mounted || _busyOrderId != null) return;
    setState(() => _busyOrderId = order.id);
    try {
      if (order.isCodPayment) {
        await widget.services.orders.collectCodPayment(
          order.id,
          widget.user.uid,
        );
      } else {
        await widget.services.orders.completeCourierDelivery(
          order.id,
          widget.user.uid,
        );
      }
      await _stopTracking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              order.isCodPayment
                  ? 'COD diterima. Pengantaran selesai.'
                  : 'Pengantaran ditandai selesai.',
            ),
          ),
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
      backgroundColor: EmeraldColors.background,
      body: SafeArea(
        child: StreamBuilder<List<FoodOrder>>(
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
            final activeCount = orders
                .where(
                  (order) => order.deliveryStatus != DeliveryStatus.delivered,
                )
                .length;
            final inTransitCount = orders
                .where(
                  (order) => order.deliveryStatus == DeliveryStatus.inTransit,
                )
                .length;
            final completedCount = orders
                .where(
                  (order) => order.deliveryStatus == DeliveryStatus.delivered,
                )
                .length;
            final visibleOrders = orders.where((order) {
              return switch (_filter) {
                _CourierTaskFilter.active =>
                  order.deliveryStatus != DeliveryStatus.delivered,
                _CourierTaskFilter.history =>
                  order.deliveryStatus == DeliveryStatus.delivered,
                _CourierTaskFilter.all => true,
              };
            }).toList()..sort(_compareCourierTasks);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _CourierHeader(
                      name: widget.user.displayName,
                      authService: widget.services.auth,
                      routeService: widget.services.routeDistance,
                    ),
                    const SizedBox(height: 14),
                    _ForegroundTrackingNotice(
                      isTracking: _trackingOrderId != null,
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) => GridView.count(
                        crossAxisCount: constraints.maxWidth >= 720 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: constraints.maxWidth >= 720
                            ? 2.0
                            : 1.25,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _CourierMetric(
                            label: 'Tugas aktif',
                            value: activeCount,
                            icon: Icons.assignment_outlined,
                            color: EmeraldColors.warning,
                          ),
                          _CourierMetric(
                            label: 'Sedang diantar',
                            value: inTransitCount,
                            icon: Icons.delivery_dining_rounded,
                            color: EmeraldColors.primary,
                          ),
                          _CourierMetric(
                            label: 'Selesai',
                            value: completedCount,
                            icon: Icons.task_alt_rounded,
                            color: EmeraldColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Tugas Pengantaran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: EmeraldColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('Aktif ($activeCount)'),
                            selected: _filter == _CourierTaskFilter.active,
                            onSelected: (_) => setState(
                              () => _filter = _CourierTaskFilter.active,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Riwayat ($completedCount)'),
                            selected: _filter == _CourierTaskFilter.history,
                            onSelected: (_) => setState(
                              () => _filter = _CourierTaskFilter.history,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Semua (${orders.length})'),
                            selected: _filter == _CourierTaskFilter.all,
                            onSelected: (_) => setState(
                              () => _filter = _CourierTaskFilter.all,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (visibleOrders.isEmpty)
                      StateMessage(
                        icon: _filter == _CourierTaskFilter.history
                            ? Icons.history_rounded
                            : Icons.assignment_outlined,
                        title: _filter == _CourierTaskFilter.history
                            ? 'Belum ada riwayat'
                            : 'Belum ada tugas',
                        message: _filter == _CourierTaskFilter.history
                            ? 'Pengantaran yang selesai akan tersimpan di sini.'
                            : 'Admin akan menugaskan pesanan yang sudah dibayar kepadamu.',
                      )
                    else
                      for (final order in visibleOrders)
                        _CourierOrderCard(
                          order: order,
                          services: widget.services,
                          isTracking: _trackingOrderId == order.id,
                          isBusy: _busyOrderId == order.id,
                          anotherOrderIsTracking:
                              _trackingOrderId != null &&
                              _trackingOrderId != order.id,
                          onStartOrResume: () => _startOrResumeTracking(order),
                          onComplete: () => _completeDelivery(order),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _compareCourierTasks(FoodOrder first, FoodOrder second) {
    int priority(FoodOrder order) => switch (order.deliveryStatus) {
      DeliveryStatus.inTransit => 0,
      DeliveryStatus.assigned => 1,
      DeliveryStatus.delivered || null => 2,
    };
    final byStatus = priority(first).compareTo(priority(second));
    if (byStatus != 0) return byStatus;
    return (second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
  }
}

// Header panel kurir bergradien Emerald
class _CourierHeader extends StatelessWidget {
  final String name;
  final AuthService authService;
  final RouteDistanceService routeService;

  const _CourierHeader({
    required this.name,
    required this.authService,
    required this.routeService,
  });

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
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel Kurir',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Halo, $name',
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
          RouteApiKeyButton(service: routeService),
          LogoutButton(authService: authService),
        ],
      ),
    );
  }
}

class _ForegroundTrackingNotice extends StatelessWidget {
  final bool isTracking;

  const _ForegroundTrackingNotice({required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isTracking
            ? EmeraldColors.success.withValues(alpha: 0.1)
            : EmeraldColors.softGreenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTracking
              ? EmeraldColors.success.withValues(alpha: 0.3)
              : EmeraldColors.border,
        ),
      ),
      child: Row(
        children: [
          if (isTracking) ...[
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: EmeraldColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const Icon(
              Icons.info_outline_rounded,
              color: EmeraldColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTracking ? 'GPS Sedang Aktif' : 'Siap Berangkat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isTracking
                        ? EmeraldColors.success
                        : EmeraldColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTracking
                      ? 'Lokasi dibagikan lewat notifikasi walau aplikasi ditutup.'
                      : 'Lokasi mulai dibagikan setelah kamu memulai tugas pengantaran.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: EmeraldColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourierMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _CourierMetric({
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

class _CourierOrderCard extends StatelessWidget {
  final FoodOrder order;
  final AppServices services;
  final bool isTracking;
  final bool isBusy;
  final bool anotherOrderIsTracking;
  final VoidCallback onStartOrResume;
  final VoidCallback onComplete;

  const _CourierOrderCard({
    required this.order,
    required this.services,
    required this.isTracking,
    required this.isBusy,
    required this.anotherOrderIsTracking,
    required this.onStartOrResume,
    required this.onComplete,
  });

  Color _statusColor(DeliveryStatus? status) => switch (status) {
    DeliveryStatus.inTransit => EmeraldColors.primary,
    DeliveryStatus.assigned => EmeraldColors.warning,
    DeliveryStatus.delivered || null => EmeraldColors.border,
  };

  @override
  Widget build(BuildContext context) {
    final deliveryStatus = order.deliveryStatus;
    final canTrack =
        deliveryStatus == DeliveryStatus.assigned ||
        deliveryStatus == DeliveryStatus.inTransit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: EmeraldColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EmeraldColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip dengan aksen warna status
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: _statusColor(deliveryStatus),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info resto & pemesan
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: EmeraldColors.softGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: EmeraldColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.restaurantName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: EmeraldColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: EmeraldColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: EmeraldColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatRupiah(order.total),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: EmeraldColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        OrderStatusChip(status: order.status),
                      ],
                    ),
                  ],
                ),

                // Titik tujuan
                if (order.deliveryLocation case final destination?) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: EmeraldColors.softGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmeraldColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: EmeraldColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tujuan: ${destination.latitude.toStringAsFixed(5)}, '
                            '${destination.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: EmeraldColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (canTrack && order.deliveryLocation == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Titik tujuan belum tersedia. Hubungi admin sebelum berangkat.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EmeraldColors.error,
                      ),
                    ),
                  ),

                // Peta selalu tampil langsung saat ditugaskan atau sedang jalan
                if ((deliveryStatus == DeliveryStatus.assigned ||
                        deliveryStatus == DeliveryStatus.inTransit) &&
                    order.deliveryLocation != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CourierTrackingMap(
                      courierLocation: order.courierLocation,
                      destination: order.deliveryLocation,
                      routeService: services.routeDistance,
                    ),
                  ),
                  if (order.courierLocationUpdatedAt case final updatedAt?) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Posisi diperbarui ${formatDateTime(updatedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EmeraldColors.textSecondary,
                      ),
                    ),
                  ],
                ],

                // Action buttons
                if (canTrack) ...[
                  const SizedBox(height: 14),
                  if (isTracking)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : onComplete,
                        style: FilledButton.styleFrom(
                          backgroundColor: EmeraldColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.task_alt_rounded),
                        label: Text(
                          order.isCodPayment
                              ? 'Selesai + Terima Pembayaran'
                              : 'Selesaikan Pengantaran',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: isBusy || anotherOrderIsTracking
                            ? null
                            : onStartOrResume,
                        style: FilledButton.styleFrom(
                          backgroundColor: EmeraldColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                deliveryStatus == DeliveryStatus.assigned
                                    ? Icons.play_arrow_rounded
                                    : Icons.my_location_rounded,
                              ),
                        label: Text(
                          deliveryStatus == DeliveryStatus.assigned
                              ? 'Mulai Pengantaran'
                              : 'Lanjutkan Berbagi Lokasi',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (anotherOrderIsTracking)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Selesaikan tugas yang sedang berjalan terlebih dahulu.',
                        style: TextStyle(
                          fontSize: 11,
                          color: EmeraldColors.error,
                        ),
                      ),
                    ),
                  if (canTrack) ...[
                    const SizedBox(height: 8),
                    Text(
                      'GPS tetap jalan saat aplikasi ditutup. Tiba otomatis setelah '
                      'kurir diam ±20 detik dalam radius 60 m dari tujuan.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EmeraldColors.textSecondary,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => unawaited(
                          services.location.openBackgroundLocationSettings(),
                        ),
                        icon: const Icon(Icons.settings_rounded, size: 16),
                        label: const Text('Izinkan lokasi latar belakang'),
                      ),
                    ),
                  ],
                ],

                if (deliveryStatus == DeliveryStatus.delivered)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: EmeraldColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: EmeraldColors.success,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tugas pengantaran selesai.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: EmeraldColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
