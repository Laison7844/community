import 'package:flutter/material.dart';

/// Centralized color palette for the CSI Church Community application.
///
/// Designed with a calm, elegant, and welcoming church theme:
/// warm ivory, cream, soft beige, muted gold, deep brown, and subtle olive green.
class AppColors {
  AppColors._();

  // Primary & Accents
  static const Color primaryBrown = Color(0xFF3E2723); // Deep Church Brown
  static const Color primaryBrownLight = Color(0xFF5D4037);
  static const Color primaryBrownDark = Color(0xFF271512);

  // Muted Gold / Warm Brass (for badges, highlights, cross emblem)
  static const Color mutedGold = Color(0xFFC5A059);
  static const Color mutedGoldLight = Color(0xFFDFBF7E);
  static const Color mutedGoldDark = Color(0xFF9E7B35);

  // Liturgical Wine / Rich Burgundy (for wedding anniversaries & celebrations)
  static const Color accentWine = Color(0xFF8B263E);

  // Background & Neutral Surfaces
  static const Color backgroundIvory = Color(0xFFFAF8F5); // Warm Ivory
  static const Color surfaceCream = Color(0xFFF5F0E8);    // Soft Cream
  static const Color cardSurface = Color(0xFFFFFFFF);     // Pure Card Surface
  static const Color softBeige = Color(0xFFE8E2D8);       // Border / Divider Beige
  static const Color lightBeige = Color(0xFFF1ECE4);

  // Subtle Olive Green (peaceful accents, approved status)
  static const Color subtleOlive = Color(0xFF556B2F);
  static const Color oliveLight = Color(0xFFEBF1E5);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C2523);   // Dark Warm Charcoal
  static const Color textSecondary = Color(0xFF6E655F); // Muted Body Gray
  static const Color textLight = Color(0xFF9E958F);     // Caption / Hint
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on brown/gold
  static const Color textOnGold = Color(0xFF2E200B);    // Deep dark on gold

  // Status & Feedback Colors
  static const Color errorRed = Color(0xFFC62828);
  static const Color errorRedLight = Color(0xFFFFEBEE);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenLight = Color(0xFFE8F5E9);
}
