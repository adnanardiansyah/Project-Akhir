import 'package:flutter/material.dart';

import '../../controllers/cart_controller.dart';
import '../../models/app_user.dart';
import '../../models/cart_item.dart';
import '../../services/app_services.dart';
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

// Menyimpan tanda sedang mengirim pesanan
class _CartScreenState extends State<CartScreen> {
  bool _isSubmitting = false;

  // Menulis pesanan ke Firestore, mengosongkan keranjang, lalu membuka detail pesanan
  Future<void> _submit() async {
    final cart = widget.cart;
    final restaurant = cart.restaurant;
    if (_isSubmitting || restaurant == null || cart.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final orderId = await widget.services.orders.createOrder(
        customerUid: widget.user.uid,
        customerName: widget.user.displayName,
        restaurant: restaurant,
        cartItems: cart.items,
      );
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
      // Dikosongkan walau layar sudah ditutup, agar pesanan tidak terkirim dua kali
      cart.clear();
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showErrorSnackBar(
          context,
          'Pesanan gagal dibuat. Periksa koneksi internet.',
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
                        child: _CartItemCard(item: item, cart: cart),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              _CheckoutPanel(
                total: cart.total,
                isSubmitting: _isSubmitting,
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

  const _CartItemCard({required this.item, required this.cart});

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
              onIncrement: () => cart.add(restaurant, item.menuItem),
              onDecrement: () => cart.decrement(item.menuItem.id),
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
  final VoidCallback onSubmit;

  const _CheckoutPanel({
    required this.total,
    required this.isSubmitting,
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
