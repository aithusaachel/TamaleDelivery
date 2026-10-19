import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Identity Tokens (Master Build Document Section 6 & D1)
  static const Color midnightNavy = Color(0xFF10264B); // Primary brand & headings
  static const Color clearBlue = Color(0xFF2463EB);    // Action buttons & active controls
  static const Color clearBlueHover = Color(0xFF1D4ED8);
  static const Color blueTint = Color(0xFFEFF6FF);     // Soft blue background tint

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);   // Crisp, clean off-white
  static const Color surface = Color(0xFFFFFFFF);      // Pure white cards & sheets
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Light gray input fills

  // Typography Tokens (WCAG AA/AAA compliant)
  static const Color textPrimary = Color(0xFF0F172A);  // Deep slate navy (maximum clarity)
  static const Color textSecondary = Color(0xFF475569);// High-contrast neutral
  static const Color textMuted = Color(0xFF94A3B8);    // Captions

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Status Colors
  static const Color success = Color(0xFF10B981);      // Emerald green
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);      // Golden amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);        // Red
  static const Color errorBg = Color(0xFFFEF2F2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: clearBlue,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: clearBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
