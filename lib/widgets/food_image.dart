import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Helper foto kuliner dan restoran beresolusi tinggi dengan fallback offline yang elegan.
class FoodImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;

  const FoodImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.restaurant_rounded,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _buildFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          final loaded = loadingProgress.cumulativeBytesLoaded;
          final progress = total != null ? loaded / total : null;

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: EmeraldColors.softGreenLight,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  color: EmeraldColors.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EmeraldColors.softGreenLight, EmeraldColors.softGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: EmeraldColors.border, width: 1),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: EmeraldColors.primaryDark,
          size: (height != null && height! < 50) ? 20 : 32,
        ),
      ),
    );
  }
}

/// Mendapatkan URL foto berkualitas tinggi berdasarkan nama atau ID restoran.
String getRestaurantCoverPhoto(String nameOrId) {
  final lower = nameOrId.toLowerCase();
  if (lower.contains('mie') || lower.contains('bangladesh') || lower.contains('aceh')) {
    // Mie Bangladesh / Mie Aceh autentik
    return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&auto=format&fit=crop&q=80';
  } else if (lower.contains('hokben') || lower.contains('suzuya') || lower.contains('teriyaki')) {
    // Bento Jepang HokBen Suzuya
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop&q=80';
  } else if (lower.contains('wong solo') || lower.contains('ayam') || lower.contains('penyet')) {
    // Ayam Penyet Wong Solo
    return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800&auto=format&fit=crop&q=80';
  } else if (lower.contains('kopi') || lower.contains('sanger') || lower.contains('kafe')) {
    // Kopi Aceh / Sanger
    return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&auto=format&fit=crop&q=80';
  }
  // Default foto restoran gourmet
  return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80';
}

/// Mendapatkan URL foto hidangan berdasarkan nama menu.
String getFoodItemPhoto(String itemName) {
  final lower = itemName.toLowerCase();
  if (lower.contains('mie') || lower.contains('bangladesh') || lower.contains('ramen')) {
    return 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=400&auto=format&fit=crop&q=80';
  } else if (lower.contains('teriyaki') || lower.contains('beef') || lower.contains('chicken') && lower.contains('set')) {
    return 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=400&auto=format&fit=crop&q=80';
  } else if (lower.contains('ayam') || lower.contains('penyet') || lower.contains('naskot')) {
    return 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400&auto=format&fit=crop&q=80';
  } else if (lower.contains('kopi') || lower.contains('sanger') || lower.contains('teh') || lower.contains('jus')) {
    return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&auto=format&fit=crop&q=80';
  } else if (lower.contains('burger') || lower.contains('pizza')) {
    return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&auto=format&fit=crop&q=80';
  }
  return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&auto=format&fit=crop&q=80';
}
