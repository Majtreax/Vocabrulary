import 'package:flutter/material.dart';

// APPLICATION THEME CONFIGURATION AND PALETTE
class AppTheme {
  // COLOR PALETTE CONSTANTS
  static const darkBackground = Color(0xFF0A0A0A);
  static const surfaceColor = Color(0xFF1E1E1E);
  static const primaryColor = Color(0xFFBB86FC);
  static const secondaryColor = Color(0xFF03DAC6);

  // GLOBAL DARK THEME CONFIGURATION
  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'Roboto',
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
    ),
  );

  // BACKGROUND CONTAINER DECORATION
  static const backgroundGradient = BoxDecoration(
    color: Color(0xFF14141C),
  );

  // UNIFIED CARD GRADIENT PALETTE
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF252538),
    ],
  );

  // UNIFIED BOTTOM SHEET BACKGROUND GRADIENT
  static const sheetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1C1C26),
      Color(0xFF121218),
    ],
  );

  // UNIFIED CARD DECORATION FACTORY
  static BoxDecoration cardDecoration({
    double borderRadius = 20,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(color: const Color(0x20FFFFFF), width: 1.0),
      boxShadow: boxShadow ?? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
