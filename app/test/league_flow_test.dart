import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/env.dart';
import 'package:app/features/league/league_controller.dart';

void main() {
  group('league flow helpers', () {
    test('invite code is trimmed and uppercased before join rpc', () {
      expect(normalizeInviteCode(' abc123 '), 'ABC123');
      expect(normalizeInviteCode('\nPitW4ll\t'), 'PITW4LL');
    });

    test('production invite links use HTTPS fallback URL', () {
      expect(
        Env.joinUri(' abc123 ').toString(),
        'https://pitwall.app/join/ABC123',
      );
    });
  });
}
