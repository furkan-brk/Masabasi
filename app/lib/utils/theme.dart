import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Scholar's Table design system color tokens.
/// Mirrors the Stitch tailwind.config palette 1:1.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF570000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF800000);
  static const Color onPrimaryContainer = Color(0xFFFF8371);
  static const Color primaryFixed = Color(0xFFFFDAD4);
  static const Color primaryFixedDim = Color(0xFFFFB4A8);

  static const Color secondary = Color(0xFF3B6751);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFBBEACF);
  static const Color onSecondaryContainer = Color(0xFF406B56);

  static const Color tertiary = Color(0xFF342400);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF503800);
  static const Color onTertiaryContainer = Color(0xFFC7A15A);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color surface = Color(0xFFFCF9F2); // parchment
  static const Color surfaceDim = Color(0xFFDCDAD3);
  static const Color surfaceBright = Color(0xFFFCF9F2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3EC);
  static const Color surfaceContainer = Color(0xFFF1EEE7);
  static const Color surfaceContainerHigh = Color(0xFFEBE8E1);
  static const Color surfaceContainerHighest = Color(0xFFE5E2DB);
  static const Color surfaceVariant = Color(0xFFE5E2DB);

  static const Color onSurface = Color(0xFF1C1C18);
  static const Color onSurfaceVariant = Color(0xFF5A413D);
  static const Color onBackground = Color(0xFF1C1C18);
  static const Color background = Color(0xFFFCF9F2);

  static const Color outline = Color(0xFF8E706C);
  static const Color outlineVariant = Color(0xFFE2BFB9);
  static const Color surfaceTint = Color(0xFFB22B1D);

  static const Color inverseSurface = Color(0xFF31312C);
  static const Color inverseOnSurface = Color(0xFFF3F0E9);
  static const Color inversePrimary = Color(0xFFFFB4A8);

  // CSS-derived effect colors (status seals, slots, dividers).
  static const Color slotFilled = Color(0xFF570000);
  static const Color slotEmptyBorder = Color(0xFF8E706C);
  static const Color statusBekliyorBorder = Color(0xFF3B6751);
  static const Color statusBekliyorBg = Color(0xFFBBEACF);
  static const Color statusDoluBorder = Color(0xFFBA1A1A);
  static const Color statusDoluBg = Color(0xFFFFDAD6);
  static const Color doubleDividerLine = Color(0xFFE2BFB9);
}

/// Spacing scale from the Stitch tailwind config.
class AppSpacing {
  AppSpacing._();

  static const double base = 4;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 48;
  static const double xl = 80;
  static const double gutter = 24;
  static const double marginMobile = 16;
  static const double marginDesktop = 64;
  static const double navWidth = 256; // w-64
  static const double topNavHeight = 80; // h-20
}

/// Border-radius scale (tailwind: DEFAULT .125rem / lg .25rem / xl .5rem / full .75rem).
class AppRadius {
  AppRadius._();

  static const double sm = 2; // DEFAULT 0.125rem
  static const double lg = 4; // 0.25rem
  static const double xl = 8; // 0.5rem
  static const double full = 12; // 0.75rem
}

/// Breakpoint helpers. 768px is the md: split used throughout Stitch.
class AppBreakpoints {
  AppBreakpoints._();

  static const double md = 768;
  static const double lg = 1024;
  static const double maxContent = 1200;

  static bool isMobile(double width) => width < md;
  static bool isDesktop(double width) => width >= md;
}

/// Playfair Display + Inter typography, scaled exactly to the Stitch fontSize map.
class AppText {
  AppText._();

  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.96, // -0.02em * 48
        height: 1.1,
      );

  static TextStyle get headlineLg => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get headlineMd => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.7, // 0.05em * 14
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    surfaceTint: AppColors.surfaceTint,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: TextTheme(
      displayLarge: AppText.display,
      headlineLarge: AppText.headlineLg,
      headlineMedium: AppText.headlineMd,
      bodyLarge: AppText.bodyLg,
      bodyMedium: AppText.bodyMd,
      labelMedium: AppText.labelMd,
      labelSmall: AppText.caption,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
