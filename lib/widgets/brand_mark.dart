import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Logo aplikasi: ikon makanan dalam kotak bergradasi oranye
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A4D), brandOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: brandOrange.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
