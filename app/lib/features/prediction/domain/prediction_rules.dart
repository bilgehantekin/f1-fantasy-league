class PredictionKey {
  final String raceId;
  final String? leagueId;

  const PredictionKey({required this.raceId, this.leagueId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionKey &&
          raceId == other.raceId &&
          leagueId == other.leagueId;

  @override
  int get hashCode => Object.hash(raceId, leagueId);
}

Set<String> normalizeTargetLeagueIds(Iterable<String> leagueIds) => leagueIds
    .where((id) => id.trim().isNotEmpty)
    .map((id) => id.trim())
    .toSet();
