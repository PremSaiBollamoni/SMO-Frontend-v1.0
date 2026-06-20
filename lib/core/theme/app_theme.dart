import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryVariant = Color(0xFF0F172A);
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

  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkOnSurface = onSurface;
  static const Color darkSurfaceVariant = surfaceVariant;
  static const Color darkOnSurfaceVariant = onSurfaceVariant;

  // Role colors — single source of truth
  static const Color roleOperator = Color(0xFF7B5EA7);
  static const Color roleStore = Color(0xFF00838F);
  static const Color roleQc = Color(0xFF2E7D32);
  static const Color rolePurchase = Color(0xFFE8871E);
  static const Color roleGm = Color(0xFF1565C0);
  static const Color rolePlanner = Color(0xFF5B8C5A);
  static const Color roleEfficiency = Color(0xFF7B61FF);
  static const Color roleOperations = Color(0xFFE65100);
  static const Color roleStations = Color(0xFF00897B);

  static Color roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPERVISOR': return primary;
      case 'HR': case 'ADMIN': return info;
      case 'GM': return roleGm;
      case 'PROCESS PLANNER': return rolePlanner;
      case 'STORE MANAGER': return roleStore;
      case 'QC ENGINEER': case 'QC MANAGER': return roleQc;
      case 'PURCHASE MANAGER': return rolePurchase;
      default: return roleOperator;
    }
  }

  // Text styles
  static TextStyle _t(double size, FontWeight w, {Color c = onSurface, double h = 1.4}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c, height: h);

  static TextStyle get displayLarge => _t(32, FontWeight.w700, h: 1.2);
  static TextStyle get displayMedium => _t(28, FontWeight.w600, h: 1.2);
  static TextStyle get displaySmall => _t(24, FontWeight.w600, h: 1.2);
  static TextStyle get headlineLarge => _t(22, FontWeight.w700, h: 1.3);
  static TextStyle get headlineMedium => _t(20, FontWeight.w700, h: 1.3);
  static TextStyle get headlineSmall => _t(18, FontWeight.w600, h: 1.4);
  static TextStyle get titleLarge => _t(16, FontWeight.w700);
  static TextStyle get titleMedium => _t(15, FontWeight.w600);
  static TextStyle get titleSmall => _t(14, FontWeight.w600);
  static TextStyle get bodyLarge => _t(16, FontWeight.w400, h: 1.5);
  static TextStyle get bodyMedium => _t(14, FontWeight.w400, h: 1.5);
  static TextStyle get bodySmall => _t(12, FontWeight.w400, h: 1.5);
  static TextStyle get labelLarge => _t(14, FontWeight.w600, c: onPrimary);
  static TextStyle get labelMedium => _t(12, FontWeight.w600, c: onPrimary);
  static TextStyle get labelSmall => _t(11, FontWeight.w600, c: onPrimary);

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary, foregroundColor: onPrimary, elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
    shadowColor: primary.withValues(alpha: 0.3),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondary, foregroundColor: onSecondary, elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
    shadowColor: secondary.withValues(alpha: 0.3),
  );

  static final ButtonStyle tertiaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: tertiary, foregroundColor: onPrimary, elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
    shadowColor: tertiary.withValues(alpha: 0.3),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primary,
    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
  );

  // Input decoration
  static InputDecoration inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.plusJakartaSans(color: primaryVariant, fontWeight: FontWeight.w500),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: surfaceVariant, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: surfaceVariant, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error, width: 2)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error, width: 2.5)),
    filled: true, fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );

  // Card decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface, borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: onSurface.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4)),
      BoxShadow(color: onSurface.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
    ],
  );

  static BoxDecoration highlightCardDecoration(Color color) => BoxDecoration(
    color: surface, borderRadius: BorderRadius.circular(16),
    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
  );

  static BoxDecoration get darkCardDecoration => cardDecoration;
  static InputDecoration darkInputDecoration(String label) => inputDecoration(label);

  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: primary, foregroundColor: onPrimary, elevation: 0, centerTitle: false,
    titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: onPrimary),
    toolbarHeight: 52,
  );

  static ChipThemeData get chipTheme => ChipThemeData(
    backgroundColor: surfaceVariant,
    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: onSurface),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
  );

  static FloatingActionButtonThemeData floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: secondary, foregroundColor: onSecondary,
    elevation: 6, focusElevation: 8, hoverElevation: 8, disabledElevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static BottomNavigationBarThemeData get bottomNavigationBarTheme => BottomNavigationBarThemeData(
    backgroundColor: surface, selectedItemColor: primary, unselectedItemColor: onSurfaceVariant, elevation: 8,
    selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12),
  );

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
    textTheme: GoogleFonts.plusJakartaSansTextTheme(const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, height: 1.2),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, height: 1.2),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: onSurface, height: 1.2),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface, height: 1.4),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onPrimary, height: 1.5),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onPrimary, height: 1.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onPrimary, height: 1.5),
    )),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: surface,
    ),
  );
}

class CustomSnackbar {
  static void showSuccess(BuildContext context, String message) => _show(context, message, AppTheme.success, Icons.check_circle);
  static void showError(BuildContext context, String message) => _show(context, message, AppTheme.error, Icons.error, duration: 4);
  static void showInfo(BuildContext context, String message) => _show(context, message, AppTheme.info, Icons.info);

  static void _show(BuildContext context, String message, Color color, IconData icon, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: AppTheme.onPrimary),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.onPrimary))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: Duration(seconds: duration),
    ));
  }
}
