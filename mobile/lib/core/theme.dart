// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
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
    cardTheme: CardTheme(
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
