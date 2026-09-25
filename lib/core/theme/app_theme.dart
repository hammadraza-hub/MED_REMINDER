import 'package:flutter/material.dart';

class AppTheme {
  // App Main Colors
  static const Color primaryGreen = Color(0xFF006B4D);
  static const Color darkNavy = Color(0xFF0A334A);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFCFD8DC);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBg,

      // Text Formatting
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: darkNavy,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: darkNavy,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkNavy, width: 1.5),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
