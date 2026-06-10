import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/onboarding_flow.dart';
import '../../features/feed/screens/home_screen.dart';
import '../../features/coaching/screens/coach_profile_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/compete/screens/compete_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/navigation_scaffold.dart';

import '../../features/profile/screens/belt_verification_screen.dart';
import '../../features/coaching/screens/coach_dashboard_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/onboarding', // Start with onboarding flow
  routes: <RouteBase>[
    // Onboarding Wizard Route (standalone)
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingFlow();
      },
    ),
    // Belt Verification Route (standalone)
    GoRoute(
      path: '/verify-belt',
      builder: (BuildContext context, GoRouterState state) {
        return const BeltVerificationScreen();
      },
    ),
    // Coach Dashboard Route (standalone)
    GoRoute(
      path: '/coach-dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const CoachDashboardScreen();
      },
    ),
    // Shell navigation route for the 5-tab app
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return NavigationScaffold(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/discover',
          builder: (BuildContext context, GoRouterState state) {
            return const DiscoverScreen();
          },
        ),
        GoRoute(
          path: '/book',
          builder: (BuildContext context, GoRouterState state) {
            return const CoachProfileScreen();
          },
        ),
        GoRoute(
          path: '/compete',
          builder: (BuildContext context, GoRouterState state) {
            return const CompeteScreen();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfileScreen();
          },
        ),
      ],
    ),
  ],
);
