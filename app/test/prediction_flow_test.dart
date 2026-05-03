import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/prediction/prediction_controller.dart';
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
