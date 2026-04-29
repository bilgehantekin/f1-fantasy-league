// PitWall — domain modelleri (POCO; fromJson Supabase select sonuçlarına eşlenir)

class Profile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String tier;
  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.tier = 'free',
  });
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        username: j['username'] as String,
        avatarUrl: j['avatar_url'] as String?,
        tier: (j['tier'] as String?) ?? 'free',
      );
  bool get isPremium => tier == 'premium';
}

class Team {
  final String id;
  final String code;
  final String name;
  final String? color;
  Team({required this.id, required this.code, required this.name, this.color});
  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        color: j['color'] as String?,
      );
}

class Driver {
  final String id;
  final String code;
  final String fullName;
  final int? number;
  final String? teamId;
  final String? teamCode;
  final String? teamName;
  final String? teamColor;
  Driver({
    required this.id,
    required this.code,
    required this.fullName,
    this.number,
    this.teamId,
    this.teamCode,
    this.teamName,
    this.teamColor,
  });
  factory Driver.fromJson(Map<String, dynamic> j) {
    final team = j['team'] as Map<String, dynamic>?;
    return Driver(
      id: j['id'] as String,
      code: j['code'] as String,
      fullName: j['full_name'] as String,
      number: j['number'] as int?,
      teamId: j['team_id'] as String?,
      teamCode: team?['code'] as String?,
      teamName: team?['name'] as String?,
      teamColor: team?['color'] as String?,
    );
  }
}

enum RaceStatus { upcoming, locked, live, finished }

RaceStatus _parseStatus(String s) =>
    RaceStatus.values.firstWhere((e) => e.name == s, orElse: () => RaceStatus.upcoming);

class Race {
  final String id;
  final int round;
  final String name;
  final String circuit;
  final DateTime qualifyingAt;
  final DateTime raceAt;
  final DateTime lockAt;
  final RaceStatus status;
  Race({
    required this.id,
    required this.round,
    required this.name,
    required this.circuit,
    required this.qualifyingAt,
    required this.raceAt,
    required this.lockAt,
    required this.status,
  });
  factory Race.fromJson(Map<String, dynamic> j) => Race(
        id: j['id'] as String,
        round: j['round'] as int,
        name: j['name'] as String,
        circuit: j['circuit'] as String,
        qualifyingAt: DateTime.parse(j['qualifying_at'] as String),
        raceAt: DateTime.parse(j['race_at'] as String),
        lockAt: DateTime.parse(j['lock_at'] as String),
        status: _parseStatus(j['status'] as String),
      );

  bool get isLocked => DateTime.now().isAfter(lockAt);
  Duration get timeUntilLock => lockAt.difference(DateTime.now());
}

class JokerQuestion {
  final String id;
  final String raceId;
  final String text;
  final List<String> options;
  final int points;
  JokerQuestion({
    required this.id,
    required this.raceId,
    required this.text,
    required this.options,
    required this.points,
  });
  factory JokerQuestion.fromJson(Map<String, dynamic> j) => JokerQuestion(
        id: j['id'] as String,
        raceId: j['race_id'] as String,
        text: j['text'] as String,
        options: (j['options'] as List).map((e) => e as String).toList(),
        points: j['points'] as int,
      );
}

class Prediction {
  final String? id;
  final String raceId;
  final String? winnerDriverId;
  final String? p1Id;
  final String? p2Id;
  final String? p3Id;
  final String? poleDriverId;
  final String? fastestLapDriverId;
  final int? dnfCount;
  final String? jokerOption;
  final int? score;
  Prediction({
    this.id,
    required this.raceId,
    this.winnerDriverId,
    this.p1Id,
    this.p2Id,
    this.p3Id,
    this.poleDriverId,
    this.fastestLapDriverId,
    this.dnfCount,
    this.jokerOption,
    this.score,
  });
  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
        id: j['id'] as String?,
        raceId: j['race_id'] as String,
        winnerDriverId: j['winner_driver_id'] as String?,
        p1Id: j['p1_id'] as String?,
        p2Id: j['p2_id'] as String?,
        p3Id: j['p3_id'] as String?,
        poleDriverId: j['pole_driver_id'] as String?,
        fastestLapDriverId: j['fastest_lap_driver_id'] as String?,
        dnfCount: j['dnf_count'] as int?,
        jokerOption: j['joker_option'] as String?,
        score: j['score'] as int?,
      );

  Map<String, dynamic> toUpsertJson(String userId) => {
        'user_id': userId,
        'race_id': raceId,
        'winner_driver_id': winnerDriverId,
        'p1_id': p1Id,
        'p2_id': p2Id,
        'p3_id': p3Id,
        'pole_driver_id': poleDriverId,
        'fastest_lap_driver_id': fastestLapDriverId,
        'dnf_count': dnfCount,
        'joker_option': jokerOption,
      };

  Prediction copyWith({
    String? winnerDriverId,
    String? p1Id,
    String? p2Id,
    String? p3Id,
    String? poleDriverId,
    String? fastestLapDriverId,
    int? dnfCount,
    String? jokerOption,
  }) =>
      Prediction(
        id: id,
        raceId: raceId,
        winnerDriverId: winnerDriverId ?? this.winnerDriverId,
        p1Id: p1Id ?? this.p1Id,
        p2Id: p2Id ?? this.p2Id,
        p3Id: p3Id ?? this.p3Id,
        poleDriverId: poleDriverId ?? this.poleDriverId,
        fastestLapDriverId: fastestLapDriverId ?? this.fastestLapDriverId,
        dnfCount: dnfCount ?? this.dnfCount,
        jokerOption: jokerOption ?? this.jokerOption,
        score: score,
      );
}

class League {
  final String id;
  final String name;
  final String type;
  final String ownerId;
  final String inviteCode;
  final int seasonId;
  League({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.inviteCode,
    required this.seasonId,
  });
  factory League.fromJson(Map<String, dynamic> j) => League(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        ownerId: j['owner_id'] as String,
        inviteCode: j['invite_code'] as String,
        seasonId: j['season_id'] as int,
      );
}

class AppBadge {
  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String rarity;
  AppBadge({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
  });
  factory AppBadge.fromJson(Map<String, dynamic> j) => AppBadge(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        icon: j['icon'] as String,
        rarity: j['rarity'] as String,
      );
}

class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final String? raceId;
  final DateTime awardedAt;
  final AppBadge? badge;
  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    this.raceId,
    required this.awardedAt,
    this.badge,
  });
  factory UserBadge.fromJson(Map<String, dynamic> j) => UserBadge(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        badgeId: j['badge_id'] as String,
        raceId: j['race_id'] as String?,
        awardedAt: DateTime.parse(j['awarded_at'] as String),
        badge: j['badge'] is Map<String, dynamic>
            ? AppBadge.fromJson(j['badge'] as Map<String, dynamic>)
            : null,
      );
}

class StandingRow {
  final String userId;
  final String username;
  final int score;
  final int rank;
  StandingRow({
    required this.userId,
    required this.username,
    required this.score,
    required this.rank,
  });
  factory StandingRow.weekly(Map<String, dynamic> j) => StandingRow(
        userId: j['user_id'] as String,
        username: j['username'] as String,
        score: (j['score'] ?? 0) as int,
        rank: (j['rnk'] as num).toInt(),
      );
  factory StandingRow.season(Map<String, dynamic> j) => StandingRow(
        userId: j['user_id'] as String,
        username: j['username'] as String,
        score: ((j['total_score'] ?? 0) as num).toInt(),
        rank: (j['rnk'] as num).toInt(),
      );
}
