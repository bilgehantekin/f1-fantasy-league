import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gridcall/core/notifications.dart';
import 'package:gridcall/shared/models.dart';

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

    test('post-race summary ids do not collide with reminders', () {
      final postRace = postRaceSummaryNotificationId('race-1');
      final reminder = stableNotificationId('race-1', 'public', 'main');

      expect(postRace, isNot(reminder));
      expect(postRace, postRaceSummaryNotificationId('race-1'));
    });
  });

  group('PostRaceSummaryPreferences', () {
    test('defaults off for existing users', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await PostRaceSummaryPreferences.load();

      expect(prefs.enabled, isFalse);
    });

    test('serializes enabled flag', () async {
      SharedPreferences.setMockInitialValues({});

      await const PostRaceSummaryPreferences(enabled: true).save();
      final prefs = await PostRaceSummaryPreferences.load();

      expect(prefs.enabled, isTrue);
    });
  });

  group('postRaceSummaryNotificationTime', () {
    test('uses race session end when available with result delay', () {
      final race = Race(
        id: 'race-1',
        round: 1,
        name: 'Test GP',
        circuit: 'Test',
        qualifyingAt: DateTime.utc(2026, 5, 1, 12),
        raceAt: DateTime.utc(2026, 5, 3, 12),
        lockAt: DateTime.utc(2026, 5, 1, 11),
        status: RaceStatus.upcoming,
        sessions: [
          RaceSession(
            id: 's1',
            sessionKey: null,
            sessionName: 'Race',
            sessionType: 'race',
            shortLabel: 'R',
            sortOrder: 5,
            startsAt: DateTime.utc(2026, 5, 3, 12),
            endsAt: DateTime.utc(2026, 5, 3, 14),
          ),
        ],
      );

      expect(
        postRaceSummaryNotificationTime(race),
        DateTime.utc(2026, 5, 3, 17),
      );
    });
  });
}
