import 'package:flutter_test/flutter_test.dart';

import 'package:gridcall/shared/models.dart';

void main() {
  test('Race.isLocked true past lockAt', () {
    final past = Race(
      id: 'a',
      round: 1,
      name: 'Test',
      circuit: 'Circuit',
      qualifyingAt: DateTime.now().subtract(const Duration(hours: 2)),
      raceAt: DateTime.now().subtract(const Duration(hours: 1)),
      lockAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: RaceStatus.upcoming,
    );
    expect(past.isLocked, true);
  });

  test('Race.isLocked false before lockAt', () {
    final future = Race(
      id: 'b',
      round: 2,
      name: 'Test',
      circuit: 'Circuit',
      qualifyingAt: DateTime.now().add(const Duration(days: 7)),
      raceAt: DateTime.now().add(const Duration(days: 8)),
      lockAt: DateTime.now().add(const Duration(days: 6, hours: 23)),
      status: RaceStatus.upcoming,
    );
    expect(future.isLocked, false);
    expect(future.timeUntilLock.inHours, greaterThan(0));
  });

  test('Race.isJokerWindowOpen false more than 24h before lock', () {
    final far = Race(
      id: 'jr1',
      round: 3,
      name: 'Test',
      circuit: 'Circuit',
      qualifyingAt: DateTime.now().add(const Duration(days: 5)),
      raceAt: DateTime.now().add(const Duration(days: 6)),
      lockAt: DateTime.now().add(const Duration(days: 5)),
      status: RaceStatus.upcoming,
    );
    expect(far.isJokerWindowOpen, false);
    expect(far.timeUntilJokerOpens.inHours, greaterThan(0));
  });

  test('Race.isJokerWindowOpen true within 24h of lock', () {
    final near = Race(
      id: 'jr2',
      round: 4,
      name: 'Test',
      circuit: 'Circuit',
      qualifyingAt: DateTime.now().add(const Duration(hours: 12)),
      raceAt: DateTime.now().add(const Duration(hours: 36)),
      lockAt: DateTime.now().add(const Duration(hours: 6)),
      status: RaceStatus.upcoming,
    );
    expect(near.isJokerWindowOpen, true);
    expect(near.timeUntilJokerOpens.isNegative, true);
  });

  test('Prediction.copyWith preserves race_id', () {
    final p = Prediction(raceId: 'r1', winnerDriverId: 'd1');
    final p2 = p.copyWith(p1Id: 'd2');
    expect(p2.raceId, 'r1');
    expect(p2.winnerDriverId, 'd1');
    expect(p2.p1Id, 'd2');
  });
}
