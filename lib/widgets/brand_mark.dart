import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Logo aplikasi: Ikon makanan premium bergradasi Emerald dengan bayangan lembut
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
          colors: [EmeraldColors.secondary, EmeraldColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: EmeraldColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.15),
          ),
          BoxShadow(
            color: EmeraldColors.accent.withValues(alpha: 0.15),
            blurRadius: size * 0.1,
            offset: Offset(0, -size * 0.04),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}
