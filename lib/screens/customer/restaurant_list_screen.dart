import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/cart_controller.dart';
import '../../models/app_user.dart';
import '../../models/restaurant.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/food_image.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/pressable_card.dart';
import '../../widgets/restaurant_avatar.dart';
import '../../widgets/route_api_key_button.dart';
import '../../widgets/route_distance_label.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/state_message.dart';
import '../auth/partner_registration_screen.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';

/// Halaman Utama Pelanggan dengan Konsep Desain Emerald Premium.
/// Dilengkapi Navigation Bar 5 Tab: Home, Explore, Cart, Orders, Profile.
class RestaurantListScreen extends StatefulWidget {
  final AppUser user;
  final AppServices services;
  final CartController cart;

  const RestaurantListScreen({
    super.key,
    required this.user,
    required this.services,
    required this.cart,
  });

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  // Aliran disimpan agar mengetik pencarian tidak memutus langganan Firestore
  late Stream<List<Restaurant>> _restaurantsStream = widget.services.restaurants
      .watchRestaurants()
      .asBroadcastStream();

  // Banner carousel state
  late final PageController _bannerController = PageController();
  int _activeBannerIndex = 0;
  Timer? _bannerTimer;

  static const List<_CategoryItem> _categories = [
    _CategoryItem(name: 'Semua', icon: Icons.grid_view_rounded),
    _CategoryItem(name: 'Mie Aceh', icon: Icons.ramen_dining_rounded),
    _CategoryItem(name: 'Kopi & Teh', icon: Icons.local_cafe_rounded),
    _CategoryItem(name: 'Ayam Penyet', icon: Icons.restaurant_rounded),
    _CategoryItem(name: 'Cepat Saji', icon: Icons.lunch_dining_rounded),
    _CategoryItem(name: 'Minuman Dingin', icon: Icons.local_drink_rounded),
  ];

