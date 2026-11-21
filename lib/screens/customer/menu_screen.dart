import 'package:flutter/material.dart';

import '../../controllers/cart_controller.dart';
import '../../models/app_user.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/stream_list_view.dart';
import 'cart_screen.dart';

// Layar menu dan harga satu resto, dengan tombol tambah ke keranjang
class MenuScreen extends StatelessWidget {
  final Restaurant restaurant;
  final AppUser user;
  final AppServices services;
  final CartController cart;

  const MenuScreen({
    super.key,
    required this.restaurant,
    required this.user,
    required this.services,
    required this.cart,
  });

  // Menambah menu; bila keranjang berisi menu resto lain, minta konfirmasi ganti
  Future<void> _addItem(BuildContext context, MenuItem item) async {
    if (cart.isSubmittingOrder) {
      showErrorSnackBar(
        context,
        'Pesanan sedang dikirim. Tunggu konfirmasi server terlebih dahulu.',
      );
      return;
    }
    if (cart.canAddFrom(restaurant)) {
      cart.add(restaurant, item);
      return;
    }
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti keranjang?'),
        content: Text(
          'Keranjang berisi menu dari ${cart.restaurant?.name}. '
          'Satu pesanan hanya untuk satu resto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: dialogButtonMinSize),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
    if (replace == true) cart.replaceWith(restaurant, item);
  }

  // Membuka layar keranjang
  void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(user: user, services: services, cart: cart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [LogoutButton(authService: services.auth)]),
      body: Stack(
        children: [
          StreamListView<MenuItem>(
            streamFactory: () =>
                services.restaurants.watchMenuItems(restaurant.id),
            emptyIcon: Icons.no_meals_rounded,
            emptyMessage: 'Menu resto ini belum tersedia',
            errorMessage: 'Menu gagal dimuat. Periksa koneksi atau akses Firestore.',
            bottomPadding: 120,
            header: _RestaurantHeader(restaurant: restaurant),
            itemBuilder: (context, item) => _MenuItemCard(
              item: item,
              cart: cart,
              onAdd: () => _addItem(context, item),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CartBar(cart: cart, onOpen: () => _openCart(context)),
          ),
        ],
      ),
    );
  }
}

// Kepala layar menu: avatar besar, nama, dan alamat resto
class _RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantHeader({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          RestaurantAvatar(restaurantId: restaurant.id, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name, style: text.headlineSmall),
                if (restaurant.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    restaurant.address,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Kartu satu menu: nama, harga, dan pengatur jumlah di keranjang
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final CartController cart;
  final VoidCallback onAdd;

  const _MenuItemCard({
    required this.item,
    required this.cart,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(item.price),
                    style: text.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: cart,
              builder: (context, _) => QuantityStepper(
                quantity: cart.quantityOf(item.id),
                onIncrement: cart.isSubmittingOrder ? null : onAdd,
                onDecrement: cart.isSubmittingOrder
                    ? null
                    : () => cart.decrement(item.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
