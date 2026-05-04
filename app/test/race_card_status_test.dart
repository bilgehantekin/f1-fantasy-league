import 'package:flutter_test/flutter_test.dart';

import 'package:gridcall/shared/models.dart';
import 'package:gridcall/shared/widgets/race_card_new.dart';

void main() {
  Race race({
    required String id,
    required DateTime lockAt,
    DateTime? raceAt,
    RaceStatus status = RaceStatus.upcoming,
    bool hasSprint = false,
    DateTime? sprintLockAt,
    RaceStatus sprintStatus = RaceStatus.upcoming,
  }) {
    return Race(
      id: id,
      round: 1,
      name: 'Test Grand Prix',
      circuit: 'Test Circuit',
      qualifyingAt: lockAt.add(const Duration(hours: 1)),
      raceAt: raceAt ?? lockAt.add(const Duration(days: 1)),
      lockAt: lockAt,
      status: status,
      hasSprint: hasSprint,
      sprintQualifyingAt: sprintLockAt?.add(const Duration(hours: 1)),
      sprintRaceAt: sprintLockAt?.add(const Duration(hours: 2)),
      sprintLockAt: sprintLockAt,
      sprintStatus: sprintStatus,
    );
  }

  group('effective race card status', () {
    test('main race becomes locked when lock time is past', () {
      final now = DateTime.utc(2026, 5, 3, 12);
      final r = race(
        id: 'miami',
        lockAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(
        effectiveRaceCardStatus((race: r, kind: RaceCardKind.main), now: now),
        RaceStatus.locked,
      );
    });

    test('sprint race uses sprint lock time independently', () {
      final now = DateTime.utc(2026, 5, 3, 12);
      final r = race(
        id: 'miami',
        lockAt: now.add(const Duration(days: 1)),
        hasSprint: true,
        sprintLockAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(
        effectiveRaceCardStatus((race: r, kind: RaceCardKind.sprint), now: now),
        RaceStatus.locked,
      );
      expect(
        effectiveRaceCardStatus((race: r, kind: RaceCardKind.main), now: now),
        RaceStatus.upcoming,
      );
    });

    test('finished status is preserved even if lock time is past', () {
      final now = DateTime.utc(2026, 5, 3, 12);
      final r = race(
        id: 'miami',
        lockAt: now.subtract(const Duration(days: 1)),
        status: RaceStatus.finished,
      );

      expect(
        effectiveRaceCardStatus((race: r, kind: RaceCardKind.main), now: now),
        RaceStatus.finished,
      );
    });
  });

  group('previous and next race selection', () {
    test('returns only the nearest previous and next race', () {
      final now = DateTime.utc(2026, 5, 10, 12);
      final races = [
        race(
          id: 'future-2',
          lockAt: now,
          raceAt: now.add(const Duration(days: 14)),
        ),
        race(
          id: 'past-1',
          lockAt: now,
          raceAt: now.subtract(const Duration(days: 7)),
        ),
        race(
          id: 'future-1',
          lockAt: now,
          raceAt: now.add(const Duration(days: 7)),
        ),
        race(
          id: 'past-2',
          lockAt: now,
          raceAt: now.subtract(const Duration(days: 21)),
        ),
      ];

      expect(buildPreviousAndNextRaces(races, now: now).map((r) => r.id), [
        'past-1',
        'future-1',
      ]);
    });
  });
}
