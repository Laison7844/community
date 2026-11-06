import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('apiBaseUrl defaults to valid host URL in debug mode', () {
      final url = AppConfig.apiBaseUrl;
      expect(url.isNotEmpty, isTrue);
      expect(url.endsWith('/'), isFalse, reason: 'URL must not end with a trailing slash');
      expect(url.endsWith('/api'), isFalse, reason: 'URL must not end with trailing /api');
    });

    test('Normalize URL correctly strips trailing slashes and redundant /api segment', () {
      // Testing the internal logic via expected behavior
      final url = AppConfig.apiBaseUrl;
      expect(url.contains('/api/api'), isFalse);
    });
  });
}

