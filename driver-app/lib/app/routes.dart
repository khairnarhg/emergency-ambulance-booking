import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/providers/auth_provider.dart';
import 'package:driver_app/features/auth/presentation/login_screen.dart';
import 'package:driver_app/features/home/presentation/home_screen.dart';
import 'package:driver_app/features/dispatch/presentation/request_screen.dart';
import 'package:driver_app/features/case/presentation/active_case_screen.dart';
import 'package:driver_app/features/case/presentation/triage_screen.dart';
import 'package:driver_app/features/case/presentation/medications_screen.dart';
import 'package:driver_app/features/case/presentation/case_complete_screen.dart';
import 'package:driver_app/features/history/presentation/history_screen.dart';
import 'package:driver_app/features/profile/presentation/profile_screen.dart';
import 'package:driver_app/features/notifications/presentation/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/request/:sosId',
        builder: (context, state) {
          final sosId = int.parse(state.pathParameters['sosId']!);
          return RequestScreen(sosId: sosId);
        },
      ),
      GoRoute(
        path: '/case/:sosId',
        builder: (context, state) {
          final sosId = int.parse(state.pathParameters['sosId']!);
          return ActiveCaseScreen(sosId: sosId);
        },
      ),
      GoRoute(
        path: '/case/:sosId/triage',
        builder: (context, state) {
          final sosId = int.parse(state.pathParameters['sosId']!);
          return TriageScreen(sosId: sosId);
        },
      ),
      GoRoute(
        path: '/case/:sosId/medications',
        builder: (context, state) {
          final sosId = int.parse(state.pathParameters['sosId']!);
          return MedicationsScreen(sosId: sosId);
        },
      ),
      GoRoute(
        path: '/case/:sosId/complete',
        builder: (context, state) {
          final sosId = int.parse(state.pathParameters['sosId']!);
          return CaseCompleteScreen(sosId: sosId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/history');
      case 2:
        context.go('/profile');
    }
  }
}
