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
import '../../widgets/food_image.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/route_distance_label.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/state_message.dart';
import 'cart_screen.dart';

/// Layar Detail Restoran & Daftar Menu dengan Konsep Emerald Premium.
class MenuScreen extends StatefulWidget {
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

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // Aliran menu tetap hidup saat pengguna mengetik pencarian
  late Stream<List<MenuItem>> _menuStream = widget.services.restaurants
      .watchMenuItems(widget.restaurant.id);

  // Tarik ke bawah meminta snapshot Firestore baru untuk restoran ini
  Future<void> _refresh() async {
    setState(() {
      _menuStream = widget.services.restaurants.watchMenuItems(
        widget.restaurant.id,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Menambah menu; bila keranjang berisi menu resto lain, minta konfirmasi ganti
  Future<void> _addItem(BuildContext context, MenuItem item) async {
    if (widget.cart.isSubmittingOrder) {
      showErrorSnackBar(
        context,
        'Pesanan sedang dikirim. Tunggu konfirmasi server terlebih dahulu.',
      );
      return;
    }
    if (widget.cart.canAddFrom(widget.restaurant)) {
      widget.cart.add(widget.restaurant, item);
      return;
    }
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Ganti keranjang?'),
        content: Text(
          'Keranjang Anda saat ini berisi menu dari ${widget.cart.restaurant?.name}. '
          'Satu pesanan hanya dapat dibuat untuk satu resto sekaligus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: EmeraldColors.primary,
              minimumSize: dialogButtonMinSize,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ganti Keranjang'),
          ),
        ],
      ),
    );
    if (replace == true) widget.cart.replaceWith(widget.restaurant, item);
  }

  void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          user: widget.user,
          services: widget.services,
          cart: widget.cart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmeraldColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: EmeraldColors.primary,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Hero AppBar dengan Background Emerald & Navigasi
                _buildHeroAppBar(context),

                // 2. Info Card Restoran
                SliverToBoxAdapter(child: _buildRestaurantInfoCard(context)),

                // 3. Search Bar Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EmeraldColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari menu di resto ini...',
                          hintStyle: const TextStyle(
                            color: EmeraldColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: EmeraldColors.primary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar Menu Tersedia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: EmeraldColors.textPrimary,
                                ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: EmeraldColors.softGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Harga Resmi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: EmeraldColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Daftar Menu Reaktif dari Firestore
                _buildMenuListSliver(context),

                // Bottom Padding
                const SliverToBoxAdapter(child: SizedBox(height: 130)),
              ],
            ),
          ),

          // Floating Cart Bar di bagian bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: CartBar(cart: widget.cart, onOpen: () => _openCart(context)),
          ),
        ],
      ),
    );
  }

  // Hero AppBar dengan foto restoran
  Widget _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: EmeraldColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: EmeraldColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            FoodImage(
              imageUrl: getRestaurantCoverPhoto(widget.restaurant.name),
              borderRadius: 0,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x33000000), Color(0x99000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Restaurant Info Card
  Widget _buildRestaurantInfoCard(BuildContext context) {
    final r = widget.restaurant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Transform.translate(
        offset: const Offset(0, -30),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EmeraldColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RestaurantAvatar(restaurantId: r.id, size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: EmeraldColors.softGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'MITRA RESMI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: EmeraldColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFD97706),
                                      size: 13,
                                    ),
                                    SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        '4.8',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: EmeraldColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (r.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: EmeraldColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: RouteDistanceLabel(
                      services: widget.services,
                      destinationKey:
                          '${r.id}:${r.location.latitude},${r.location.longitude}',
                      loadDestination: () async => r.location,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: EmeraldColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '15–25 Menit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: EmeraldColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menu List Sliver
  Widget _buildMenuListSliver(BuildContext context) {
    return StreamBuilder<List<MenuItem>>(
      stream: _menuStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SkeletonList(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: StateMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Menu gagal dimuat',
                message: 'Periksa koneksi internet atau akses Firestore.',
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];
        final filtered = items.where((item) {
          return _searchQuery.isEmpty ||
              item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: StateMessage(
                icon: Icons.no_meals_rounded,
                title: 'Menu tidak ditemukan',
                message: 'Menu ini belum tersedia di katalog restoran.',
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModernMenuItemCard(
                  item: item,
                  cart: widget.cart,
                  onAdd: () => _addItem(context, item),
                ),
              );
            }, childCount: filtered.length),
          ),
        );
      },
    );
  }
}

// Modern Menu Item Card
class _ModernMenuItemCard extends StatelessWidget {
  final MenuItem item;
  final CartController cart;
  final VoidCallback onAdd;

  const _ModernMenuItemCard({
    required this.item,
    required this.cart,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmeraldColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Dish Photo Container
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FoodImage(
                imageUrl: getFoodItemPhoto(item.name),
                width: 64,
                height: 64,
                borderRadius: 16,
                fit: BoxFit.cover,
                fallbackIcon: Icons.restaurant_menu_rounded,
              ),
            ),
            const SizedBox(width: 14),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: EmeraldColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(item.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: EmeraldColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Control
            ListenableBuilder(
              listenable: cart,
              builder: (context, _) {
                final qty = cart.quantityOf(item.id);
                if (qty == 0) {
                  return InkWell(
                    onTap: cart.isSubmittingOrder ? null : onAdd,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: EmeraldColors.softGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: EmeraldColors.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: EmeraldColors.primaryDark,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: EmeraldColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return QuantityStepper(
                  quantity: qty,
                  onIncrement: cart.isSubmittingOrder ? null : onAdd,
                  onDecrement: cart.isSubmittingOrder
                      ? null
                      : () => cart.decrement(item.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
