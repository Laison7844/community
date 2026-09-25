import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable member profile avatar widget across Web and Mobile.
///
/// Features:
/// - Displays actual profile photo if valid URL exists
/// - Gracefully falls back to default icon placeholder on error, empty, or null URL
/// - Does not crash on network or decoding failures
/// - Material 3 church aesthetic with configurable radius and colors
class MemberAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final BoxBorder? border;

  const MemberAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = imageUrl?.trim() ?? '';
    final bg = backgroundColor ?? AppColors.surfaceCream;
    final fg = iconColor ?? AppColors.mutedGold;
    final size = radius * 2;
    final iSize = iconSize ?? (radius * 1.05);

    Widget fallbackPlaceholder() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            size: iSize,
            color: fg,
          ),
        ),
      );
    }

    if (validUrl.isEmpty) {
      return fallbackPlaceholder();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
      ),
      child: ClipOval(
        child: Image.network(
          validUrl,
          width: size,
          height: size,
          cacheWidth: (size * 2).round().clamp(64, 512),
          cacheHeight: (size * 2).round().clamp(64, 512),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return fallbackPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: bg,
              child: Center(
                child: SizedBox(
                  width: radius * 0.7,
                  height: radius * 0.7,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.mutedGold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
