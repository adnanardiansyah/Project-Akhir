import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/cart_controller.dart';
import '../../models/app_user.dart';
import '../../models/cart_item.dart';
import '../../services/app_services.dart';
import '../../services/firestore_write.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/state_message.dart';
import '../shared/order_detail_screen.dart';

// Layar keranjang: atur jumlah, lihat total, lalu buat pesanan
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

// Menunggu konfirmasi server tanpa mengizinkan pesanan yang sama dikirim dua kali.
class _CartScreenState extends State<CartScreen> {
  bool _waitingForServer = false;
  Timer? _pendingNoticeTimer;

  @override
  void initState() {
    super.initState();
    _schedulePendingNotice();
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

  // Menulis pesanan ke Firestore, mengosongkan keranjang, lalu membuka detail pesanan
  Future<void> _submit() async {
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
      appBar: AppBar(title: const Text('Keranjang')),
      body: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) {
          final cart = widget.cart;
          final restaurant = cart.restaurant;
          if (cart.isEmpty || restaurant == null) {
            return const StateMessage(
              icon: Icons.shopping_bag_outlined,
              title: 'Keranjang kosong',
              message: 'Pilih menu dari resto untuk mulai memesan.',
            );
          }
          final items = cart.items;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    FadeSlideIn(
                      child: Row(
                        children: [
                          RestaurantAvatar(
                            restaurantId: restaurant.id,
                            size: 44,
                            heroEnabled: false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final (index, item) in items.indexed) ...[
                      FadeSlideIn(
                        index: index + 1,
                        child: _CartItemCard(
                          item: item,
                          cart: cart,
                          isDisabled: cart.isSubmittingOrder,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              _CheckoutPanel(
                total: cart.total,
                isSubmitting: cart.isSubmittingOrder,
                isWaitingForServer: _waitingForServer,
                onSubmit: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

// Kartu satu baris keranjang: nama, harga satuan, subtotal, pengatur jumlah
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final CartController cart;
  final bool isDisabled;

  const _CartItemCard({
    required this.item,
    required this.cart,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final restaurant = cart.restaurant!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.menuItem.name, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${formatRupiah(item.menuItem.price)} × ${item.quantity}'
                    ' = ${formatRupiah(item.subtotal)}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            QuantityStepper(
              quantity: item.quantity,
              onIncrement: isDisabled
                  ? null
                  : () => cart.add(restaurant, item.menuItem),
              onDecrement: isDisabled
                  ? null
                  : () => cart.decrement(item.menuItem.id),
            ),
          ],
        ),
      ),
    );
  }
}

// Panel bawah: total dan tombol buat pesanan
class _CheckoutPanel extends StatelessWidget {
  final int total;
  final bool isSubmitting;
  final bool isWaitingForServer;
  final VoidCallback onSubmit;

  const _CheckoutPanel({
    required this.total,
    required this.isSubmitting,
    required this.isWaitingForServer,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Total', style: text.titleMedium)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      formatRupiah(total),
                      key: ValueKey(total),
                      style: text.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (isWaitingForServer) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cloud_sync_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pesanan belum dikonfirmasi server. Tunggu koneksi; '
                        'jangan kirim pesanan lagi.',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              LoadingButton(
                label: 'Buat Pesanan',
                isLoading: isSubmitting,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
