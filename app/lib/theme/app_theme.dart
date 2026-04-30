import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const periwinkle = Color(0xFF99B7F5);
  static const forestGreen = Color(0xFF267F53);
  static const orange = Color(0xFFF5793B);
  static const bubblegum = Color(0xFFF296BD);
  static const sunnyYellow = Color(0xFFFCCA59);
  static const offWhite = Color(0xFFFFFDF9);
  static const ink = Color(0xFF1A1A2E);
  static const ash = Color(0xFF6B6873);
  static const fog = Color(0xFFB8B4C0);
  static const border = Color(0xFFE8E4DE);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.periwinkle,
        secondary: AppColors.orange,
        surface: AppColors.offWhite,
      ),
      textTheme: _textTheme,
      useMaterial3: true,
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ash,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
    );
  }
}

class AppRadius {
  static const card = Radius.circular(22);
  static const cardBorderRadius = BorderRadius.all(card);
  static const pill = BorderRadius.all(Radius.circular(999));
}
