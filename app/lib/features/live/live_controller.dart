import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase.dart';
import '../../shared/models.dart';

class LivePosition {
  final String driverId;
  final int? position;
  final String status;
  final DateTime updatedAt;
  LivePosition({
    required this.driverId,
    required this.position,
    required this.status,
    required this.updatedAt,
  });
  factory LivePosition.fromJson(Map<String, dynamic> j) => LivePosition(
    driverId: j['driver_id'] as String,
    position: j['position'] as int?,
    status: j['status'] as String,
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}

/// Initial fetch + realtime subscription kombine eder.
final livePositionsProvider = StreamProvider.family<List<LivePosition>, String>((
  ref,
  raceId,
) async* {
  // İlk yükleme
  final initial = await supabase
      .from('live_positions')
      .select()
      .eq('race_id', raceId);
  var current = initial.map((e) => LivePosition.fromJson(e)).toList();
  yield current;

  // Realtime channel
  final channel = supabase.channel('race:$raceId:positions');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'live_positions',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'race_id',
      value: raceId,
    ),
    callback: (payload) {
      // Bir sonraki yield için tetikleyici; provider auto-refetch yerine basit polling de yapabilir
    },
  );
  channel.subscribe();

  // Postgres change'leri yakalamak için stream'i akıllı yapmadan,
  // pratik MVP: 5sn'de bir refetch.
  while (true) {
    await Future.delayed(const Duration(seconds: 5));
    final rows = await supabase
        .from('live_positions')
        .select()
        .eq('race_id', raceId);
    current = rows.map((e) => LivePosition.fromJson(e)).toList();
    yield current;
  }
});

class LiveComparison {
  final String label;
  final Driver? predicted;
  final Driver? actual;
  final bool? matches;
  LiveComparison({
    required this.label,
    required this.predicted,
    required this.actual,
    required this.matches,
  });
}

List<LiveComparison> buildComparisons({
  required Prediction? prediction,
  required List<LivePosition> positions,
  required List<Driver> drivers,
}) {
  final byPosition = <int, Driver>{};
  for (final p in positions) {
    if (p.position == null) continue;
    Driver? d;
    for (final dr in drivers) {
      if (dr.id == p.driverId) {
        d = dr;
        break;
      }
    }
    if (d != null) byPosition[p.position!] = d;
  }

  Driver? findById(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Driver? predictedDriver(String? id) => findById(id);

  if (prediction == null) {
    return [
      LiveComparison(
        label: 'P1 ŞU AN',
        predicted: null,
        actual: byPosition[1],
        matches: null,
      ),
      LiveComparison(
        label: 'P2 ŞU AN',
        predicted: null,
        actual: byPosition[2],
        matches: null,
      ),
      LiveComparison(
        label: 'P3 ŞU AN',
        predicted: null,
        actual: byPosition[3],
        matches: null,
      ),
    ];
  }

  return [
    _cmp('KAZANAN', predictedDriver(prediction.winnerDriverId), byPosition[1]),
    _cmp('P1', predictedDriver(prediction.p1Id), byPosition[1]),
    _cmp('P2', predictedDriver(prediction.p2Id), byPosition[2]),
    _cmp('P3', predictedDriver(prediction.p3Id), byPosition[3]),
  ];
}

LiveComparison _cmp(String label, Driver? pred, Driver? actual) =>
    LiveComparison(
      label: label,
      predicted: pred,
      actual: actual,
      matches: (pred == null || actual == null) ? null : pred.id == actual.id,
    );
