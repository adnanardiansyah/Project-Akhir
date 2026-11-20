import 'package:flutter/material.dart';

import '../../controllers/cart_controller.dart';
import '../../models/app_user.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/pressable_card.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/route_api_key_button.dart';
import '../../widgets/route_distance_label.dart';
import '../../widgets/stream_list_view.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';

// Beranda pemesan: sapaan, daftar resto, dan bar keranjang
class RestaurantListScreen extends StatelessWidget {
  final AppUser user;
  final AppServices services;
  final CartController cart;

  const RestaurantListScreen({
    super.key,
    required this.user,
    required this.services,
    required this.cart,
  });

  // Membuka layar lain di atas beranda
  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Makanan'),
        actions: [
          RouteApiKeyButton(service: services.routeDistance),
          IconButton(
            tooltip: 'Pesanan saya',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () =>
                _push(context, MyOrdersScreen(user: user, services: services)),
          ),
          LogoutButton(authService: services.auth),
        ],
      ),
      body: Stack(
        children: [
          StreamListView<Restaurant>(
            streamFactory: services.restaurants.watchRestaurants,
            emptyIcon: Icons.storefront_rounded,
            emptyMessage: 'Belum ada resto',
            errorMessage:
                'Daftar resto gagal dimuat. Periksa koneksi internet.',
            bottomPadding: 120,
            header: _Greeting(name: user.displayName),
            itemBuilder: (context, restaurant) => _RestaurantCard(
              restaurant: restaurant,
              services: services,
              onTap: () => _push(
                context,
                MenuScreen(
                  restaurant: restaurant,
                  user: user,
                  services: services,
                  cart: cart,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CartBar(
              cart: cart,
              onOpen: () => _push(
                context,
                CartScreen(user: user, services: services, cart: cart),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sapaan di atas daftar resto
class _Greeting extends StatelessWidget {
  final String name;

  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $name',
            style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text('Mau makan apa hari ini?', style: text.headlineMedium),
        ],
      ),
    );
  }
}

// Kartu satu resto: avatar, nama, alamat, dan jarak rute
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final AppServices services;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.services,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return PressableCard(
      onTap: onTap,
      child: Row(
        children: [
          RestaurantAvatar(restaurantId: restaurant.id),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name, style: text.titleMedium),
                if (restaurant.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                RouteDistanceLabel(
                  services: services,
                  loadDestination: () async => restaurant.location,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
