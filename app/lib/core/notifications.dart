import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'env.dart';
import 'supabase.dart';
import '../shared/models.dart';

const _scheduledReminderIdsKey = 'reminders.scheduledNotificationIds';

int stableNotificationId(String raceId, String leagueId, String kind) {
  final input = '$raceId:$leagueId:$kind';
  var hash = 0;
  for (final codeUnit in input.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

class ReminderPreferences {
  final bool enabled;
  final int hoursBeforeLock;
  final bool onlyMissingPrediction;

  const ReminderPreferences({
    required this.enabled,
    required this.hoursBeforeLock,
    required this.onlyMissingPrediction,
  });

  static const disabled = ReminderPreferences(
    enabled: false,
    hoursBeforeLock: 1,
    onlyMissingPrediction: true,
  );

  static Future<ReminderPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderPreferences(
      enabled: prefs.getBool('reminders.enabled') ?? false,
      hoursBeforeLock: prefs.getInt('reminders.hoursBeforeLock') ?? 1,
      onlyMissingPrediction:
          prefs.getBool('reminders.onlyMissingPrediction') ?? true,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders.enabled', enabled);
    await prefs.setInt('reminders.hoursBeforeLock', hoursBeforeLock);
    await prefs.setBool(
      'reminders.onlyMissingPrediction',
      onlyMissingPrediction,
    );
  }

  ReminderPreferences copyWith({
    bool? enabled,
    int? hoursBeforeLock,
    bool? onlyMissingPrediction,
  }) {
    return ReminderPreferences(
      enabled: enabled ?? this.enabled,
      hoursBeforeLock: hoursBeforeLock ?? this.hoursBeforeLock,
      onlyMissingPrediction:
          onlyMissingPrediction ?? this.onlyMissingPrediction,
    );
  }
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // notification.presentationOptions: foreground'da banner+sound göster
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await init();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permission granted: $granted');
      return granted ?? false;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      debugPrint('Android notification permission: $status');
      return status.isGranted;
    }

    return true;
  }

  Future<NotificationsEnabledOptions?> checkPermissions() async {
    await init();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return ios?.checkPermissions();
  }

  Future<void> scheduleForRaces(
    List<Race> races, {
    ReminderPreferences? preferences,
  }) async {
    await init();
    final prefs = preferences ?? await ReminderPreferences.load();
    await _cancelScheduledReminderIds();
    if (!prefs.enabled) return;

    final now = DateTime.now();
    final leagueIds = await _seasonLeagueIds();
    if (leagueIds.isEmpty) return;
    final completedKeys = prefs.onlyMissingPrediction
        ? await _completedPredictionKeys(leagueIds)
        : <String>{};
    final scheduledIds = <int>{};

    for (final race in races) {
      for (final leagueId in leagueIds) {
        if (race.status != RaceStatus.finished &&
            race.status != RaceStatus.cancelled) {
          final mainKey = _predictionKey(
            raceId: race.id,
            leagueId: leagueId,
            sprint: false,
          );
          if (!completedKeys.contains(mainKey)) {
            final lockReminder = race.effectiveLockAt.subtract(
              Duration(hours: prefs.hoursBeforeLock),
            );
            if (lockReminder.isAfter(now)) {
              final id = _idFor(race.id, leagueId, 'main');
              final scheduled = await _scheduleAt(
                id: id,
                title: '${race.name} yarış tahmini yaklaşıyor',
                body:
                    'Ana yarış tahminlerin kilitlenmek üzere. Aç ve seçimlerini yap.',
                when: lockReminder,
              );
              if (scheduled) scheduledIds.add(id);
            }
          }
        }

        if (race.hasSprint &&
            race.effectiveSprintLockAt != null &&
            race.sprintStatus != RaceStatus.finished &&
            race.sprintStatus != RaceStatus.cancelled) {
          final sprintKey = _predictionKey(
            raceId: race.id,
            leagueId: leagueId,
            sprint: true,
          );
          if (!completedKeys.contains(sprintKey)) {
            final sprintReminder = race.effectiveSprintLockAt!.subtract(
              Duration(hours: prefs.hoursBeforeLock),
            );
            if (sprintReminder.isAfter(now)) {
              final id = _idFor(race.id, leagueId, 'sprint');
              final scheduled = await _scheduleAt(
                id: id,
                title: '${race.name} sprint tahmini yaklaşıyor',
                body:
                    'Sprint tahminlerin kilitlenmek üzere. Aç ve seçimlerini yap.',
                when: sprintReminder,
              );
              if (scheduled) scheduledIds.add(id);
            }
          }
        }
      }
    }
    await _saveScheduledReminderIds(scheduledIds);
  }

  Future<void> cancelForRace(String raceId) async {
    await init();
    final leagueIds = await _seasonLeagueIds();
    for (final leagueId in leagueIds) {
      await _plugin.cancel(_idFor(raceId, leagueId, 'main'));
      await _plugin.cancel(_idFor(raceId, leagueId, 'sprint'));
    }
  }

  Future<void> cancelForPrediction({
    required String raceId,
    required String leagueId,
    required bool sprint,
  }) async {
    await init();
    await _plugin.cancel(_idFor(raceId, leagueId, sprint ? 'sprint' : 'main'));
  }

  /// Test amaçlı: hemen bir bildirim göster
  Future<void> showTest() async {
    await init();
    await _plugin.show(
      999999,
      'GridCall test',
      'Bildirimler çalışıyor 🏎️',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
        android: AndroidNotificationDetails(
          'gridcall_general',
          'Genel',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<bool> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
          ),
          android: AndroidNotificationDetails(
            'gridcall_reminders',
            'Hatırlatmalar',
            channelDescription: 'Yarış öncesi tahmin hatırlatmaları',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      // Permission yoksa veya past time - sessizce geç
      debugPrint('Notification schedule failed: $e');
      return false;
    }
  }

  // race_id + league_id + kind → 32-bit int (notification id)
  int _idFor(String raceId, String leagueId, String kind) =>
      stableNotificationId(raceId, leagueId, kind);

  Future<void> _cancelScheduledReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_scheduledReminderIdsKey) ?? const [];
    for (final rawId in rawIds) {
      final id = int.tryParse(rawId);
      if (id != null) await _plugin.cancel(id);
    }
    await prefs.remove(_scheduledReminderIdsKey);
  }

  Future<void> _saveScheduledReminderIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(_scheduledReminderIdsKey);
      return;
    }
    await prefs.setStringList(
      _scheduledReminderIdsKey,
      ids.map((id) => id.toString()).toList()..sort(),
    );
  }

  String _predictionKey({
    required String raceId,
    required String leagueId,
    required bool sprint,
  }) => '${sprint ? 'sprint' : 'main'}:$raceId:$leagueId';

  Future<Set<String>> _seasonLeagueIds() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    final memberships = await supabase
        .from('league_memberships')
        .select('league_id, league:leagues!inner(season_id)')
        .eq('user_id', user.id)
        .eq('league.season_id', Env.seasonId);
    return memberships.map((e) => e['league_id'] as String).toSet();
  }

  Future<Set<String>> _completedPredictionKeys(Set<String> leagueIds) async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    if (leagueIds.isEmpty) return {};

    final mainRows = await supabase
        .from('predictions')
        .select('race_id, league_id')
        .eq('user_id', user.id)
        .inFilter('league_id', leagueIds.toList());
    final sprintRows = await supabase
        .from('sprint_predictions')
        .select('race_id, league_id')
        .eq('user_id', user.id)
        .inFilter('league_id', leagueIds.toList());

    final keys = <String>{};
    for (final row in mainRows) {
      keys.add(
        _predictionKey(
          raceId: row['race_id'] as String,
          leagueId: row['league_id'] as String,
          sprint: false,
        ),
      );
    }
    for (final row in sprintRows) {
      keys.add(
        _predictionKey(
          raceId: row['race_id'] as String,
          leagueId: row['league_id'] as String,
          sprint: true,
        ),
      );
    }
    return keys;
  }
}

// Sezonun yarışlarını çekip tüm hatırlatmaları kurar (login sonrası çağrılır).
Future<void> rescheduleAllReminders(int seasonId) async {
  final rows = await supabase
      .from('races')
      .select()
      .eq('season_id', seasonId)
      .order('round');
  final races = rows.map((e) => Race.fromJson(e)).toList();
  await NotificationService.instance.scheduleForRaces(races);
}
