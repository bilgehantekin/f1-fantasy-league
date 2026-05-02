import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_jokers_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/league/leagues_screen.dart';
import '../features/league/league_detail_screen.dart';
import '../features/league/join_league_screen.dart';
import '../features/league/league_settings_screen.dart';
import '../features/league/weekly_summary_screen.dart';
import '../features/lineup/race_lineup_screen.dart';
import '../features/live/live_race_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/prediction/prediction_screen.dart';
import '../features/profile/notification_settings_screen.dart';
import '../features/profile/profile_controller.dart';
import '../features/profile/profile_screen.dart';
import '../features/results/results_screen.dart';
import 'supabase.dart';

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(authStateProvider, (_, _) => refresh.ping());
  ref.listen(profileProvider, (_, _) => refresh.ping());

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/calendar',
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentUser != null;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/auth';
      final onboarding = loc == '/onboarding';

      if (!loggedIn) {
        if (loggingIn) return null;
        final from = Uri.encodeComponent(state.uri.toString());
        return '/auth?from=$from';
      }
      if (loggingIn) {
        return state.uri.queryParameters['from'] ?? '/calendar';
      }

      // Profile yüklendiyse onboarding gate'i uygula.
      // Henüz yüklenmediyse (loading/error) yönlendirme yapma; yüklenince
      // refreshListenable ile redirect tekrar çalışır.
      final profileAsync = ref.read(profileProvider);
      final profile = profileAsync.asData?.value;
      if (profile != null) {
        if (!profile.onboardingCompleted && !onboarding) {
          return '/onboarding';
        }
        if (profile.onboardingCompleted && onboarding) {
          return '/calendar';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
      GoRoute(
        path: '/race/:id/predict',
        builder: (_, s) => PredictionScreen(
          raceId: s.pathParameters['id']!,
          initialSprintMode: s.uri.queryParameters['mode'] == 'sprint',
        ),
      ),
      GoRoute(
        path: '/race/:id/results',
        builder: (_, s) => ResultsScreen(
          raceId: s.pathParameters['id']!,
          sprintMode: s.uri.queryParameters['mode'] == 'sprint',
        ),
      ),
      GoRoute(
        path: '/race/:id/live',
        builder: (_, s) => LiveRaceScreen(raceId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/race/:id/lineup',
        builder: (_, s) => RaceLineupScreen(
          raceId: s.pathParameters['id']!,
          sprintMode: s.uri.queryParameters['mode'] == 'sprint',
        ),
      ),
      GoRoute(path: '/leagues', builder: (_, _) => const LeaguesScreen()),
      GoRoute(
        path: '/join/:code',
        builder: (_, s) =>
            JoinLeagueScreen(inviteCode: s.pathParameters['code']!),
      ),
      GoRoute(
        path: '/leagues/:id',
        builder: (_, s) =>
            LeagueDetailScreen(leagueId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/leagues/:id/settings',
        builder: (_, s) =>
            LeagueSettingsScreen(leagueId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/leagues/:lid/race/:rid/predict',
        builder: (_, s) => PredictionScreen(
          raceId: s.pathParameters['rid']!,
          leagueId: s.pathParameters['lid']!,
          initialSprintMode: s.uri.queryParameters['mode'] == 'sprint',
        ),
      ),
      GoRoute(
        path: '/leagues/:lid/race/:rid/results',
        builder: (_, s) => ResultsScreen(
          raceId: s.pathParameters['rid']!,
          leagueId: s.pathParameters['lid']!,
          sprintMode: s.uri.queryParameters['mode'] == 'sprint',
        ),
      ),
      GoRoute(
        path: '/leagues/:lid/race/:rid/summary',
        builder: (_, s) {
          final sprintMode = s.uri.queryParameters['mode'] == 'sprint';
          if (sprintMode) {
            return ResultsScreen(
              raceId: s.pathParameters['rid']!,
              leagueId: s.pathParameters['lid']!,
              sprintMode: true,
            );
          }
          return WeeklySummaryScreen(
            leagueId: s.pathParameters['lid']!,
            raceId: s.pathParameters['rid']!,
          );
        },
      ),
      GoRoute(
        path: '/admin/jokers',
        builder: (_, _) => const AdminJokersScreen(),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(path: '/premium', builder: (_, _) => const PaywallScreen()),
    ],
  );
});
