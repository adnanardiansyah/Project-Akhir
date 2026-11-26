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

String _photoUrl(int id, int width) =>
    'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=$width';

String _normalizeName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

const Map<String, int> _restaurantCoverPhotoIds = <String, int>{
  'mie bangladesh': 37048267,
  'hokben - suzuya mall lhokseumawe': 38714625,
  'hokben suzuya mall': 38714625,
  'ayam penyet wong solo lhokseumawe': 37320407,
  'ayam penyet wong solo': 37320407,
  'kedai kopi aceh': 15891300,
};

const Map<String, int> _foodPhotoIds = <String, int>{
  'mie bangladesh': 37173529,
  'mie bangladesh kuah becek': 37173529,
  'mie aceh': 37173529,
  'mie aceh kuah': 37173529,
  'mie aceh goreng': 37106132,
  'mie kuah': 37173529,
  'mie rebus': 37173531,
  'mie rebus bangladesh': 37173529,
  'mie goreng basah daging': 40756021,
  'kari kambing': 28674565,
  'roti cane': 38954055,
  'roti canai': 38954055,
  'martabak telur': 41197492,
  'mie goreng': 37106132,
  'mi goreng': 37106132,
  'mie goreng biasa': 37106132,
  'indomie goreng': 37106132,
  'indomie kuah': 37173529,
  'mie ayam': 37104346,
  'mi ayam': 37104346,
  'chicken teriyaki': 38714625,
  'chicken teriyaki set': 38714625,
  'simple set chicken teriyaki 1': 39083061,
  'hot spicy chicken teriyaki': 6368743,
  'beef teriyaki': 17308547,
  'hot spicy beef teriyaki': 26341193,
  'chicken yakiniku': 13065185,
  'beef yakiniku': 37274310,
  'tori ball': 28371785,
  'ebi furai': 7011610,
  'hokkaido miso ramen reguler': 37415849,
  'spicy ramen reguler': 37415849,
  'teh kotak sosro': 4071422,
  'fresh orange juice': 37026953,
  'naskot ayam penyet': 37076558,
  'ayam penyet': 37076558,
  'ayam geprek': 37076558,
  'paket ayam bakar': 14098784,
  'ayam bakar': 14098784,
  'naskot lombok ijo': 37179941,
  'lombok ijo': 37179941,
  'naskot nila bakar': 37255814,
  'nila bakar': 37255814,
  'nasi goreng ayam': 37173548,
  'nasi goreng': 37173548,
  'cah brokoli': 21482825,
  'tumis kangkung': 7361029,
  'balado cumi': 30749018,
  'nasi putih': 17563535,
  'kopi aceh': 30839009,
  'kopi sanger': 30839009,
  'es kopi susu': 5567620,
  'kopi susu': 5567620,
  'teh tarik': 4071422,
  'es jeruk': 37026953,
  'es jeruk nipis': 37026953,
  'jus jeruk': 37026953,
  'burger': 3219483,
  'pizza': 35760004,
};

/// Mendapatkan URL foto sampul restoran berdasarkan nama atau ID restoran.
String getRestaurantCoverPhoto(String nameOrId) {
  final name = _normalizeName(nameOrId);
  final exactId = _restaurantCoverPhotoIds[name];
  if (exactId != null) return _photoUrl(exactId, 900);

  final isNoodle =
      name.contains('mie') ||
      name.startsWith('mi ') ||
      name.contains(' mi ') ||
      name.contains('ramen') ||
      name.contains('noodle');

  if (name.contains('kopi') ||
      name.contains('sanger') ||
      name.contains('kafe') ||
      name.contains('coffee')) {
    return _photoUrl(15891300, 900);
  }
  if (isNoodle || name.contains('bangladesh') || name.contains('aceh')) {
    return _photoUrl(37048267, 900);
  }
  if (name.contains('hokben') ||
      name.contains('suzuya') ||
      name.contains('teriyaki')) {
    return _photoUrl(38714625, 900);
  }
  if (name.contains('wong solo') ||
      name.contains('ayam') ||
      name.contains('penyet')) {
    return _photoUrl(37320407, 900);
  }
  return _photoUrl(5865071, 900);
}

/// Mendapatkan URL foto hidangan berdasarkan nama menu.
String getFoodItemPhoto(String itemName) {
  final name = _normalizeName(itemName);
  final exactId = _foodPhotoIds[name];
  if (exactId != null) return _photoUrl(exactId, 500);

  if (name.contains('ramen')) return _photoUrl(37415849, 500);

  final isNoodle =
      name.contains('mie') ||
      name.startsWith('mi ') ||
      name.contains(' mi ') ||
      name.contains('noodle');
  if (isNoodle) {
    if (name.contains('goreng')) return _photoUrl(37106132, 500);
    if (name.contains('kuah') ||
        name.contains('becek') ||
        name.contains('aceh') ||
        name.contains('bangladesh')) {
      return _photoUrl(37173529, 500);
    }
    return _photoUrl(37104346, 500);
  }
  if (name.contains('beef') && name.contains('teriyaki')) {
    return _photoUrl(17308547, 500);
  }
  if (name.contains('teriyaki') || name.contains('chicken set')) {
    return _photoUrl(38714625, 500);
  }
  if (name.contains('yakiniku')) {
    return _photoUrl(name.contains('beef') ? 37274310 : 13065185, 500);
  }
  if (name.contains('tori ball')) return _photoUrl(28371785, 500);
  if (name.contains('ebi')) return _photoUrl(7011610, 500);
  if (name.contains('penyet') ||
      name.contains('naskot') ||
      name.contains('geprek')) {
    return _photoUrl(37076558, 500);
  }
  if (name.contains('ayam bakar') || name.contains('bakar')) {
    return _photoUrl(14098784, 500);
  }
  if (name.contains('lombok ijo')) return _photoUrl(37179941, 500);
  if (name.contains('nila')) return _photoUrl(37255814, 500);
  if (name.contains('nasi goreng')) return _photoUrl(37173548, 500);
  if (name.contains('brokoli')) return _photoUrl(21482825, 500);
  if (name.contains('kangkung')) return _photoUrl(7361029, 500);
  if (name.contains('cumi')) return _photoUrl(30749018, 500);
  if (name.contains('kari')) return _photoUrl(28674565, 500);
  if (name.contains('roti')) return _photoUrl(38954055, 500);
  if (name.contains('martabak')) return _photoUrl(41197492, 500);
  if (name.contains('nasi')) return _photoUrl(17563535, 500);
  if (name.contains('es jeruk') ||
      name.contains('jus jeruk') ||
      name.contains('jeruk') ||
      name.contains('orange')) {
    return _photoUrl(37026953, 500);
  }
  if (name.contains('kopi susu')) return _photoUrl(5567620, 500);
  if (name.contains('kopi') ||
      name.contains('sanger') ||
      name.contains('coffee')) {
    return _photoUrl(30839009, 500);
  }
  if (name.contains('teh') || name.contains('tea')) {
    return _photoUrl(4071422, 500);
  }
  if (name.contains('burger')) return _photoUrl(3219483, 500);
  if (name.contains('pizza')) return _photoUrl(35760004, 500);
  return _photoUrl(5865071, 500);
}
