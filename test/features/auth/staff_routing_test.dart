import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';
import 'package:communtiy/features/auth/presentation/splash_page.dart';
import 'package:communtiy/features/auth/providers/auth_provider.dart';

void main() {
  const staffAdminProfile = MemberProfile(
    uid: 'admin_1',
    fullName: 'Pastor John',
    familyNumber: 'F-001',
    profileImageUrl: '',
    email: 'pastor@csichurch.org',
    status: MemberStatus.approved,
    role: 'pastor',
  );

  const regularMemberProfile = MemberProfile(
    uid: 'member_1',
    fullName: 'Thomas Kurian',
    familyNumber: 'F-102',
    profileImageUrl: '',
    email: 'thomas@csichurch.org',
    status: MemberStatus.approved,
    role: 'member',
  );

  Widget createRoutingTestWidget({required AuthState authState, required List<String> routedLocations}) {
    final testRouter = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) {
            routedLocations.add('/admin');
            return const Scaffold(body: Text('Staff Admin Portal Target'));
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            routedLocations.add('/home');
            return const Scaffold(body: Text('Member Application Target'));
          },
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) {
            routedLocations.add('/welcome');
            return const Scaffold(body: Text('Welcome Target'));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => FakeAuthNotifier(authState)),
      ],
      child: MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
  }

  group('Staff Portal Architecture - Clean Route Separation Tests', () {
    testWidgets('Staff members are routed directly to /admin and not member /home', (tester) async {
      final routed = <String>[];
      const staffState = AuthState(
        isAuthenticated: true,
        isLoading: false,
        profile: staffAdminProfile,
        status: MemberStatus.approved,
      );

      await tester.pumpWidget(createRoutingTestWidget(authState: staffState, routedLocations: routed));
      // Let splash timer elapse (1.2s minimum branding display)
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      expect(routed.contains('/admin'), isTrue);
      expect(routed.contains('/home'), isFalse);
      expect(find.text('Staff Admin Portal Target'), findsOneWidget);
      expect(find.text('Member Application Target'), findsNothing);
    });

    testWidgets('Regular church members are routed to /home and not /admin', (tester) async {
      final routed = <String>[];
      const memberState = AuthState(
        isAuthenticated: true,
        isLoading: false,
        profile: regularMemberProfile,
        status: MemberStatus.approved,
      );

      await tester.pumpWidget(createRoutingTestWidget(authState: memberState, routedLocations: routed));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      expect(routed.contains('/home'), isTrue);
      expect(routed.contains('/admin'), isFalse);
      expect(find.text('Member Application Target'), findsOneWidget);
      expect(find.text('Staff Admin Portal Target'), findsNothing);
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}
