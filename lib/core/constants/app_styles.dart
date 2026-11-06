import 'package:flutter/material.dart';

/// Centralized layout tokens, padding, radius, elevation, and responsive breakpoints.
class AppStyles {
  AppStyles._();

  // ===============================================================
  // Spacing System (8-Point Base Grid)
  // ===============================================================
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0; // Preserved for backward compatibility
  static const double space32 = 32.0;
  static const double space40 = 40.0; // Preserved for backward compatibility
  static const double space48 = 48.0;

  // Semantic spacing aliases
  static const double spacingXXS = space4;
  static const double spacingXS = space8;
  static const double spacingSM = space12;
  static const double spacingMD = space16;
  static const double spacingLG = space20;
  static const double spacingXL = space24;
  static const double spacing2XL = space32;
  static const double spacing3XL = space48;

  // ===============================================================
  // Border Radiuses
  // ===============================================================
  static const double radiusSmall = 8.0;     // Inputs, chips, compact buttons
  static const double radiusMedium = 12.0;   // Standard buttons, dropdowns, banners
  static const double radiusLarge = 16.0;    // Cards, containers
  static const double radiusXLarge = 24.0;   // Dialogs, bottom sheets
  static const double radiusFull = 999.0;    // Avatars, pills

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedXLarge = BorderRadius.all(Radius.circular(radiusXLarge));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Max Width for Responsive Containment on Desktop/Tablet
  static const double maxContentWidth = 480.0;
  static const double maxFormWidth = 600.0;
  static const double maxDashboardWidth = 1200.0;

  // ===============================================================
  // Responsive Breakpoints
  // ===============================================================
  static const double mobileBreakpoint = 600.0;  // Below 600px: Mobile phone
  static const double tabletBreakpoint = 1024.0; // 600-1024px: Tablet
  static const double desktopBreakpoint = 1024.0; // Above 1024px: Desktop / Large Web

  /// Check if the current viewport is mobile width (< 600px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Check if the current viewport is tablet width (600 - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width <= tabletBreakpoint;
  }

  /// Check if the current viewport is desktop width (> 1024px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > desktopBreakpoint;

  // ===============================================================
  // Subtle Warm-Brown Elevation & Shadows
  // ===============================================================

  /// Elevation 0: Flat / no shadow
  static const List<BoxShadow> elevation0 = [];

  /// Elevation 1: Subtle ambient shadow for standard cards, search inputs
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x0A3E2723), // 4% church brown
      blurRadius: 10.0,
      offset: Offset(0, 3),
    ),
  ];

  /// Elevation 2: Interactive / hover card shadow
  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x123E2723), // 7% church brown
      blurRadius: 18.0,
      offset: Offset(0, 6),
    ),
  ];

  /// Elevation 3: Prominent overlay shadow for dialogs and bottom sheets
  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x20271512), // 12% deep brown
      blurRadius: 30.0,
      offset: Offset(0, 12),
    ),
  ];

  /// Preserved alias for backward compatibility
  static const List<BoxShadow> softCardShadow = elevation1;

  /// Subtle gold glow for emblems and ceremonial highlights
  static const List<BoxShadow> goldGlowShadow = [
    BoxShadow(
      color: Color(0x28C5A059),
      blurRadius: 20.0,
      offset: Offset(0, 4),
    ),
  ];
}
