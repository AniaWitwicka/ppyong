import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'korean_font.dart';

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
      // For theme styles we don't set below; ours carry it via withKorean.
      fontFamilyFallback: const [koreanFontFamily],
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Adds the bundled Korean font after the style's own font, so Hangul never
  /// waits for Flutter's runtime fallback download (shows boxes meanwhile).
  /// GoogleFonts styles carry their own fallback list, which would otherwise
  /// hide the theme-wide one.
  static TextStyle withKorean(TextStyle style) => style.copyWith(
        fontFamilyFallback: [
          ...?style.fontFamilyFallback,
          if (!(style.fontFamilyFallback?.contains(koreanFontFamily) ?? false))
            koreanFontFamily,
        ],
      );

  /// Nunito (headings, big numbers) with the Korean fallback.
  /// Use this instead of `fontFamily: 'Nunito'`: google_fonts registers the
  /// font under its own per-weight names, so a plain 'Nunito' is never found
  /// and the text waits for Flutter's runtime fallback fonts (boxes meanwhile).
  static TextStyle nunito(TextStyle style) =>
      withKorean(GoogleFonts.nunito(textStyle: style));

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: withKorean(GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      )),
      displayMedium: withKorean(GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      )),
      headlineMedium: withKorean(GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      )),
      titleMedium: withKorean(GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      )),
      bodyLarge: withKorean(GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      )),
      bodyMedium: withKorean(GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ash,
      )),
      labelLarge: withKorean(GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      )),
    );
  }
}

class AppRadius {
  static const card = Radius.circular(22);
  static const cardBorderRadius = BorderRadius.all(card);
  static const pill = BorderRadius.all(Radius.circular(999));
}
