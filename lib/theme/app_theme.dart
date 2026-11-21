import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Warna merek: hijau-teal yang memberi kesan segar dan profesional.
const Color brandGreen = Color(0xFF0F766E);

// Hijau lebih gelap untuk tombol utama dan label merek.
const Color brandGreenDeep = Color(0xFF115E59);

// Hijau semantik untuk pembayaran berhasil.
const Color successGreen = Color(0xFF16845B);

// Jari-jari sudut standar untuk kartu dan kolom isian
const double cardRadius = 20;
const double fieldRadius = 16;

// Ukuran tombol di dialog; tombol utama tema selebar layar sehingga perlu ditimpa di dialog
const Size dialogButtonMinSize = Size(96, 44);

// Durasi dan kurva animasi yang dipakai seragam di seluruh aplikasi
const Duration motionShort = Duration(milliseconds: 220);
const Duration motionMedium = Duration(milliseconds: 420);
const Curve motionCurve = Curves.easeOutCubic;

// Tema terang aplikasi
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

// Tema gelap aplikasi
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

// Menyusun tema lengkap dari satu warna merek untuk terang atau gelap
ThemeData _buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final seeded = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  // Mode terang: oranye cerah senada logo, tetap terbaca dengan teks putih tebal
  final primaryScheme = isLight
      ? seeded.copyWith(primary: brandGreenDeep, onPrimary: Colors.white)
      : seeded;
  // Tombol tonal dan chip memakai oranye tipis di atas latar, senada dengan aksen
  final scheme = primaryScheme.copyWith(
    secondaryContainer: Color.alphaBlend(
      primaryScheme.primary.withValues(alpha: 0.12),
      primaryScheme.surface,
    ),
    onSecondaryContainer: primaryScheme.primary,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
  );
  final text = base.textTheme;

  return base.copyWith(
    scaffoldBackgroundColor: isLight
        ? const Color(0xFFF6F8F5)
        : scheme.surface,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: _overlayStyle(brightness),
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
        textStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      space: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

// Status bar transparan dengan ikon kontras terhadap latar
SystemUiOverlayStyle _overlayStyle(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final base = isLight
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light;
  return base.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: isLight
        ? const Color(0xFFF6F8F5)
        : const Color(0xFF121A19),
    systemNavigationBarIconBrightness: isLight
        ? Brightness.dark
        : Brightness.light,
  );
}

// Gaya status bar untuk layar tanpa AppBar, mengikuti tema yang aktif
SystemUiOverlayStyle overlayStyleFor(BuildContext context) =>
    _overlayStyle(Theme.of(context).brightness);
