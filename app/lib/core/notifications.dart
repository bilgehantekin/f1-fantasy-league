import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'env.dart';
import 'supabase.dart';
import '../shared/models.dart';

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
    if (ios == null) return true; // android veya başka platform
    final granted = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('iOS notification permission granted: $granted');
    return granted ?? false;
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
    await _plugin.cancelAll();
    if (!prefs.enabled) return;

    final now = DateTime.now();
    final fullyPredictedRaceIds = prefs.onlyMissingPrediction
        ? await _fullyPredictedRaceIds()
        : <String>{};

    for (final race in races) {
      if (race.status == RaceStatus.finished) continue;
      if (fullyPredictedRaceIds.contains(race.id)) continue;

      final lockReminder = race.lockAt.subtract(
        Duration(hours: prefs.hoursBeforeLock),
      );
      if (lockReminder.isAfter(now)) {
        await _scheduleAt(
          id: _idFor(race.id, 'lock'),
          title: '${race.name} tahminleri yaklaşıyor',
          body: 'Tahminlerin kilitlenmek üzere. Aç ve seçimlerini yap.',
          when: lockReminder,
        );
      }
    }
  }

  Future<void> cancelForRace(String raceId) async {
    await init();
    await _plugin.cancel(_idFor(raceId, 'lock'));
  }

  /// Test amaçlı: hemen bir bildirim göster
  Future<void> showTest() async {
    await init();
    await _plugin.show(
      999999,
      'PitWall test',
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
          'pitwall_general',
          'Genel',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _scheduleAt({
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
            'pitwall_reminders',
            'Hatırlatmalar',
            channelDescription: 'Yarış öncesi tahmin hatırlatmaları',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Permission yoksa veya past time - sessizce geç
      if (kDebugMode) {
        // ignore: avoid_print
        print('schedule failed: $e');
      }
    }
  }

  // race_id (UUID string) + kind → 32-bit int (notification id)
  int _idFor(String raceId, String kind) {
    final hash = (raceId + kind).hashCode;
    return hash.abs() & 0x7FFFFFFF;
  }

  Future<Set<String>> _fullyPredictedRaceIds() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};
    final memberships = await supabase
        .from('league_memberships')
        .select('league_id, league:leagues!inner(season_id)')
        .eq('user_id', user.id)
        .eq('league.season_id', Env.seasonId);
    final leagueIds = memberships.map((e) => e['league_id'] as String).toSet();
    if (leagueIds.isEmpty) return {};

    final rows = await supabase
        .from('predictions')
        .select('race_id, league_id')
        .eq('user_id', user.id)
        .inFilter('league_id', leagueIds.toList());
    final byRace = <String, Set<String>>{};
    for (final row in rows) {
      final raceId = row['race_id'] as String;
      final leagueId = row['league_id'] as String;
      byRace.putIfAbsent(raceId, () => <String>{}).add(leagueId);
    }
    return {
      for (final entry in byRace.entries)
        if (entry.value.length >= leagueIds.length) entry.key,
    };
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
