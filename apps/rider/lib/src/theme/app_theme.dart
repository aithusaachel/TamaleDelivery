import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette - Clean, Modern, High Contrast
  static const Color midnightNavy = Color(0xFF0F172A); // Slate 900
  static const Color deepNavy = Color(0xFF1E293B);     // Slate 800
  static const Color navySurface = Color(0xFF0F172A);
  
  // Brand Blue
  static const Color clearBlue = Color(0xFF2563EB);     // Modern Blue 600
  static const Color clearBlueHover = Color(0xFF1D4ED8);
  static const Color blueTint = Color(0xFFEFF6FF);      // Blue 50

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);    // Crisp Slate 50
  static const Color warmIvory = Color(0xFFF8FAFC);     // Maintained alias
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);  // Slate 100
  static const Color white = Color(0xFFFFFFFF);

  // Typography Colors (WCAG AA/AAA compliant)
  static const Color textPrimary = Color(0xFF0F172A);   // Bold, ultra-clear
  static const Color primaryText = Color(0xFF0F172A);   // Maintained alias
  static const Color textSecondary = Color(0xFF475569); // High contrast neutral
  static const Color secondaryText = Color(0xFF475569); // Maintained alias
  static const Color textMuted = Color(0xFF94A3B8);     // Subtle captions
  static const Color mutedText = Color(0xFF94A3B8);     // Maintained alias

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);        // Slate 200
  static const Color divider = Color(0xFFF1F5F9);

  // Functional Status Colors
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color successBg = Color(0xFFECFDF5);     // Emerald 50
  static const Color successText = Color(0xFF047857);   // Emerald 700

  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color warningBg = Color(0xFFFFFBEB);     // Amber 50
  static const Color warningText = Color(0xFFB45309);   // Amber 700

  static const Color error = Color(0xFFEF4444);         // Red 500
  static const Color errorBg = Color(0xFFFEF2F2);       // Red 50
  static const Color errorText = Color(0xFFB91C1C);     // Red 700

  // Night / Dispatch Active Screen Tokens
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF131C2E);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF2E3E5C);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkSubtext = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: clearBlue,
        onPrimary: white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: white,
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.6,
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
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: clearBlue,
          foregroundColor: white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: clearBlue,
        onPrimary: white,
        surface: darkSurface,
        onSurface: darkText,
        error: error,
        onError: white,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: darkText,
          letterSpacing: -0.6,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: darkText,
          letterSpacing: -0.3,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: darkSubtext,
        ),
      ),
    );
  }
}
