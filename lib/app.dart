import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/cart_controller.dart';
import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/restaurant_list_screen.dart';
import 'screens/restaurant/incoming_orders_screen.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/brand_mark.dart';
import 'widgets/logout_button.dart';
import 'widgets/state_message.dart';

// Akar aplikasi; memilih layar berdasarkan status login dan peran
class FoodOrderApp extends StatelessWidget {
  final AppServices services;

  const FoodOrderApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesan Makanan',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      // Status bar transparan untuk semua layar, termasuk yang tanpa AppBar
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyleFor(context),
        child: child!,
      ),
      home: _RoleRouter(services: services),
    );
  }
}

// Mengalihkan ke layar login atau ke pemeriksa profil sesuai status login
class _RoleRouter extends StatefulWidget {
  final AppServices services;

  const _RoleRouter({required this.services});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

// Menyimpan aliran status login agar tidak dibuat ulang tiap build
class _RoleRouterState extends State<_RoleRouter> {
  late final Stream<User?> _authStream = widget.services.auth
      .authStateChanges();
  late StreamSubscription<User?> _authSubscription;
  String? _activeUid;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authStream.listen(_clearKeyOnAccountChange);
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }

  // Key jarak sesi sebelumnya tidak dipakai setelah akun berganti atau keluar
  void _clearKeyOnAccountChange(User? user) {
    final nextUid = user?.uid;
    if (_activeUid == nextUid) return;
    if (_activeUid != null) {
      widget.services.routeDistance.clearPersonalApiKey();
    }
    _activeUid = nextUid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) =>
          _FadeSwitch(child: _buildForAuth(snapshot)),
    );
  }

  // Memilih layar sesuai status login; key berbeda memicu animasi pergantian
  Widget _buildForAuth(AsyncSnapshot<User?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _LoadingScreen(key: ValueKey('auth-loading'));
    }
    final firebaseUser = snapshot.data;
    if (firebaseUser == null) {
      return LoginScreen(
        key: const ValueKey('login'),
        authService: widget.services.auth,
      );
    }
    return _ProfileGate(
      key: ValueKey(firebaseUser.uid),
      uid: firebaseUser.uid,
      services: widget.services,
    );
  }
}

// Membaca profil users/{uid} lalu membuka beranda sesuai peran
class _ProfileGate extends StatefulWidget {
  final String uid;
  final AppServices services;

  const _ProfileGate({super.key, required this.uid, required this.services});

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

// Menyimpan aliran profil dan keranjang milik akun ini; keduanya hilang saat keluar
class _ProfileGateState extends State<_ProfileGate> {
  final CartController _cart = CartController();

  // Galat dicatat sekali per kejadian di aliran, bukan tiap build
  late final Stream<AppUser?> _profileStream = widget.services.auth
      .watchAppUser(widget.uid)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) {
            debugPrint('Gagal memuat profil ${widget.uid}: $error');
            sink.addError(error, stackTrace);
          },
        ),
      );

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _profileStream,
      builder: (context, snapshot) =>
          _FadeSwitch(child: _buildForProfile(snapshot)),
    );
  }

  // Memilih beranda sesuai peran, atau layar masalah bila profil tidak valid
  Widget _buildForProfile(AsyncSnapshot<AppUser?> snapshot) {
    if (snapshot.hasError) {
      return _ProfileProblemScreen(
        key: const ValueKey('profile-error'),
        authService: widget.services.auth,
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat profil',
        message: 'Periksa koneksi internet, lalu keluar dan masuk lagi.',
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _LoadingScreen(key: ValueKey('profile-loading'));
    }
    final appUser = snapshot.data;
    if (appUser == null) {
      return _ProfileProblemScreen(
        key: const ValueKey('profile-missing'),
        authService: widget.services.auth,
        icon: Icons.person_off_outlined,
        title: 'Profil tidak ditemukan',
        message:
            'Profil akun ini belum tersedia atau perannya tidak dikenal. '
            'Hubungi pengelola aplikasi.',
      );
    }
    return switch (appUser.role) {
      UserRole.customer => RestaurantListScreen(
        key: const ValueKey('customer-home'),
        user: appUser,
        services: widget.services,
        cart: _cart,
      ),
      UserRole.restaurant => IncomingOrdersScreen(
        key: const ValueKey('restaurant-home'),
        user: appUser,
        services: widget.services,
      ),
    };
  }
}

// Pergantian layar akar dengan efek pudar yang halus
class _FadeSwitch extends StatelessWidget {
  final Widget child;

  const _FadeSwitch({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionMedium,
      switchInCurve: motionCurve,
      switchOutCurve: motionCurve,
      child: child,
    );
  }
}

// Layar tunggu selama data login atau profil dimuat
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(),
            SizedBox(height: 32),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Layar bila profil tidak ada, perannya tidak dikenal, atau gagal dimuat
class _ProfileProblemScreen extends StatelessWidget {
  final AuthService authService;
  final IconData icon;
  final String title;
  final String message;

  const _ProfileProblemScreen({
    super.key,
    required this.authService,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [LogoutButton(authService: authService)]),
      body: StateMessage(icon: icon, title: title, message: message),
    );
  }
}
