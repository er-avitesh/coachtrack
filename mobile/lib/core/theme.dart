// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(AppConstants.primaryColor),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2C2C2E)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(AppConstants.primaryColor), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(AppConstants.primaryColor),
      ),
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(AppConstants.primaryColor),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(AppConstants.bgColor),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(AppConstants.bgColor),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Color(AppConstants.textPrimary),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Color(AppConstants.textPrimary)),
    ),
    cardTheme: CardThemeData(
      color: const Color(AppConstants.cardColor),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(AppConstants.primaryColor), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(AppConstants.primaryColor),
      ),
    ),
  );
}
