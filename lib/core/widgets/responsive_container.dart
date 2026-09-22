import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

/// A wrapper widget that centers content and constrains its maximum width on desktop / tablet screens.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppStyles.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: AppStyles.space20),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
