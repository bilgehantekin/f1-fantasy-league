import 'package:flutter_test/flutter_test.dart';

import 'package:gridcall/core/env.dart';
import 'package:gridcall/features/league/league_controller.dart';
import 'package:gridcall/shared/models.dart';

void main() {
  group('league flow helpers', () {
    test('invite code is trimmed and uppercased before join rpc', () {
      expect(normalizeInviteCode(' abc123xy '), 'ABC123XY');
      expect(normalizeInviteCode('\nGrid4ll7\t'), 'GRID4LL7');
    });

    test('production invite links use HTTPS fallback URL', () {
      expect(
        Env.joinUri(' abc123xy ').toString(),
        'https://gridcall.app/join/ABC123XY',
      );
    });

    test('my leagues sorting puts favorites first then names', () {
      final leagues = [
        League(
          id: '2',
          name: 'Zulu',
          type: 'private',
          ownerId: null,
          inviteCode: 'BBBBBBBB',
          seasonId: Env.seasonId,
        ),
        League(
          id: '1',
          name: 'Alpha',
          type: 'private',
          ownerId: null,
          inviteCode: 'AAAAAAAA',
          seasonId: Env.seasonId,
          isFavorite: true,
        ),
        League(
          id: '3',
          name: 'Beta',
          type: 'private',
          ownerId: null,
          inviteCode: 'CCCCCCCC',
          seasonId: Env.seasonId,
          isFavorite: true,
        ),
      ]..sort(compareLeaguesForMyLeagues);

      expect(leagues.map((league) => league.name), ['Alpha', 'Beta', 'Zulu']);
    });
  });
}
