import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DuniTheme {
  static ThemeData get lightWarm {
    const primaryColor = Color(0xFFFF8746);
    const peach = Color(0xFFFFD4B5);
    const cream = Color(0xFFFFF0E4);
    const textMain = Color(0xFF6B3A28);
    const textMuted = Color(0xFF9A8E87);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: peach,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
    );
  }
}
