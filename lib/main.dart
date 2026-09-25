import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the preconfigured DefaultFirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM Notification listeners and deep-linking handlers
  await NotificationService.instance.initialize(
    onNavigate: (route) {
      appRouter.go(route);
    },
  );

  runApp(
    const ProviderScope(
      child: CSIChurchApp(),
    ),
  );
}