  static const List<_PromoBannerData> _promos = [
    _PromoBannerData(
      tag: 'KULINER KHAS ACEH',
      title: 'Diskon 25% Mie Bangladesh',
      subtitle: 'Cita rasa legendaris kuah becek khas Lhokseumawe',
      icon: Icons.ramen_dining_rounded,
      gradient: [Color(0xFF059669), Color(0xFF047857)],
    ),
    _PromoBannerData(
      tag: 'GRATIS ONGKIR',
      title: 'Pesan Dari Mana Saja',
      subtitle: 'Rute jalan presisi via OpenRouteService & pelacakan live',
      icon: Icons.delivery_dining_rounded,
      gradient: [Color(0xFF0D9488), Color(0xFF115E59)],
    ),
    _PromoBannerData(
      tag: 'RESTO TERVERIFIKASI',
      title: 'Jaminan Rasa & Kualitas',
      subtitle: 'Pilihan resto terbaik siap melayani pesanan Anda',
      icon: Icons.verified_rounded,
      gradient: [Color(0xFF16A34A), Color(0xFF064E3B)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_activeBannerIndex + 1) % _promos.length;
      _activeBannerIndex = next;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // Tarik ke bawah menyegarkan GPS dan membuka aliran Firestore yang baru
  Future<void> _refreshData() async {
    await widget.services.location.refreshCurrentLocation();
    if (!mounted) return;
    setState(() {
      _restaurantsStream = widget.services.restaurants
          .watchRestaurants()
          .asBroadcastStream();
    });
  }

  void _openMenu(BuildContext context, Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          restaurant: restaurant,
          user: widget.user,
          services: widget.services,
          cart: widget.cart,
        ),
      ),
    );
  }

  void _openPartnerRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartnerRegistrationScreen(
          services: widget.services,
          applicant: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveCart = !widget.cart.isEmpty && _currentTab != 2;

    return Scaffold(
      backgroundColor: EmeraldColors.background,
      body: Stack(
        children: [
          // Konten Tab Utama
          IndexedStack(
            index: _currentTab,
            children: [
              _buildHomeTab(context),
              _buildExploreTab(context),
              _buildCartTab(context),
              _buildOrdersTab(context),
              _buildProfileTab(context),
            ],
          ),

          // Floating Cart Bar (muncul jika ada menu di keranjang dan bukan di tab Cart)
          if (hasActiveCart)
            Positioned(
              left: 0,
              right: 0,
              bottom: 84,
              child: CartBar(
                cart: widget.cart,
                onOpen: () => setState(() => _currentTab = 2),
              ),
            ),

          // Modern Emerald Floating Bottom Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: HOME PAGE (FLAGSHIP VIEW)
  // ==========================================
  Widget _buildHomeTab(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: EmeraldColors.primary,
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Header: Greeting, Delivery Location, Notifications
            SliverToBoxAdapter(child: _buildHomeHeader(context)),

            // 2. Search Bar Modern
            SliverToBoxAdapter(child: _buildSearchBar()),

            // 3. Promotional Carousel Banner
            SliverToBoxAdapter(child: _buildPromoCarousel()),

            // 4. Food Categories (Horizontal Scrolling)
            SliverToBoxAdapter(child: _buildFoodCategories()),

            // 5. Section: Featured Restaurants
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restoran Pilihan di Lhokseumawe',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: EmeraldColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mitra resmi terverifikasi dengan menu autentik',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: EmeraldColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentTab = 1),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Row(
                        children: [
                          Text('Lihat Semua'),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Resto Cards List (Filtered by Category & Search)
            _buildRestaurantSliverList(),

            // 6. Section: Popular Dishes Showcase
            SliverToBoxAdapter(child: _buildPopularDishesSection(context)),

            // Extra bottom spacing agar tidak tertutup floating bar
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }

  // 1. Home Header
  Widget _buildHomeHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi ☀️'
        : hour < 15
        ? 'Selamat Siang 🌤️'
        : hour < 18
        ? 'Selamat Sore 🌅'
        : 'Selamat Malam 🌙';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Delivery Location Pill
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await widget.services.location.refreshCurrentLocation();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi GPS diperbarui.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EmeraldColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KIRIM KE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: EmeraldColors.primaryDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Lhokseumawe, Aceh',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: EmeraldColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: EmeraldColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Route API Key Button
              RouteApiKeyButton(service: widget.services.routeDistance),

              // Partner application shortcut
              IconButton(
                tooltip: 'Daftar sebagai mitra',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: EmeraldColors.border),
                ),
                icon: const Icon(
                  Icons.handshake_outlined,
                  color: EmeraldColors.primary,
                  size: 20,
                ),
                onPressed: _openPartnerRegistration,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmeraldColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.displayName.isNotEmpty
                          ? widget.user.displayName
                          : 'Foodies Lhokseumawe',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: EmeraldColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: EmeraldColors.softGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: EmeraldColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: EmeraldColors.primary,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Emerald Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: EmeraldColors.primaryDeep,
                          ),
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
    );
  }

  // 2. Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: EmeraldColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          decoration: InputDecoration(
            hintText: 'Cari mie aceh, kopi, teriyaki, ayam...',
            hintStyle: const TextStyle(
              color: EmeraldColors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: EmeraldColors.primary,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : const Icon(
                    Icons.tune_rounded,
                    color: EmeraldColors.textSecondary,
                    size: 20,
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // 3. Promotional Carousel Banner
  Widget _buildPromoCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) {
              if (_activeBannerIndex != idx && mounted) {
                setState(() => _activeBannerIndex = idx);
              }
            },
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: promo.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: promo.gradient.first.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background circular pattern
                      Positioned(
                        right: -24,
                        bottom: -32,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 24,
                        child: Icon(
                          promo.icon,
                          size: 78,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),

                      // Banner Content
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                promo.tag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promos.length, (idx) {
            final isActive = idx == _activeBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? EmeraldColors.primary : EmeraldColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 4. Food Categories Bar
  Widget _buildFoodCategories() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == cat.name;

            return InkWell(
              onTap: () => setState(() => _selectedCategory = cat.name),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? EmeraldColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? EmeraldColors.primary
                        : EmeraldColors.border,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: EmeraldColors.primary.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 17,
                      color: isSelected
                          ? Colors.white
                          : EmeraldColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : EmeraldColors.textPrimary,
                      ),
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

  // 5. Resto Sliver List
  Widget _buildRestaurantSliverList() {
    return StreamBuilder<List<Restaurant>>(
      stream: _restaurantsStream,
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
                title: 'Gagal memuat restoran',
                message: 'Periksa koneksi internet atau akses Firestore.',
              ),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = all.where((resto) {
          final queryMatch =
              _searchQuery.isEmpty ||
              resto.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              resto.address.toLowerCase().contains(_searchQuery.toLowerCase());

          final categoryMatch =
              _selectedCategory == 'Semua' ||
              _categoryMatchesRestaurant(_selectedCategory, resto.name);

          return queryMatch && categoryMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: StateMessage(
                icon: Icons.search_off_rounded,
                title: 'Restoran tidak ditemukan',
                message:
                    'Coba pilih kategori lain atau gunakan kata kunci pencarian berbeda.',
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final restaurant = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModernRestaurantCard(
                  restaurant: restaurant,
                  services: widget.services,
                  onTap: () => _openMenu(context, restaurant),
                ),
              );
            }, childCount: filtered.length),
          ),
        );
      },
    );
  }

  // 6. Popular Dishes Section
  Widget _buildPopularDishesSection(BuildContext context) {
    // Menu unggulan lokal Lhokseumawe yang dipadankan dengan data restoran nyata
    final popularDishes = [
      _PopularDish(
        name: 'Mie Bangladesh Kuah Becek',
        category: 'Khas Aceh',
        price: 26000,
        restoName: 'Mie Bangladesh',
        icon: Icons.ramen_dining_rounded,
        rating: 4.9,
      ),
      _PopularDish(
        name: 'Chicken Teriyaki',
        category: 'Jepang',
        price: 31819,
        restoName: 'HokBen - Suzuya Mall Lhokseumawe',
        icon: Icons.lunch_dining_rounded,
        rating: 4.8,
      ),
      _PopularDish(
        name: 'Naskot Ayam Penyet',
        category: 'Ayam & Nasi',
        price: 47300,
        restoName: 'Ayam Penyet Wong Solo Lhokseumawe',
        icon: Icons.restaurant_rounded,
        rating: 4.8,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Terfavorit Warga',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EmeraldColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paling sering dipesan dengan kepuasan tertinggi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EmeraldColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFEA580C),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal list of popular dishes
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popularDishes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final dish = popularDishes[index];
                return Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: EmeraldColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food photo at top
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: FoodImage(
                          imageUrl: getFoodItemPhoto(dish.name),
                          width: 170,
                          height: 95,
                          borderRadius: 0,
                          fit: BoxFit.cover,
                          fallbackIcon: dish.icon,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFD97706),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${dish.rating}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dish.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: EmeraldColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dish.restoName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: EmeraldColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatRupiah(dish.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: EmeraldColors.primaryDark,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _currentTab = 1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: EmeraldColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: EXPLORE PAGE
  // ==========================================
  Widget _buildExploreTab(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: EmeraldColors.primary,
        onRefresh: _refreshData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eksplor Kuliner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: EmeraldColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Semua restoran dan tempat makan di Lhokseumawe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: EmeraldColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  RouteApiKeyButton(service: widget.services.routeDistance),
                ],
              ),
            ),
            _buildSearchBar(),
            _buildFoodCategories(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Restaurant>>(
                stream: _restaurantsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SkeletonList(),
                    );
                  }
                  final all = snapshot.data ?? [];
                  final filtered = all.where((r) {
                    final queryMatch =
                        _searchQuery.isEmpty ||
                        r.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        r.address.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    final categoryMatch =
                        _selectedCategory == 'Semua' ||
                        _categoryMatchesRestaurant(_selectedCategory, r.name);
                    return queryMatch && categoryMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: StateMessage(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak ada restoran ditemukan',
                        message: 'Coba cari dengan kata kunci lain.',
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final r = filtered[idx];
                      return _ModernRestaurantCard(
                        restaurant: r,
                        services: widget.services,
                        onTap: () => _openMenu(context, r),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: CART PAGE
  // ==========================================
  Widget _buildCartTab(BuildContext context) {
    return CartScreen(
      user: widget.user,
      services: widget.services,
      cart: widget.cart,
    );
  }

  // ==========================================
  // TAB 3: ORDERS PAGE
  // ==========================================
  Widget _buildOrdersTab(BuildContext context) {
    return MyOrdersScreen(user: widget.user, services: widget.services);
  }

  // ==========================================
  // TAB 4: PROFILE PAGE
  // ==========================================
  Widget _buildProfileTab(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EmeraldColors.primaryDeep, EmeraldColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: EmeraldColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 31,
                      backgroundColor: EmeraldColors.softGreen,
                      child: Text(
                        widget.user.displayName.isNotEmpty
                            ? widget.user.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: EmeraldColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.displayName.isNotEmpty
                              ? widget.user.displayName
                              : 'Pengguna',
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Peran: Pelanggan (Customer)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Kemitraan
            _buildProfileSectionTitle('Kemitraan & Peluang'),
            _buildProfileMenuTile(
              icon: Icons.handshake_outlined,
              title: 'Daftar sebagai Mitra Restoran / Kurir',
              subtitle: 'Kembangkan usaha kuliner Anda bersama kami',
              onTap: _openPartnerRegistration,
            ),

            const SizedBox(height: 18),

            // Section: Layanan & Integrasi
            _buildProfileSectionTitle('Integrasi Layanan'),
            _buildProfileMenuTile(
              icon: Icons.key_rounded,
              title: 'API Key OpenRouteService',
              subtitle: 'Atur token sesi untuk kalkulasi jarak jalan raya',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('API Key ORS'),
                    content: const Text(
                      'Masukkan API Key HeiGIT OpenRouteService milik Anda untuk sesi ini.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildProfileMenuTile(
              icon: Icons.my_location_rounded,
              title: 'Cek Status GPS & Lokasi',
              subtitle: 'Pastikan izin lokasi akurat telah diaktifkan',
              onTap: () async {
                final res = await widget.services.location
                    .refreshCurrentLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res.location != null
                            ? 'GPS Aktif: ${res.location!.latitude.toStringAsFixed(4)}, ${res.location!.longitude.toStringAsFixed(4)}'
                            : 'Gagal membaca GPS. Aktifkan lokasi di pengaturan.',
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 18),

            // Section: Informasi
            _buildProfileSectionTitle('Tentang Aplikasi'),
            _buildProfileMenuTile(
              icon: Icons.info_outline_rounded,
              title: 'Food Order Lhokseumawe v1.0.0',
              subtitle: 'Project Akhir Komputasi Bergerak — TRKJ 3B PNL',
              onTap: null,
            ),

            const SizedBox(height: 24),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EmeraldColors.border),
              ),
              child: LogoutButton(authService: widget.services.auth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: EmeraldColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmeraldColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EmeraldColors.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: EmeraldColors.primary, size: 22),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: EmeraldColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: EmeraldColors.textSecondary,
            ),
          ),
          trailing: onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: EmeraldColors.textSecondary,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }

  // ==========================================
  // FLOATING BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = constraints.maxWidth >= 360;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: EmeraldColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda', showLabels),
              _buildNavItem(1, Icons.explore_rounded, 'Eksplor', showLabels),
              _buildCartNavItem(2, showLabels),
              _buildNavItem(
                3,
                Icons.receipt_long_rounded,
                'Pesanan',
                showLabels,
              ),
              _buildNavItem(4, Icons.person_rounded, 'Profil', showLabels),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool showLabels,
  ) {
    final isSelected = _currentTab == index;

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? EmeraldColors.softGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? EmeraldColors.primary
                  : EmeraldColors.textSecondary,
            ),
            if (isSelected && showLabels) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: EmeraldColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartNavItem(int index, bool showLabels) {
    final isSelected = _currentTab == index;

    return ListenableBuilder(
      listenable: widget.cart,
      builder: (context, _) {
        final count = widget.cart.totalQuantity;

        return InkWell(
          onTap: () => setState(() => _currentTab = index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 14 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? EmeraldColors.softGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: EmeraldColors.primary,
                  textColor: Colors.white,
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    size: 22,
                    color: isSelected
                        ? EmeraldColors.primary
                        : EmeraldColors.textSecondary,
                  ),
                ),
                if (isSelected && showLabels) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Keranjang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: EmeraldColors.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _categoryMatchesRestaurant(String category, String restoName) {
    final lower = restoName.toLowerCase();
    return switch (category) {
      'Mie Aceh' => lower.contains('mie') || lower.contains('aceh'),
      'Kopi & Teh' => lower.contains('kopi') || lower.contains('kedai'),
      'Ayam Penyet' =>
        lower.contains('ayam') ||
            lower.contains('penyet') ||
            lower.contains('solo'),
      'Cepat Saji' =>
        lower.contains('hokben') ||
            lower.contains('burger') ||
            lower.contains('pizza'),
      'Minuman Dingin' =>
        lower.contains('kopi') ||
            lower.contains('teh') ||
            lower.contains('jus'),
      _ => true,
    };
  }
}

// ==========================================
// KARTU RESTORAN MODERN EMERALD PREMIUM
// ==========================================
class _ModernRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final AppServices services;
  final VoidCallback onTap;

  const _ModernRestaurantCard({
    required this.restaurant,
    required this.services,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return PressableCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto restoran sebagai hero banner dengan overlay chip
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto restoran dari Unsplash via FoodImage
                  FoodImage(
                    imageUrl: getRestaurantCoverPhoto(restaurant.name),
                    height: 130,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                  // Dark gradient overlay agar teks dan badge terlihat kontras
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x33000000), Color(0x99000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Chip Buka (top-left)
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EmeraldColors.success,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Buka',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Chip Rating (top-right)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFBBF24),
                            size: 14,
                          ),
                          SizedBox(width: 3),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Avatar restoran menempel di bawah foto (bottom-left)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: RestaurantAvatar(
                      restaurantId: restaurant.id,
                      restaurantName: restaurant.name,
                      size: 46,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant Info Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: EmeraldColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: EmeraldColors.textSecondary,
                    ),
                  ],
                ),
                if (restaurant.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: EmeraldColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: EmeraldColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Driving distance via OpenRouteService
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RouteDistanceLabel(
                        services: services,
                        destinationKey:
                            '${restaurant.id}:${restaurant.location.latitude},'
                            '${restaurant.location.longitude}',
                        loadDestination: () async => restaurant.location,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EmeraldColors.softGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Lihat Menu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: EmeraldColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Models
class _CategoryItem {
  final String name;
  final IconData icon;
  const _CategoryItem({required this.name, required this.icon});
}

class _PromoBannerData {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  const _PromoBannerData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class _PopularDish {
  final String name;
  final String category;
  final int price;
  final String restoName;
  final IconData icon;
  final double rating;
  const _PopularDish({
    required this.name,
    required this.category,
    required this.price,
    required this.restoName,
    required this.icon,
    required this.rating,
  });
}
