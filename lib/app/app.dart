import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import 'app_theme.dart';
import 'router.dart';

/// Root application widget for the CSI Church Community App.
class CSIChurchApp extends StatelessWidget {
  const CSIChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
