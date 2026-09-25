import 'package:flutter/material.dart';

/// Centralized layout tokens, padding, radius, and shadow styling.
class AppStyles {
  AppStyles._();

  // Spacing
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Border Radiuses
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedXLarge = BorderRadius.all(Radius.circular(radiusXLarge));

  // Max Width for Responsive Containment on Desktop/Tablet
  static const double maxContentWidth = 480.0;
  static const double maxDashboardWidth = 1100.0;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x0C3E2723), // 5% deep brown shadow
      blurRadius: 16.0,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> goldGlowShadow = [
    BoxShadow(
      color: Color(0x28C5A059),
      blurRadius: 20.0,
      offset: Offset(0, 4),
    ),
  ];
}
