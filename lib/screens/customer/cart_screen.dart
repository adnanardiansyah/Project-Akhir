import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../controllers/cart_controller.dart';
import '../../models/app_user.dart';
import '../../models/cart_item.dart';
import '../../services/app_services.dart';
import '../../services/firestore_write.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/restaurant_avatar.dart';
import '../shared/order_detail_screen.dart';

/// Layar Keranjang & Checkout Modern dengan Konsep Emerald Premium.
class CartScreen extends StatefulWidget {
  final AppUser user;
  final AppServices services;
  final CartController cart;

  const CartScreen({
    super.key,
    required this.user,
    required this.services,
    required this.cart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _waitingForServer = false;
  bool _isLoadingDeliveryLocation = false;
  GeoPoint? _deliveryLocation;
  String? _deliveryLocationError;
  Timer? _pendingNoticeTimer;

  @override
  void initState() {
    super.initState();
    _schedulePendingNotice();
    // Otomatis deteksi GPS untuk kemudahan pemesan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureDeliveryLocation();
    });
  }

  @override
  void dispose() {
    _pendingNoticeTimer?.cancel();
    super.dispose();
  }

  void _schedulePendingNotice() {
    _pendingNoticeTimer?.cancel();
    final startedAt = widget.cart.orderSubmissionStartedAt;
    if (startedAt == null) {
      _waitingForServer = false;
      return;
    }
    final remaining =
        writePendingNoticeDelay - DateTime.now().difference(startedAt);
    if (remaining <= Duration.zero) {
      _waitingForServer = true;
      return;
    }
    _pendingNoticeTimer = Timer(remaining, () {
      if (mounted && widget.cart.isSubmittingOrder) {
        setState(() => _waitingForServer = true);
      }
    });
  }

  Future<void> _captureDeliveryLocation() async {
    if (_isLoadingDeliveryLocation || widget.cart.isSubmittingOrder) return;
    setState(() {
      _isLoadingDeliveryLocation = true;
      _deliveryLocationError = null;
    });
    final result = await widget.services.location.refreshCurrentLocation();
    if (!mounted) return;
    setState(() {
      _isLoadingDeliveryLocation = false;
      if (result.location == null) {
        final message = _locationIssueMessage(result.issue);
        _deliveryLocationError = _deliveryLocation == null
            ? message
            : '$message Titik sebelumnya tetap digunakan.';
      } else {
        _deliveryLocation = result.location;
        _deliveryLocationError = null;
      }
    });
  }

  String _locationIssueMessage(LocationIssue? issue) => switch (issue) {
    LocationIssue.serviceDisabled =>
      'Aktifkan GPS ponsel untuk mengambil lokasi.',
    LocationIssue.permissionDenied => 'Izin akses lokasi belum diberikan.',
    LocationIssue.permissionDeniedForever =>
      'Izinkan akses lokasi lewat Pengaturan perangkat.',
    LocationIssue.unavailable ||
    null => 'Gagal membaca koordinat GPS perangkat.',
  };

  Future<void> _submit() async {
    if (_isLoadingDeliveryLocation) return;
    if (_deliveryLocation == null) {
      showErrorSnackBar(
        context,
        'Pastikan GPS aktif dan titik pengantaran telah terbaca.',
      );
      return;
    }
    final cart = widget.cart;
    final restaurant = cart.restaurant;
    if (restaurant == null || cart.isEmpty || !cart.beginOrderSubmission()) {
      return;
    }
    setState(() => _waitingForServer = false);
    _schedulePendingNotice();

    try {
      final orderId = await widget.services.orders.createOrder(
        customerUid: widget.user.uid,
        customerName: widget.user.displayName,
        restaurant: restaurant,
        cartItems: cart.items,
        deliveryLocation: _deliveryLocation!,
      );
      _pendingNoticeTimer?.cancel();
      cart.finishOrderSubmission(succeeded: true);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              orderId: orderId,
              user: widget.user,
              services: widget.services,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (_) {
      _pendingNoticeTimer?.cancel();
      cart.finishOrderSubmission(succeeded: false);
      if (mounted) {
        setState(() => _waitingForServer = false);
        showErrorSnackBar(
          context,
          'Pesanan gagal disimpan. Periksa koneksi dan akses Firestore.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmeraldColors.background,
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) {
          final cart = widget.cart;
          final restaurant = cart.restaurant;

          if (cart.isEmpty || restaurant == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: EmeraldColors.softGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: EmeraldColors.primary,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Keranjang Masih Kosong',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: EmeraldColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih makanan lezat dari resto favoritmu di Lhokseumawe dan buat pesanan sekarang.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EmeraldColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = cart.items;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Info Restoran
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: EmeraldColors.border),
                      ),
                      child: Row(
                        children: [
                          RestaurantAvatar(
                            restaurantId: restaurant.id,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: EmeraldColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pesanan dari restoran ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: EmeraldColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => cart.clear(),
                            style: TextButton.styleFrom(
                              foregroundColor: EmeraldColors.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text('Kosongkan'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Daftar Item Makanan
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildCartItemCard(item),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Lokasi Pengantaran (GPS Capture)
                    _buildDeliveryLocationCard(),

                    const SizedBox(height: 14),

                    // Ringkasan Pembayaran
                    _buildPaymentSummaryCard(cart),
                  ],
                ),
              ),

              // Bottom Checkout Bar
              _buildCheckoutBottomBar(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmeraldColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EmeraldColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: EmeraldColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EmeraldColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(item.menuItem.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: EmeraldColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          QuantityStepper(
            quantity: item.quantity,
            onIncrement: widget.cart.isSubmittingOrder
                ? null
                : () => widget.cart.add(widget.cart.restaurant!, item.menuItem),
            onDecrement: widget.cart.isSubmittingOrder
                ? null
                : () => widget.cart.decrement(item.menuItem.id),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmeraldColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: EmeraldColors.softGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: EmeraldColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Titik Pengantaran Kurir (GPS)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: EmeraldColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _isLoadingDeliveryLocation
                    ? null
                    : _captureDeliveryLocation,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingDeliveryLocation)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: EmeraldColors.primary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh_rounded,
                          size: 15,
                          color: EmeraldColors.primary,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _isLoadingDeliveryLocation ? 'Membaca...' : 'Perbarui',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: EmeraldColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_deliveryLocation != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EmeraldColors.softGreenLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EmeraldColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: EmeraldColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Terkunci: ${_deliveryLocation!.latitude.toStringAsFixed(5)}, '
                      '${_deliveryLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EmeraldColors.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              _deliveryLocationError ??
                  'Ketuk perbarui untuk merekam GPS pengantaran.',
              style: TextStyle(
                fontSize: 12,
                color: _deliveryLocationError != null
                    ? EmeraldColors.error
                    : EmeraldColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(CartController cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmeraldColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: EmeraldColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subtotal (${cart.totalQuantity} menu)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: EmeraldColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  formatRupiah(cart.total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: EmeraldColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Biaya Layanan & Pengantaran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: EmeraldColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Rp 0 (Simulasi)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: EmeraldColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Total Tagihan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: EmeraldColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  formatRupiah(cart.total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: EmeraldColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomBar(CartController cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: EmeraldColors.border)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_waitingForServer)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Sedang menunggu konfirmasi server...',
                style: TextStyle(
                  fontSize: 12,
                  color: EmeraldColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL PESANAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: EmeraldColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    formatRupiah(cart.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: EmeraldColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: LoadingButton(
                  label: 'Buat Pesanan',
                  isLoading: cart.isSubmittingOrder,
                  icon: Icons.check_circle_rounded,
                  onPressed: _deliveryLocation == null ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
