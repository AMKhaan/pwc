import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/rides/screens/home_screen.dart';
import '../../features/rides/screens/post_ride_screen.dart';
import '../../features/rides/screens/active_ride_screen.dart';
import '../../features/rides/screens/ride_detail_screen.dart';
import '../../features/rides/screens/my_rides_screen.dart';
import '../../features/rides/screens/search_rides_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/vehicles_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_completion_screen.dart';
import '../../features/profile/screens/about_app_screen.dart';
import '../../features/bookings/screens/notifications_screen.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

// ─── Pending booking requests count (badge on My Rides tab) ──────────────────

final pendingRequestsCountProvider = FutureProvider<int>((ref) async {
  try {
    final res = await DioClient.instance.get(ApiConstants.pendingBookingsCount);
    return (res.data['count'] as num).toInt();
  } catch (_) {
    return 0;
  }
});

// ─── Unread notifications count (badge on Bookings tab) ──────────────────────

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  try {
    final res = await DioClient.instance.get(ApiConstants.unreadNotificationsCount);
    return (res.data['count'] as num).toInt();
  } catch (_) {
    return 0;
  }
});

// ─── Bottom nav shell ──────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = ['/home', '/my-rides', '/bookings', '/profile'];

  // Use instance-level list (non-const) so each AppShell has its own widget
  // instances, avoiding const-canonicalization conflicts with GoRouter.
  final _screens = [
    const HomeScreen(),
    const MyRidesScreen(),
    const MyBookingsScreen(),
    const ProfileScreen(),
  ];

  // Derive the active tab from the router's actual current path so that
  // navigating here from outside the shell (e.g. after login) stays in sync.
  int get _currentIndex {
    final path =
        appRouter.routerDelegate.currentConfiguration.uri.path;
    final idx = _tabs.indexOf(path);
    return idx >= 0 ? idx : 0;
  }

  void _switchTab(int index) {
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;

    return Scaffold(
      // IndexedStack keeps all tab States alive without PageView quirks.
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _switchTab,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
            icon: _MyRidesBadge(
              child: const Icon(Icons.directions_car_outlined),
            ),
            activeIcon: _MyRidesBadge(
              child: const Icon(Icons.directions_car),
            ),
            label: 'My Rides',
          ),
          BottomNavigationBarItem(
            icon: _BookingsBadge(child: const Icon(Icons.bookmark_outline)),
            activeIcon: _BookingsBadge(child: const Icon(Icons.bookmark)),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: _ProfileBadge(child: const Icon(Icons.person_outline)),
            activeIcon: _ProfileBadge(child: const Icon(Icons.person)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Badge widget for Profile tab (shows 1 when verification is rejected) ─────

class _ProfileBadge extends ConsumerWidget {
  final Widget child;
  const _ProfileBadge({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final show = user != null &&
        (user.isRejected || !user.hasSubmittedProfile && !user.isVerified);
    return Badge(
      isLabelVisible: show,
      label: const Text('1'),
      child: child,
    );
  }
}

// ─── Badge widget for Bookings tab ───────────────────────────────────────────

class _BookingsBadge extends ConsumerWidget {
  final Widget child;
  const _BookingsBadge({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 9 ? '9+' : '$count'),
      child: child,
    );
  }
}

// ─── Badge widget for My Rides tab ────────────────────────────────────────────

class _MyRidesBadge extends ConsumerWidget {
  final Widget child;
  const _MyRidesBadge({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingRequestsCountProvider).valueOrNull ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 9 ? '9+' : '$count'),
      child: child,
    );
  }
}

// ─── Navigator keys (required for correct back-gesture behaviour) ──────────────

final _rootNavKey  = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

// ─── Router ────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/verify-email',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final email = extra['email'] as String? ?? '';
        final password = extra['password'] as String?;
        return VerifyEmailScreen(email: email, password: password);
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // ─── Main shell with bottom nav ───────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavKey,
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/my-rides', builder: (_, __) => const MyRidesScreen()),
        GoRoute(path: '/bookings', builder: (_, __) => const MyBookingsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ─── Standalone screens (parentNavigatorKey pins them to root nav) ─
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/search-rides',
      builder: (_, __) => const SearchRidesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/post-ride',
      builder: (_, __) => const PostRideScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/ride/:rideId',
      builder: (_, state) {
        final rideId = state.pathParameters['rideId']!;
        return RideDetailScreen(rideId: rideId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/active-ride/:rideId',
      builder: (_, state) {
        final rideId = state.pathParameters['rideId']!;
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ActiveRideScreen(
          rideId: rideId,
          isDriver: extra['isDriver'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/profile/vehicles',
      builder: (_, __) => const VehiclesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/profile/edit',
      builder: (_, __) => const EditProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/profile/complete',
      builder: (_, __) => const ProfileCompletionScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/about',
      builder: (_, __) => const AboutAppScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
  ],

  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);

