import 'package:flutter_test/flutter_test.dart';

import 'package:gridcall/core/notifications.dart';

void main() {
  group('stableNotificationId', () {
    test('is deterministic for the same reminder key', () {
      final first = stableNotificationId('race-1', 'league-a', 'main');
      final second = stableNotificationId('race-1', 'league-a', 'main');

      expect(first, second);
      expect(first, greaterThanOrEqualTo(0));
    });

    test('separates race, league, and reminder kind', () {
      final main = stableNotificationId('race-1', 'league-a', 'main');
      final sprint = stableNotificationId('race-1', 'league-a', 'sprint');
      final otherLeague = stableNotificationId('race-1', 'league-b', 'main');
      final otherRace = stableNotificationId('race-2', 'league-a', 'main');

      expect({main, sprint, otherLeague, otherRace}, hasLength(4));
    });
  });
}
