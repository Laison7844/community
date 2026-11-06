import 'package:flutter/foundation.dart';

/// Centralized environment and build configuration.
///
/// Reads build configuration passed via `--dart-define=API_BASE_URL=...`.
/// Enforces HTTPS and non-empty URLs in release builds.
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolves the effective backend API base URL (without trailing slashes or duplicate `/api`).
  ///
  /// Release mode:
  /// - Requires `--dart-define=API_BASE_URL=https://<your-backend-host>`.
  /// - Requires HTTPS.
  /// - Throws [StateError] if missing or insecure.
  ///
  /// Debug / Profile mode:
  /// - Uses `--dart-define=API_BASE_URL=...` if provided.
  /// - Defaults to `http://10.0.2.2:5001` on Android emulator.
  /// - Defaults to `http://localhost:5001` on Web, iOS simulator, and desktop.
  static String get apiBaseUrl {
    final configured = _envApiBaseUrl.trim();

    if (kReleaseMode) {
      if (configured.isEmpty) {
        throw StateError(
          'API_BASE_URL must be provided for production release builds:\n'
          'Example: flutter build web --release --dart-define=API_BASE_URL=https://api.yourchurch.org',
        );
      }
      if (!configured.startsWith('https://')) {
        throw StateError(
          'API_BASE_URL must use HTTPS in release builds. Insecure URL provided: "$configured"',
        );
      }
      return _normalizeBaseUrl(configured);
    }

    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }

    // Development defaults
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator reaches host machine loopback via 10.0.2.2
      return 'http://10.0.2.2:5001';
    }

    return 'http://localhost:5001';
  }

  /// Normalizes the base URL by stripping trailing slashes and trailing `/api` segments
  /// to ensure consistent routing without `/api/api` duplication.
  static String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }
    return trimmed;
  }
}

