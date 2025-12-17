import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Navy blue AI analytics theme
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color secondaryColor = Color(0xFF2E5C8A);
  static const Color accentColor = Color(0xFF3B82F6);

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Text Styles
  static const heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const heading3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const bodyLarge = TextStyle(fontSize: 16);
  static const bodyMedium = TextStyle(fontSize: 14);
  static const bodySmall = TextStyle(fontSize: 12);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);

  // =========================
  // LIGHT THEME
  // =========================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      error: dangerColor,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
    ),
  );

  // =========================
  // DARK THEME
  // =========================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBg,

    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      secondary: secondaryColor,
      surface: darkSurface,
      error: dangerColor,
      background: darkBg,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: darkCard, width: 1),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: darkCard,
      thickness: 1,
    ),
  );

  // =========================
  // HELPERS
  // =========================
  static Color getConfidenceColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return successColor;
      case 'medium':
        return warningColor;
      case 'low':
        return dangerColor;
      default:
        return primaryColor;
    }
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : Colors.white;
  }

  static Color bgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBg
        : const Color(0xFFF8FAFC);
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : Colors.grey.shade200;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey.shade600;
  }
}
