import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/announcements/models/announcement.dart';
import '../features/announcements/presentation/announcement_detail_page.dart';
import '../features/announcements/presentation/announcements_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/pending_approval_page.dart';
import '../features/auth/presentation/request_access_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/home/presentation/home_preview_page.dart';

import '../features/birthdays/presentation/birthdays_page.dart';

/// Global root navigator key for deep links & notifications
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized declarative routing configuration for the CSI Church App.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/request-access',
      builder: (context, state) => const RequestAccessPage(),
    ),
    GoRoute(
      path: '/pending-approval',
      builder: (context, state) => const PendingApprovalPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePreviewPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/announcements',
      builder: (context, state) => const AnnouncementsPage(),
    ),
    GoRoute(
      path: '/announcements/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra is Announcement ? state.extra as Announcement : null;
        return AnnouncementDetailPage(
          announcementId: id,
          preloadedAnnouncement: extra,
        );
      },
    ),
    GoRoute(
      path: '/birthdays-anniversaries',
      builder: (context, state) => const BirthdaysPage(),
    ),
  ],
);
