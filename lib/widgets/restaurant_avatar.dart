import 'package:flutter/material.dart';

// Ikon makanan yang dipilih tetap per resto agar tiap resto punya ciri
const List<IconData> _foodIcons = [
  Icons.ramen_dining_rounded,
  Icons.lunch_dining_rounded,
  Icons.local_cafe_rounded,
  Icons.rice_bowl_rounded,
  Icons.local_pizza_rounded,
  Icons.bakery_dining_rounded,
];

// Pasangan warna gradasi hangat untuk latar avatar
const List<List<Color>> _gradients = [
  [Color(0xFFFF8A3D), Color(0xFFF2541B)],
  [Color(0xFFFFB547), Color(0xFFF2811D)],
  [Color(0xFFFF7A6B), Color(0xFFE5484D)],
  [Color(0xFFF7A35C), Color(0xFFD9622B)],
];

// Avatar resto bergradasi dengan ikon; Hero membuatnya berpindah mulus antar layar
class RestaurantAvatar extends StatelessWidget {
  final String restaurantId;
  final double size;
  // Dimatikan di daftar yang bisa memuat resto sama berkali-kali (tag Hero harus unik)
  final bool heroEnabled;

  const RestaurantAvatar({
    super.key,
    required this.restaurantId,
    this.size = 56,
    this.heroEnabled = true,
  });

  // Angka tetap dari id resto agar pilihan ikon dan warna tidak berubah antar sesi
  int get _seed => restaurantId.codeUnits.fold(0, (sum, unit) => sum + unit);

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[_seed % _gradients.length];
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(
        _foodIcons[_seed % _foodIcons.length],
        color: Colors.white,
        size: size * 0.5,
      ),
    );
    if (!heroEnabled) return avatar;
    return Hero(tag: 'restaurant-avatar-$restaurantId', child: avatar);
  }
}
