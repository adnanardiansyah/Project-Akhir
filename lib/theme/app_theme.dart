import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design System: EMERALD PREMIUM — Modern Food Delivery Experience.
/// Spesifikasi warna resmi sesuai Master Prompt:
class EmeraldColors {
  // Identitas Utama
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryDeep = Color(0xFF064E3B); // Emerald 900
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color accent = Color(0xFF34D399); // Emerald 400
  static const Color softGreen = Color(0xFFD1FAE5); // Emerald 100
  static const Color softGreenLight = Color(0xFFECFDF5); // Emerald 50

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimary = Color(0xFF17211D); // Deep Slate Forest
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Semantik & Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

// Kompatibilitas konstanta lama untuk kode yang sudah ada
const Color brandGreen = EmeraldColors.primary;
const Color brandGreenDeep = EmeraldColors.primaryDark;
const Color successGreen = EmeraldColors.success;

// Geometri & Komponen Token
const double cardRadius = 20.0;
const double fieldRadius = 16.0;
const double pillRadius = 50.0;

// Ukuran tombol di dialog
const Size dialogButtonMinSize = Size(96, 44);

// Durasi & Kurva Animasi
const Duration motionShort = Duration(milliseconds: 200);
const Duration motionMedium = Duration(milliseconds: 380);
const Curve motionCurve = Curves.easeOutCubic;

// Soft Shadows Emerald Premium
List<BoxShadow> get emeraldCardShadow => [
  BoxShadow(
    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
    blurRadius: 18,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];

List<BoxShadow> get emeraldElevatedShadow => [
  BoxShadow(
    color: EmeraldColors.primary.withValues(alpha: 0.16),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
  BoxShadow(
    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

// Tema terang aplikasi
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

// Tema gelap aplikasi
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: EmeraldColors.primary,
    onPrimary: Colors.white,
    primaryContainer: EmeraldColors.softGreen,
    onPrimaryContainer: EmeraldColors.primaryDeep,
    secondary: EmeraldColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: EmeraldColors.softGreenLight,
    onSecondaryContainer: EmeraldColors.primaryDark,
    tertiary: EmeraldColors.accent,
    onTertiary: EmeraldColors.textPrimary,
    error: EmeraldColors.error,
    onError: Colors.white,
    surface: isLight ? EmeraldColors.surface : const Color(0xFF131D1A),
    onSurface: isLight ? EmeraldColors.textPrimary : const Color(0xFFF1F5F9),
    surfaceContainerLowest: isLight ? Colors.white : const Color(0xFF0D1412),
    surfaceContainerLow: isLight
        ? EmeraldColors.surface
        : const Color(0xFF16221E),
    surfaceContainer: isLight
        ? EmeraldColors.surfaceMuted
        : const Color(0xFF1B2B26),
    surfaceContainerHigh: isLight
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF22352F),
    surfaceContainerHighest: isLight
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF2A423A),
    outline: EmeraldColors.border,
    outlineVariant: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF263C35),
    shadow: const Color(0xFF0F172A).withValues(alpha: 0.08),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: isLight
        ? EmeraldColors.background
        : const Color(0xFF0B1110),
  );

  final text = base.textTheme;

  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        letterSpacing: -0.8,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.3,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        fontSize: 20,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      titleSmall: text.titleSmall?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        color: EmeraldColors.textSecondary,
        fontSize: 14,
      ),
      bodyLarge: text.bodyLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
      bodyMedium: text.bodyMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w400,
        color: isLight ? EmeraldColors.textSecondary : const Color(0xFF94A3B8),
        fontSize: 14,
      ),
      bodySmall: text.bodySmall?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w400,
        color: isLight ? EmeraldColors.textTertiary : const Color(0xFF64748B),
        fontSize: 12,
      ),
      labelLarge: text.labelLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
      labelMedium: text.labelMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      labelSmall: text.labelSmall?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isLight
          ? EmeraldColors.surface
          : const Color(0xFF131D1A),
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: _overlayStyle(brightness),
      titleTextStyle: text.titleLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        fontSize: 19,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isLight ? EmeraldColors.surface : const Color(0xFF16221E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: isLight ? EmeraldColors.border : const Color(0xFF263C35),
          width: 1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? EmeraldColors.surface : const Color(0xFF1A2824),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: EmeraldColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: EmeraldColors.primary,
      suffixIconColor: EmeraldColors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: EmeraldColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: EmeraldColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: EmeraldColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: EmeraldColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: EmeraldColors.error, width: 1.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: EmeraldColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: EmeraldColors.primary,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
        side: const BorderSide(color: EmeraldColors.border, width: 1.2),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EmeraldColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: EmeraldColors.textPrimary,
      contentTextStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(
      color: EmeraldColors.border,
      space: 1,
      thickness: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

SystemUiOverlayStyle _overlayStyle(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
    statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: isLight
        ? EmeraldColors.background
        : const Color(0xFF0B1110),
    systemNavigationBarIconBrightness: isLight
        ? Brightness.dark
        : Brightness.light,
  );
}

SystemUiOverlayStyle overlayStyleFor(BuildContext context) =>
    _overlayStyle(Theme.of(context).brightness);
