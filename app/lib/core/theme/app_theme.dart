import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jansetu design tokens and theme configuration.
///
/// Color palette extracted from the onboarding design screenshots:
/// - Deep forest green header/buttons
/// - Teal-green accent for selected states
/// - Light grey cards on white backgrounds
class AppColors {
  AppColors._();

  // ── Primary greens ──────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF1B5E3B);
  static const Color primary = Color(0xFF2E7D52);
  static const Color primaryLight = Color(0xFF4CAF7D);

  // ── Surface / background ────────────────────────────────────────
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardFill = Color(0xFFF0F0F0);
  static const Color cardSelected = Color(0xFFE8F5EE);

  // ── Borders ─────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderSelected = Color(0xFF2E7D52);

  // ── Text ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ── Gradients ───────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5E3B), Color(0xFF2E7D52)],
  );
}

class AppTextStyles {
  AppTextStyles._();

  /// App title — "Aarogya Sentinel"
  static TextStyle appTitle = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Subtitle — bilingual helper text
  static TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Header title on green background — "आप कौन हैं?"
  static TextStyle headerTitle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  /// Header subtitle on green background
  static TextStyle headerSubtitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
  );

  /// Language card — native script label (e.g. "हिंदी")
  static TextStyle languageNative = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Language card — English label below
  static TextStyle languageEnglish = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Role card — title (e.g. "ASHA / ANM / CHW")
  static TextStyle roleTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Role card — subtitle
  static TextStyle roleSubtitle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// CTA button text — "आगे बढ़ें · Continue"
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  /// Footer / privacy notice
  static TextStyle footerText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headerTitle,
      ),
    );
  }
}
