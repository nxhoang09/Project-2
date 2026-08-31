import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryLight = Color(0xFF00327D); 
  static const Color primaryDark = Color(0xFFB1C5FF);  
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceDark = Color(0xFF191C1D);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF111418); 
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryLight,
      surface: surfaceLight,
      background: backgroundLight,
      onSurface: const Color(0xFF191C1D), // Text color
      surfaceVariant: const Color(0xFFE1E3E4), // Input background
    ),
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryDark,
      surface: surfaceDark,
      background: backgroundDark,
      onSurface: const Color(0xFFE1E3E4), // Text color dark
      surfaceVariant: const Color(0xFF2E3132), // Input background dark
      onPrimary: const Color(0xFF001946), // Chữ trên nút ở Dark mode
    ),
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
  );
}