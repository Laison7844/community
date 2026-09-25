import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Top-level background message entry point required by flutter_firebase_messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Already initialized or platform stub
  }
}

/// Centralized FCM Notification Service for CSI Church Community
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _http = http.Client();

  String? _cachedFcmToken;
  String? get fcmToken => _cachedFcmToken;

  bool _initialized = false;
  void Function(String route)? _onNavigateCallback;

  /// Initializes FCM listeners, permissions, and handlers
  Future<void> initialize({void Function(String route)? onNavigate}) async {
    if (_initialized) return;
    _initialized = true;
    _onNavigateCallback = onNavigate;

    try {
      // 1. Request user permission for notifications
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint('[NotificationService] Permission status: ${settings.authorizationStatus}');
      }

      // 2. Set background message handler (Android / iOS)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // 3. Obtain FCM token
      await retrieveAndCacheToken();

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('[NotificationService] Foreground message: ${message.notification?.title}');
        }
        _handleForegroundMessage(message);
      });

      // 5. Background message tap listener (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('[NotificationService] Notification tapped from background: ${message.data}');
        }
        _handleNotificationRoute(message);
      });

      // 6. Terminated app launch listener (when app was terminated and opened by tapping notification)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint('[NotificationService] App opened from terminated state by notification: ${initialMessage.data}');
        }
        _handleNotificationRoute(initialMessage);
      }

      // 7. Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _cachedFcmToken = newToken;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] FCM initialization warning: $e');
      }
    }
  }

  /// Retrieves the current device FCM token
  Future<String?> retrieveAndCacheToken() async {
    try {
      // On web, getToken requires a VAPID key if web push is configured; otherwise fallback safely
      _cachedFcmToken = await _fcm.getToken();
      if (kDebugMode && _cachedFcmToken != null) {
        debugPrint('[NotificationService] FCM Device Token obtained: $_cachedFcmToken');
      }
      return _cachedFcmToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Failed to get FCM token: $e');
      }
      return null;
    }
  }

  /// Registers the device token with the Node.js backend and Firestore profile
  Future<void> registerTokenWithBackend({
    required String uid,
    String? idToken,
    String serverBaseUrl = 'http://localhost:5001',
  }) async {
    final token = _cachedFcmToken ?? await retrieveAndCacheToken();
    if (token == null || token.isEmpty || uid.isEmpty) return;

    // 1. Direct Firestore profile sync (resilient fallback)
    try {
      await _firestore.collection('member_profiles').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // Ignore if document not created yet
    }

    // 2. Node.js backend registration
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final url = Uri.parse('$serverBaseUrl/api/tokens/register');
        await _http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'token': token}),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[NotificationService] Backend token registration failed: $e');
        }
      }
    }
  }

  /// Handles incoming foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    // App is in foreground: notification data is accessible
  }

  /// Extracts deep link route from notification data and triggers navigation
  void _handleNotificationRoute(RemoteMessage message) {
    final data = message.data;
    String route = data['route'] ?? '';

    if (route.isEmpty) {
      final type = data['type'];
      if (type == 'reminder' || type == 'birthday' || type == 'anniversary') {
        route = '/birthdays-anniversaries';
      }
    }

    if (route.isNotEmpty && _onNavigateCallback != null) {
      _onNavigateCallback!(route);
    }
  }
}
