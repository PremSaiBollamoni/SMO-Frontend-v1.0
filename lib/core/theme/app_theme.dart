import 'package:flutter/material.dart';

/// Centralized Theme Configuration — Light mode only
class AppTheme {
  // Deep Teal + Amber palette (industrial, professional, high-contrast)
  static const Color primary = Color(0xFF0F4C5C);
  static const Color primaryVariant = Color(0xFF093A47);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFE8871E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFF5B8C5A);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C2526);
  static const Color surfaceVariant = Color(0xFFE2E8ED);
  static const Color onSurfaceVariant = Color(0xFF5A6A6E);
  static const Color error = Color(0xFFC62828);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF0277BD);
  static const Color warning = Color(0xFFE8871E);

  // Backward-compat aliases (dark theme removed, these map to light values)
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkOnSurface = onSurface;
  static const Color darkSurfaceVariant = surfaceVariant;
  static const Color darkOnSurfaceVariant = onSurfaceVariant;

  static const String _fontFamily = 'sans-serif';

  // Text styles
  static TextStyle get displayLarge => TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, height: 1.2, fontFamily: _fontFamily);
  static TextStyle get displayMedium => TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: onSurface, height: 1.2, fontFamily: _fontFamily);
  static TextStyle get displaySmall => TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, height: 1.2, fontFamily: _fontFamily);
  static TextStyle get headlineLarge => TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface, height: 1.3, fontFamily: _fontFamily);
  static TextStyle get headlineMedium => TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface, height: 1.3, fontFamily: _fontFamily);
  static TextStyle get headlineSmall => TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, height: 1.4, fontFamily: _fontFamily);
  static TextStyle get titleLarge => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, height: 1.4, fontFamily: _fontFamily);
  static TextStyle get titleMedium => TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurface, height: 1.4, fontFamily: _fontFamily);
  static TextStyle get titleSmall => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface, height: 1.4, fontFamily: _fontFamily);
  static TextStyle get bodyLarge => TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.5, fontFamily: _fontFamily);
  static TextStyle get bodyMedium => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.5, fontFamily: _fontFamily);
  static TextStyle get bodySmall => TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurface, height: 1.5, fontFamily: _fontFamily);
  static TextStyle get labelLarge => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onPrimary, height: 1.5, fontFamily: _fontFamily);
  static TextStyle get labelMedium => TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onPrimary, height: 1.5, fontFamily: _fontFamily);
  static TextStyle get labelSmall => TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onPrimary, height: 1.5, fontFamily: _fontFamily);

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary, foregroundColor: onPrimary, elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: _fontFamily),
    shadowColor: primary.withValues(alpha: 0.3),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondary, foregroundColor: onSecondary, elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: _fontFamily),
    shadowColor: secondary.withValues(alpha: 0.3),
  );

  static final ButtonStyle tertiaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: tertiary, foregroundColor: onPrimary, elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: _fontFamily),
    shadowColor: tertiary.withValues(alpha: 0.3),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: _fontFamily),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primary,
    textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: _fontFamily),
  );

  // Input decoration
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryVariant, fontWeight: FontWeight.w500, fontFamily: _fontFamily),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: surfaceVariant, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: surfaceVariant, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error, width: 2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error, width: 2.5)),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: onSurface.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
      BoxShadow(color: onSurface.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
    ],
  );

  // Backward-compat alias
  static BoxDecoration get darkCardDecoration => cardDecoration;

  // Dark input decoration alias (same as light)
  static InputDecoration darkInputDecoration(String label) => inputDecoration(label);

  // App bar theme
  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: primary, foregroundColor: onPrimary, elevation: 0, centerTitle: false,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onPrimary, fontFamily: _fontFamily),
    toolbarHeight: 64,
  );

  // Chip theme
  static ChipThemeData get chipTheme => ChipThemeData(
    backgroundColor: surfaceVariant,
    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurface, fontFamily: _fontFamily),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
  );

  // FAB theme
  static FloatingActionButtonThemeData floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: secondary, foregroundColor: onSecondary,
    elevation: 6, focusElevation: 8, hoverElevation: 8, disabledElevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  // Bottom nav theme
  static BottomNavigationBarThemeData get bottomNavigationBarTheme => BottomNavigationBarThemeData(
    backgroundColor: surface, selectedItemColor: primary, unselectedItemColor: onSurfaceVariant, elevation: 8,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: _fontFamily),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, fontFamily: _fontFamily),
  );

  // Theme data (light only)
  static ThemeData get themeData => ThemeData(
    primaryColor: primary,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary, onPrimary: onPrimary,
      secondary: secondary, onSecondary: onSecondary,
      error: error, onError: onError,
      surface: background, onSurface: onSurface,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: appBarTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    floatingActionButtonTheme: floatingActionButtonTheme,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
    chipTheme: chipTheme,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, height: 1.2),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: onSurface, height: 1.2),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, height: 1.2),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurface, height: 1.4),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onPrimary, height: 1.5),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onPrimary, height: 1.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onPrimary, height: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: surface,
    ),
  );
}

/// Custom Snackbar Utility
class CustomSnackbar {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: AppTheme.onPrimary),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.onPrimary))),
      ]),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
    ));
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error, color: AppTheme.onPrimary),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.onPrimary))),
      ]),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 4),
    ));
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info, color: AppTheme.onPrimary),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.onPrimary))),
      ]),
      backgroundColor: AppTheme.info,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
    ));
  }
}
