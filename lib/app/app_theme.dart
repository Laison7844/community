import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

/// Centralized Material 3 church theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBrown,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.surfaceCream,
      onPrimaryContainer: AppColors.primaryBrownDark,
      secondary: AppColors.mutedGold,
      onSecondary: AppColors.textOnGold,
      secondaryContainer: AppColors.lightBeige,
      onSecondaryContainer: AppColors.primaryBrown,
      tertiary: AppColors.accentBurgundy,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accentBurgundyLight,
      onTertiaryContainer: AppColors.accentBurgundy,
      error: AppColors.errorRed,
      onError: Colors.white,
      errorContainer: AppColors.errorRedLight,
      onErrorContainer: AppColors.errorRed,
      surface: AppColors.cardSurface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.cardSurface,
      surfaceContainerLow: AppColors.backgroundIvory,
      surfaceContainer: AppColors.surfaceCream,
      surfaceContainerHigh: AppColors.lightBeige,
      surfaceContainerHighest: AppColors.softBeige,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderSubtle,
    );

    const textTheme = TextTheme(
      // Display: 32px
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBrown,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBrown,
        letterSpacing: -0.3,
        height: 1.28,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBrown,
        height: 1.3,
      ),

      // Headline large: 24px, medium: 20px, small: 18px
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBrown,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBrown,
        height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBrown,
        height: 1.35,
      ),

      // Title large: 18px, medium: 16px, small: 14px
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),

      // Body large: 16px, medium: 14px, small: 12px
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      ),

      // Label large: 14px, medium: 12px, small: 11px
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundIvory,
      textTheme: textTheme,
      fontFamily: null, // Clean, modern system font

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundIvory,
        foregroundColor: AppColors.primaryBrown,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1.0,
        titleTextStyle: TextStyle(
          color: AppColors.primaryBrown,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryBrown),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.roundedLarge,
          side: BorderSide(color: AppColors.borderDefault, width: 1.0),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space20, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: AppStyles.roundedMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space20, vertical: 12),
          side: const BorderSide(color: AppColors.borderDefault, width: 1.2),
          shape: const RoundedRectangleBorder(
            borderRadius: AppStyles.roundedMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.space16,
          vertical: AppStyles.space14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: AppStyles.roundedSmall,
          borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.roundedSmall,
          borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.roundedSmall,
          borderSide: const BorderSide(color: AppColors.primaryBrown, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.roundedSmall,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.roundedSmall,
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.8),
        ),
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.roundedXLarge,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBrown,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.45,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardSurface,
        selectedColor: AppColors.primaryBrown,
        secondarySelectedColor: AppColors.mutedGold,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.roundedSmall,
          side: const BorderSide(color: AppColors.borderDefault, width: 1.0),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
