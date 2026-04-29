import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_jokers_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/league/leagues_screen.dart';
import '../features/league/league_detail_screen.dart';
import '../features/live/live_race_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/prediction/prediction_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/results/results_screen.dart';
import 'supabase.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild router state when auth state changes.
  ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/calendar',
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/auth';
      if (!loggedIn) return loggingIn ? null : '/auth';
      if (loggingIn) return '/calendar';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
      GoRoute(
        path: '/race/:id/predict',
        builder: (_, s) =>
            PredictionScreen(raceId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/race/:id/results',
        builder: (_, s) =>
            ResultsScreen(raceId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/race/:id/live',
        builder: (_, s) => LiveRaceScreen(raceId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/leagues', builder: (_, _) => const LeaguesScreen()),
      GoRoute(
        path: '/leagues/:id',
        builder: (_, s) =>
            LeagueDetailScreen(leagueId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/jokers', builder: (_, _) => const AdminJokersScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/premium', builder: (_, _) => const PaywallScreen()),
    ],
  );
});
