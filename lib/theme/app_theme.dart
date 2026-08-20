import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00875A); // Gully Green / Emerald
  static const Color primaryDark = Color(0xFF064E3B);  // Deep Forest Green
  static const Color accentColor = Color(0xFF10B981);   // Bright Mint Emerald
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF0F172A); // High contrast slate dark
  static const Color textSecondaryColor = Color(0xFF334155); // Crisp secondary dark text

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF0B1912);
  static const Color darkCardColor = Color(0xFF13281E);
  static const Color darkInputColor = Color(0xFF1C382B);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      visualDensity: VisualDensity.compact,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textPrimaryColor, fontSize: 22),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textPrimaryColor, fontSize: 16),
        titleSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textPrimaryColor, fontSize: 14),
        bodyLarge: GoogleFonts.inter(fontSize: 14, color: textPrimaryColor, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.inter(fontSize: 13, color: textPrimaryColor, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondaryColor, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.inter(color: textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      visualDensity: VisualDensity.compact,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      canvasColor: darkCardColor,
      cardColor: darkCardColor,
      dividerColor: Colors.white12,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: accentColor,
        surface: darkCardColor,
        onSurface: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkCardColor,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: darkCardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkInputColor,
        disabledColor: Colors.white10,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
      ),
      iconTheme: const IconThemeData(color: Color(0xE6FFFFFF)),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        titleSmall: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF0F0F0), fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputColor,
        labelStyle: GoogleFonts.inter(color: const Color(0xE6FFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCardColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
