import 'package:flutter/material.dart';

// Ikon cadangan untuk resto dengan nama yang belum dikenali
const List<IconData> _foodIcons = [
  Icons.ramen_dining_rounded,
  Icons.lunch_dining_rounded,
  Icons.local_cafe_rounded,
  Icons.rice_bowl_rounded,
  Icons.local_pizza_rounded,
  Icons.bakery_dining_rounded,
];

// Pasangan warna gradasi Emerald Premium untuk latar avatar
const List<List<Color>> _gradients = [
  [Color(0xFF10B981), Color(0xFF047857)], // Emerald Primary
  [Color(0xFF0D9488), Color(0xFF115E59)], // Emerald Teal
  [Color(0xFF16A34A), Color(0xFF14532D)], // Fresh Green
  [Color(0xFF059669), Color(0xFF064E3B)], // Deep Emerald
];

IconData? getRestaurantIcon(String nameOrId) {
  final lower = nameOrId.toLowerCase();
  if (lower.contains('kopi') ||
      lower.contains('sanger') ||
      lower.contains('kafe') ||
      lower.contains('coffee')) {
    return Icons.local_cafe_rounded;
  }
  if (lower.contains('mie') ||
      lower.contains('bangladesh') ||
      lower.contains('aceh') ||
      lower.contains('ramen')) {
    return Icons.ramen_dining_rounded;
  }
  if (lower.contains('hokben') ||
      lower.contains('suzuya') ||
      lower.contains('teriyaki') ||
      lower.contains('bento')) {
    return Icons.lunch_dining_rounded;
  }
  if (lower.contains('wong solo') ||
      lower.contains('ayam') ||
      lower.contains('penyet') ||
      lower.contains('naskot') ||
      lower.contains('geprek')) {
    return Icons.rice_bowl_rounded;
  }
  if (lower.contains('pizza')) return Icons.local_pizza_rounded;
  if (lower.contains('burger')) return Icons.fastfood_rounded;
  if (lower.contains('roti') ||
      lower.contains('bakery') ||
      lower.contains('cake')) {
    return Icons.bakery_dining_rounded;
  }
  return null;
}

// Avatar resto bergradasi dengan ikon; Hero membuatnya berpindah mulus antar layar
class RestaurantAvatar extends StatelessWidget {
  final String restaurantId;
  final String? restaurantName;
  final double size;
  // Dimatikan di daftar yang bisa memuat resto sama berkali-kali (tag Hero harus unik)
  final bool heroEnabled;

  const RestaurantAvatar({
    super.key,
    required this.restaurantId,
    this.restaurantName,
    this.size = 56,
    this.heroEnabled = true,
  });

  // Angka tetap dari id resto agar warna avatar tidak berubah antar sesi
  int get _seed => restaurantId.codeUnits.fold(0, (sum, unit) => sum + unit);

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[_seed % _gradients.length];
    final icon =
        getRestaurantIcon(restaurantName ?? restaurantId) ??
        _foodIcons[_seed % _foodIcons.length];
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
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
    if (!heroEnabled) return avatar;
    return Hero(tag: 'restaurant-avatar-$restaurantId', child: avatar);
  }
}
