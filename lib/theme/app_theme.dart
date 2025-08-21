import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF8B9A47);
  static const Color backgroundColor = Color(0xFFF5F3F0);
  static const String fontFamily = 'Poppins';

  static MaterialColor get primarySwatch => MaterialColor(
        0xFF8B9A47,
        {
          50: const Color(0xFFF3F5EB),
          100: const Color(0xFFE1E6CD),
          200: const Color(0xFFCDD6AC),
          300: const Color(0xFFB9C68A),
          400: const Color(0xFFAAB971),
          500: const Color(0xFF8B9A47),
          600: const Color(0xFF849040),
          700: const Color(0xFF7A8437),
          800: const Color(0xFF70782F),
          900: const Color(0xFF5E651F),
        },
      );

  static ThemeData get theme => ThemeData(
        primarySwatch: primarySwatch,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: primaryColor),
            foregroundColor: primaryColor,
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
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
            borderSide: const BorderSide(color: primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
          ),
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
          ),
        ),
      );
}