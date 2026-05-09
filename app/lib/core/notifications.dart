import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'env.dart';
import '../l10n/generated/app_localizations.dart';
import 'navigation.dart';
import 'supabase.dart';
import '../shared/models.dart';

const _scheduledReminderIdsKey = 'reminders.scheduledNotificationIds';
const _scheduledPostRaceIdsKey = 'postRace.scheduledNotificationIds';
const _postRaceKind = 'post_race_summary';

int stableNotificationId(String raceId, String leagueId, String kind) {
  final input = '$raceId:$leagueId:$kind';
  var hash = 0;
  for (final codeUnit in input.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

int postRaceSummaryNotificationId(String raceId) =>
    stableNotificationId(raceId, 'public', _postRaceKind);

DateTime postRaceSummaryNotificationTime(Race race) {
  final raceSession = race.sessions
      .where((session) {
        final type = session.sessionType.toLowerCase();
        final name = session.sessionName.toLowerCase();
        return type == 'race' || name == 'race' || name.contains('grand prix');
      })
      .fold<RaceSession?>(null, (best, session) {
        if (best == null) return session;
        return session.sortOrder > best.sortOrder ? session : best;
      });
  final base = raceSession?.endsAt ?? race.raceAt.add(const Duration(hours: 2));
  return base.add(const Duration(hours: 3));
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

class PostRaceSummaryPreferences {
  final bool enabled;

  const PostRaceSummaryPreferences({required this.enabled});

  static const disabled = PostRaceSummaryPreferences(enabled: false);

  static Future<PostRaceSummaryPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PostRaceSummaryPreferences(
      enabled: prefs.getBool('postRaceSummary.enabled') ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('postRaceSummary.enabled', enabled);
  }

  PostRaceSummaryPreferences copyWith({bool? enabled}) =>
      PostRaceSummaryPreferences(enabled: enabled ?? this.enabled);
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
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty || !payload.startsWith('/')) {
          return;
        }
        final context = appNavigatorKey.currentContext;
        if (context != null) context.go(payload);
      },
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
    PostRaceSummaryPreferences? postRacePreferences,
  }) async {
    await init();
    final prefs = preferences ?? await ReminderPreferences.load();
    final postRacePrefs =
        postRacePreferences ?? await PostRaceSummaryPreferences.load();
    await _cancelScheduledReminderIds();
    await _cancelScheduledPostRaceIds();

    final now = DateTime.now();
    final leagueIds = await _seasonLeagueIds();
    if (postRacePrefs.enabled) {
      await _schedulePostRaceSummaries(races, leagueIds: leagueIds, now: now);
    }
    if (!prefs.enabled) return;
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
                title: '${race.name} race prediction is coming up',
                body:
                    'Main race predictions are about to lock. Open the app and make your picks.',
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
                title: '${race.name} sprint prediction is coming up',
                body:
                    'Sprint predictions are about to lock. Open the app and make your picks.',
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

  Future<void> reschedulePostRaceSummaries(
    List<Race> races, {
    PostRaceSummaryPreferences? preferences,
  }) async {
    await init();
    await _cancelScheduledPostRaceIds();
    final prefs = preferences ?? await PostRaceSummaryPreferences.load();
    if (!prefs.enabled) return;
    await _schedulePostRaceSummaries(
      races,
      leagueIds: await _seasonLeagueIds(),
      now: DateTime.now(),
    );
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
      'Notifications are working 🏎️',
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
          'General',
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
    String? payload,
    String channelId = 'gridcall_reminders',
    String channelName = 'Reminders',
    String channelDescription = 'Pre-race prediction reminders',
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        NotificationDetails(
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
          ),
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
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

  Future<void> _cancelScheduledPostRaceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_scheduledPostRaceIdsKey) ?? const [];
    for (final rawId in rawIds) {
      final id = int.tryParse(rawId);
      if (id != null) await _plugin.cancel(id);
    }
    await prefs.remove(_scheduledPostRaceIdsKey);
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

  Future<void> _saveScheduledPostRaceIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(_scheduledPostRaceIdsKey);
      return;
    }
    await prefs.setStringList(
      _scheduledPostRaceIdsKey,
      ids.map((id) => id.toString()).toList()..sort(),
    );
  }

  Future<void> _schedulePostRaceSummaries(
    List<Race> races, {
    required Set<String> leagueIds,
    required DateTime now,
  }) async {
    final scheduledIds = <int>{};
    final preferredLeagueId = await _preferredLeagueId(leagueIds);
    for (final race in races) {
      if (race.isCancelled) continue;
      final when = postRaceSummaryNotificationTime(race);
      if (!when.isAfter(now)) continue;
      final id = postRaceSummaryNotificationId(race.id);
      final route = preferredLeagueId == null
          ? '/race/${race.id}/results'
          : '/leagues/$preferredLeagueId/race/${race.id}/summary';
      final l = _localizations();
      final scheduled = await _scheduleAt(
        id: id,
        title: l.raceResultsNotificationTitle,
        body: l.raceResultsNotificationBody,
        when: when,
        payload: route,
        channelId: 'gridcall_post_race',
        channelName: l.raceResultsNotificationChannelName,
        channelDescription: l.raceResultsNotificationChannelDescription,
      );
      if (scheduled) scheduledIds.add(id);
    }
    await _saveScheduledPostRaceIds(scheduledIds);
  }

  Future<String?> _preferredLeagueId(Set<String> leagueIds) async {
    final user = supabase.auth.currentUser;
    if (user == null || leagueIds.isEmpty) return null;
    try {
      final favorites = await supabase
          .from('league_favorites')
          .select('league_id')
          .eq('user_id', user.id)
          .inFilter('league_id', leagueIds.toList())
          .order('created_at')
          .limit(1);
      if (favorites.isNotEmpty) return favorites.first['league_id'] as String;
    } catch (_) {
      // Premium favorites may not exist on older deployments yet.
    }
    final sorted = leagueIds.toList()..sort();
    return sorted.first;
  }

  AppLocalizations _localizations() {
    final locale = Intl.getCurrentLocale().toLowerCase().startsWith('tr')
        ? const Locale('tr')
        : const Locale('en');
    return lookupAppLocalizations(locale);
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
