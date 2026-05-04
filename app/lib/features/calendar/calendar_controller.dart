import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../shared/models.dart';

final racesProvider = FutureProvider<List<Race>>((ref) async {
  final rows = await supabase
      .from('races')
      .select()
      .eq('season_id', Env.seasonId)
      .neq('status', 'cancelled')
      .order('round');
  return rows.map((e) => Race.fromJson(e)).toList();
});

final driverStandingsProvider = FutureProvider<List<DriverStanding>>((
  ref,
) async {
  final drivers = await _seasonDrivers();
  final rows = await _standingsRows();
  final byDriver = <String, _DriverStandingAccumulator>{};

  for (final driver in drivers) {
    byDriver[driver.id] = _DriverStandingAccumulator(
      code: driver.code,
      name: driver.fullName,
      teamName: driver.teamName ?? 'Takımsız',
      teamColor: driver.teamColor ?? '#FFFFFF',
    );
  }

  for (final row in rows) {
    final current = byDriver.putIfAbsent(
      row.driverId,
      () => _DriverStandingAccumulator(
        code: row.driverCode,
        name: row.driverName,
        teamName: row.teamName,
        teamColor: row.teamColor,
      ),
    );
    current.points += row.points;
  }

  final standings =
      byDriver.values
          .map(
            (e) => DriverStanding(
              position: 0,
              code: e.code,
              name: e.name,
              teamName: e.teamName,
              teamColor: e.teamColor,
              points: e.points,
            ),
          )
          .toList()
        ..sort((a, b) {
          final points = b.points.compareTo(a.points);
          if (points != 0) return points;
          return a.name.compareTo(b.name);
        });

  return [
    for (var i = 0; i < standings.length; i++)
      standings[i].copyWith(position: i + 1),
  ];
});

final constructorStandingsProvider = FutureProvider<List<ConstructorStanding>>((
  ref,
) async {
  final teams = await _seasonTeams();
  final rows = await _standingsRows();
  final byTeam = <String, _ConstructorStandingAccumulator>{};

  for (final team in teams) {
    byTeam[team.id] = _ConstructorStandingAccumulator(
      name: team.name,
      color: team.color ?? '#FFFFFF',
    );
  }

  for (final row in rows) {
    final current = byTeam.putIfAbsent(
      row.teamId ?? row.teamName,
      () => _ConstructorStandingAccumulator(
        name: row.teamName,
        color: row.teamColor,
      ),
    );
    current.points += row.points;
  }

  final standings =
      byTeam.values
          .map(
            (e) => ConstructorStanding(
              position: 0,
              name: e.name,
              color: e.color,
              points: e.points,
            ),
          )
          .toList()
        ..sort((a, b) {
          final points = b.points.compareTo(a.points);
          if (points != 0) return points;
          return a.name.compareTo(b.name);
        });

  return [
    for (var i = 0; i < standings.length; i++)
      standings[i].copyWith(position: i + 1),
  ];
});

Future<List<Driver>> _seasonDrivers() async {
  final rows = await supabase
      .from('drivers')
      .select('*, team:teams(id, code, name, color)')
      .eq('season_id', Env.seasonId)
      .order('full_name');
  return rows.map((e) => Driver.fromJson(e)).toList();
}

Future<List<Team>> _seasonTeams() async {
  final rows = await supabase
      .from('teams')
      .select()
      .eq('season_id', Env.seasonId)
      .order('name');
  return rows.map((e) => Team.fromJson(e)).toList();
}

class DriverStanding {
  final int position;
  final String code;
  final String name;
  final String teamName;
  final String teamColor;
  final int points;

  const DriverStanding({
    required this.position,
    required this.code,
    required this.name,
    required this.teamName,
    required this.teamColor,
    required this.points,
  });

  DriverStanding copyWith({int? position}) => DriverStanding(
    position: position ?? this.position,
    code: code,
    name: name,
    teamName: teamName,
    teamColor: teamColor,
    points: points,
  );
}

class ConstructorStanding {
  final int position;
  final String name;
  final String color;
  final int points;

  const ConstructorStanding({
    required this.position,
    required this.name,
    required this.color,
    required this.points,
  });

  ConstructorStanding copyWith({int? position}) => ConstructorStanding(
    position: position ?? this.position,
    name: name,
    color: color,
    points: points,
  );
}

Future<List<_StandingRaceRow>> _standingsRows() async {
  final raceRows = await supabase
      .from('races')
      .select('id')
      .eq('season_id', Env.seasonId);
  final raceIds = raceRows.map((e) => e['id'] as String).toList();
  if (raceIds.isEmpty) return const [];

  final mainRows = await _classificationRows(
    table: 'race_classifications',
    raceIds: raceIds,
    pointsByPosition: _mainRacePoints,
  );
  final sprintRows = await _classificationRows(
    table: 'sprint_classifications',
    raceIds: raceIds,
    pointsByPosition: _sprintRacePoints,
  );

  return [...mainRows, ...sprintRows];
}

Future<List<_StandingRaceRow>> _classificationRows({
  required String table,
  required List<String> raceIds,
  required Map<int, int> pointsByPosition,
}) async {
  final rows = await supabase
      .from(table)
      .select(
        'driver_id, position, status, '
        'driver:drivers(id, code, full_name, team:teams(id, name, color))',
      )
      .inFilter('race_id', raceIds);

  return rows.map((row) {
    final driver = row['driver'] as Map<String, dynamic>? ?? const {};
    final team = driver['team'] as Map<String, dynamic>? ?? const {};
    final position = (row['position'] as num?)?.toInt();
    final status = (row['status'] as String?) ?? 'finished';
    final points = status == 'finished' && position != null
        ? pointsByPosition[position] ?? 0
        : 0;

    return _StandingRaceRow(
      driverId: row['driver_id'] as String,
      driverCode: (driver['code'] as String?) ?? '-',
      driverName: (driver['full_name'] as String?) ?? 'Bilinmeyen Sürücü',
      teamId: team['id'] as String?,
      teamName: (team['name'] as String?) ?? 'Takımsız',
      teamColor: (team['color'] as String?) ?? '#FFFFFF',
      points: points,
    );
  }).toList();
}

const _mainRacePoints = {
  1: 25,
  2: 18,
  3: 15,
  4: 12,
  5: 10,
  6: 8,
  7: 6,
  8: 4,
  9: 2,
  10: 1,
};

const _sprintRacePoints = {1: 8, 2: 7, 3: 6, 4: 5, 5: 4, 6: 3, 7: 2, 8: 1};

class _StandingRaceRow {
  final String driverId;
  final String driverCode;
  final String driverName;
  final String? teamId;
  final String teamName;
  final String teamColor;
  final int points;

  const _StandingRaceRow({
    required this.driverId,
    required this.driverCode,
    required this.driverName,
    required this.teamId,
    required this.teamName,
    required this.teamColor,
    required this.points,
  });
}

class _DriverStandingAccumulator {
  final String code;
  final String name;
  final String teamName;
  final String teamColor;
  int points = 0;

  _DriverStandingAccumulator({
    required this.code,
    required this.name,
    required this.teamName,
    required this.teamColor,
  });
}

class _ConstructorStandingAccumulator {
  final String name;
  final String color;
  int points = 0;

  _ConstructorStandingAccumulator({required this.name, required this.color});
}
