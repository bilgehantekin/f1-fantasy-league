import 'package:flutter_test/flutter_test.dart';

import 'package:gridcall/core/router.dart';
import 'package:gridcall/shared/models.dart';

void main() {
  Profile profile({required bool onboardingCompleted}) => Profile(
    id: 'user-1',
    username: 'bilge',
    onboardingCompleted: onboardingCompleted,
  );

  group('auth redirect decisions', () {
    test('signed out users are sent to auth with return path', () {
      final redirect = resolveAuthRedirect(
        loggedIn: false,
        matchedLocation: '/leagues/:id',
        uri: Uri.parse('/leagues/league-1?tab=races'),
        profile: null,
      );

      expect(redirect, '/auth?from=%2Fleagues%2Fleague-1%3Ftab%3Draces');
    });

    test('signed in auth route returns to original path', () {
      final redirect = resolveAuthRedirect(
        loggedIn: true,
        matchedLocation: '/auth',
        uri: Uri.parse('/auth?from=/join/ABC123'),
        profile: profile(onboardingCompleted: true),
      );

      expect(redirect, '/join/ABC123');
    });

    test('incomplete onboarding is routed to onboarding', () {
      final redirect = resolveAuthRedirect(
        loggedIn: true,
        matchedLocation: '/calendar',
        uri: Uri.parse('/calendar'),
        profile: profile(onboardingCompleted: false),
      );

      expect(redirect, '/onboarding');
    });

    test('completed onboarding cannot stay on onboarding route', () {
      final redirect = resolveAuthRedirect(
        loggedIn: true,
        matchedLocation: '/onboarding',
        uri: Uri.parse('/onboarding'),
        profile: profile(onboardingCompleted: true),
      );

      expect(redirect, '/calendar');
    });
  });
}
