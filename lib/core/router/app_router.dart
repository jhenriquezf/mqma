import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/booking/presentation/screens/checkin_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/matching/presentation/screens/matching_screen.dart';
import '../../features/reviews/presentation/screens/review_screen.dart';
import '../widgets/main_scaffold.dart';
import 'navigator_key.dart';

export 'navigator_key.dart' show appNavigatorKey;

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value?.isLoggedIn ?? false;
      final isOnboarded = authState.value?.isOnboarded ?? false;
      final path = state.uri.path;

      if (path == '/splash') return null;
      if (!isLoggedIn) {
        if (path.startsWith('/auth')) return null;
        return '/auth/login';
      }
      if (isLoggedIn && !isOnboarded && path != '/onboarding') return '/onboarding';
      if (isLoggedIn && path.startsWith('/auth')) return '/events';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/events',
            builder: (_, __) => const EventsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => EventDetailScreen(id: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'book',
                    builder: (_, s) => BookingScreen(eventId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'group',
                    builder: (_, s) => MatchingScreen(eventId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: '/checkin', builder: (_, __) => const CheckinScreen()),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'edit', builder: (_, __) => const EditProfileScreen()),
            ],
          ),
          GoRoute(
            path: '/review/:eventId',
            builder: (_, s) => ReviewScreen(eventId: s.pathParameters['eventId']!),
          ),
        ],
      ),
    ],
  );

  // Refresca el router cada vez que cambia el estado de auth (login/logout)
  ref.listen(authStateProvider, (_, __) => router.refresh());

  return router;
});
