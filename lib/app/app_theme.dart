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
      tertiary: AppColors.subtleOlive,
      onTertiary: Colors.white,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: AppColors.cardSurface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.cardSurface,
      surfaceContainerLow: AppColors.backgroundIvory,
      surfaceContainer: AppColors.surfaceCream,
      surfaceContainerHigh: AppColors.lightBeige,
      surfaceContainerHighest: AppColors.softBeige,
      outline: AppColors.softBeige,
      outlineVariant: AppColors.lightBeige,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundIvory,
      fontFamily: null, // Uses default clean modern system font
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
      cardTheme: const CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.roundedLarge,
          side: BorderSide(color: AppColors.softBeige, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: AppStyles.roundedMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space24, vertical: 14),
          side: const BorderSide(color: AppColors.softBeige, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppStyles.roundedMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.softBeige,
        thickness: 1.0,
        space: 1.0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBrown,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBrown,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBrown,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
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
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
