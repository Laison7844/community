import 'package:flutter/material.dart';

/// Centralized color palette and semantic tokens for the CSI Church Community application.
///
/// Designed with a calm, dignified, and welcoming church theme:
/// warm ivory, cream, deep church espresso brown, muted antique gold, and liturgical burgundy.
class AppColors {
  AppColors._();

  // ===============================================================
  // Primary Palette (Espresso Church Brown)
  // ===============================================================
  static const Color primaryBrown = Color(0xFF3E2723); // Deep Church Brown
  static const Color primary = primaryBrown;
  static const Color primaryBrownLight = Color(0xFF5D4037);
  static const Color primaryLight = primaryBrownLight;
  static const Color primaryBrownDark = Color(0xFF271512);
  static const Color primaryDark = primaryBrownDark;

  // ===============================================================
  // Accent Palette (Antique Gold & Liturgical Burgundy)
  // ===============================================================
  static const Color mutedGold = Color(0xFFC5A059); // Antique Gold (Badges, Emblem)
  static const Color antiqueGold = mutedGold;
  static const Color accentGold = mutedGold;

  static const Color mutedGoldLight = Color(0xFFDFBF7E); // Light Gold (Highlights)
  static const Color lightGold = mutedGoldLight;
  static const Color accentGoldLight = mutedGoldLight;

  static const Color mutedGoldDark = Color(0xFF9E7B35); // Dark Gold for readable text on light backgrounds
  static const Color darkGold = mutedGoldDark;
  static const Color accentGoldDark = mutedGoldDark;

  static const Color accentWine = Color(0xFF8B263E); // Liturgical Burgundy (Marriage & Celebrations)
  static const Color burgundy = accentWine;
  static const Color accentBurgundy = accentWine;

  static const Color accentBurgundyLight = Color(0xFFFBF0F2); // Subtle Burgundy Container Tint
  static const Color burgundyLight = accentBurgundyLight;

  // ===============================================================
  // Neutral Surfaces & Backgrounds
  // ===============================================================
  static const Color backgroundIvory = Color(0xFFFAF8F5); // Warm Ivory Page Background
  static const Color background = backgroundIvory;

  static const Color surfaceCream = Color(0xFFF5F0E8); // Soft Cream Surface
  static const Color surface = surfaceCream;

  static const Color cardSurface = Color(0xFFFFFFFF); // Pure White Card Surface
  static const Color surfaceCard = cardSurface;

  static const Color softBeige = Color(0xFFE8E2D8); // Default Border & Divider Beige
  static const Color borderDefault = softBeige;

  static const Color lightBeige = Color(0xFFF1ECE4); // Subtle Border & Alternate Row Tint
  static const Color borderSubtle = lightBeige;

  // ===============================================================
  // Typography Colors
  // ===============================================================
  static const Color textPrimary = Color(0xFF2C2523); // Dark Warm Charcoal for high-contrast reading
  static const Color textSecondary = Color(0xFF6E655F); // Muted Body & Subtitle Gray
  static const Color textLight = Color(0xFF9E958F); // Captions, Placeholders, Hints
  static const Color textMuted = textLight;

  static const Color textOnPrimary = Color(0xFFFFFFFF); // High-contrast White on Dark Brown/Burgundy
  static const Color textOnGold = Color(0xFF2E200B); // Deep Dark Brown text on Gold fill

  // ===============================================================
  // Semantic Status Colors (Parish & Workflow States)
  // ===============================================================

  // Pending Review (Amber)
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusPendingFg = Color(0xFFD97706);

  // Approved Member (Olive / Forest Green)
  static const Color subtleOlive = Color(0xFF556B2F);
  static const Color oliveLight = Color(0xFFEBF1E5);
  static const Color statusApprovedBg = Color(0xFFEBF1E5);
  static const Color statusApprovedFg = Color(0xFF556B2F);

  // Suspended Account (Red)
  static const Color statusSuspendedBg = Color(0xFFFFEBEE);
  static const Color statusSuspendedFg = Color(0xFFC62828);

  // Rejected Applicant (Neutral Slate)
  static const Color statusRejectedBg = Color(0xFFF3F4F6);
  static const Color statusRejectedFg = Color(0xFF4B5563);

  // Draft Notice / Bulletin (Warm Amber / Ochre)
  static const Color statusDraftBg = Color(0xFFFEF3C7);
  static const Color statusDraftFg = Color(0xFFB45309);

  // General Status & Feedback
  static const Color errorRed = Color(0xFFC62828);
  static const Color errorRedLight = Color(0xFFFFEBEE);

  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFEF3C7);

  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenLight = Color(0xFFE8F5E9);

  static const Color infoBlue = Color(0xFF1E40AF);
  static const Color infoBlueLight = Color(0xFFEFF6FF);
}
