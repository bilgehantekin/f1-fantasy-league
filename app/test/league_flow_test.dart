import 'package:flutter_test/flutter_test.dart';

import 'package:gridcall/core/env.dart';
import 'package:gridcall/features/league/league_controller.dart';

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
  });
}
