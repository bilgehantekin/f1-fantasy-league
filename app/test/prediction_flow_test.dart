import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/prediction/prediction_controller.dart';
import 'package:app/features/prediction/domain/prediction_rules.dart';
import 'package:app/features/prediction/domain/prediction_validator.dart';
import 'package:app/shared/models.dart';

void main() {
  group('prediction flow payloads', () {
    test('main prediction upsert json is league scoped', () {
      final prediction = Prediction(
        raceId: 'race-1',
        winnerDriverId: 'nor',
        p1Id: 'nor',
        p2Id: 'pia',
        p3Id: 'lec',
        poleDriverId: 'nor',
        fastestLapDriverId: 'ver',
        dnfCount: 2,
        jokerOption: 'yes',
      );

      final json = prediction.toUpsertJson('user-1', leagueId: 'league-a');

      expect(json['user_id'], 'user-1');
      expect(json['race_id'], 'race-1');
      expect(json['league_id'], 'league-a');
      expect(json['winner_driver_id'], 'nor');
      expect(json['fastest_lap_driver_id'], 'ver');
      expect(json['joker_option'], 'yes');
    });

    test('copyWith updates draft fields without changing identity fields', () {
      final original = Prediction(
        id: 'prediction-1',
        raceId: 'race-1',
        leagueId: 'league-a',
        winnerDriverId: 'nor',
        p1Id: 'nor',
        score: 44,
      );

      final updated = original.copyWith(
        winnerDriverId: 'pia',
        p2Id: 'lec',
        jokerOption: 'yes',
      );

      expect(updated.id, 'prediction-1');
      expect(updated.raceId, 'race-1');
      expect(updated.leagueId, 'league-a');
      expect(updated.score, 44);
      expect(updated.winnerDriverId, 'pia');
      expect(updated.p1Id, 'nor');
      expect(updated.p2Id, 'lec');
      expect(updated.jokerOption, 'yes');
    });

    test('sprint prediction upsert json is stored in sprint shape', () {
      final prediction = SprintPrediction(
        raceId: 'race-1',
        winnerDriverId: 'nor',
        p1Id: 'nor',
        p2Id: 'pia',
        p3Id: 'lec',
        poleDriverId: 'nor',
        dnfCount: 2,
      );

      final json = prediction.toUpsertJson('user-1', leagueId: 'league-a');

      expect(json['user_id'], 'user-1');
      expect(json['race_id'], 'race-1');
      expect(json['league_id'], 'league-a');
      expect(json['winner_driver_id'], 'nor');
      expect(json['pole_driver_id'], 'nor');
      expect(json.containsKey('fastest_lap_driver_id'), false);
      expect(json.containsKey('joker_option'), false);
    });

    test('same draft can produce payloads for multiple target leagues', () {
      final prediction = Prediction(
        raceId: 'race-1',
        winnerDriverId: 'nor',
        p1Id: 'nor',
        p2Id: 'pia',
        p3Id: 'lec',
      );

      final payloads = [
        for (final leagueId in ['league-a', 'league-b', 'league-c'])
          prediction.toUpsertJson('user-1', leagueId: leagueId),
      ];

      expect(payloads.map((p) => p['league_id']), [
        'league-a',
        'league-b',
        'league-c',
      ]);
      expect(payloads.map((p) => p['race_id']).toSet(), {'race-1'});
      expect(payloads.map((p) => p['user_id']).toSet(), {'user-1'});
    });

    test('target league ids are normalized before copy', () {
      expect(
        normalizeTargetLeagueIds([' league-a ', '', 'league-b', 'league-a']),
        {'league-a', 'league-b'},
      );
    });

    test('save validation requires league context', () {
      expect(
        validatePredictionSave(leagueId: null),
        'Tahmin kaydetmek için lig bağlamı gerekli',
      );
      expect(validatePredictionSave(leagueId: 'league-a'), isNull);
    });

    test('sprint copyWith preserves race and league while updating picks', () {
      final original = SprintPrediction(
        id: 'sprint-1',
        raceId: 'race-1',
        leagueId: 'league-a',
        winnerDriverId: 'nor',
        score: 12,
      );

      final updated = original.copyWith(
        winnerDriverId: 'pia',
        poleDriverId: 'lec',
        dnfCount: 1,
      );

      expect(updated.id, 'sprint-1');
      expect(updated.raceId, 'race-1');
      expect(updated.leagueId, 'league-a');
      expect(updated.score, 12);
      expect(updated.winnerDriverId, 'pia');
      expect(updated.poleDriverId, 'lec');
      expect(updated.dnfCount, 1);
    });

    test('same race in different leagues has different provider keys', () {
      const firstLeague = PredictionKey(raceId: 'race-1', leagueId: 'league-a');
      const secondLeague = PredictionKey(
        raceId: 'race-1',
        leagueId: 'league-b',
      );
      const sameAsFirst = PredictionKey(raceId: 'race-1', leagueId: 'league-a');

      expect(firstLeague, isNot(secondLeague));
      expect(firstLeague, sameAsFirst);
      expect(firstLeague.hashCode, sameAsFirst.hashCode);
    });
  });
}
