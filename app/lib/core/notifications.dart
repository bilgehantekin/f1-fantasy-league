import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'supabase.dart';
import '../shared/models.dart';

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
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
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
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return ios?.checkPermissions();
  }

  /// Yarış başına 2 hatırlatma planlar:
  ///  - lock_at - 1h
  ///  - race_at başlangıç
  /// Geçmiş tarihler iptal edilir.
  Future<void> scheduleForRaces(List<Race> races) async {
    await init();
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final race in races) {
      if (race.status == RaceStatus.finished) continue;

      final lockReminder = race.lockAt.subtract(const Duration(hours: 1));
      if (lockReminder.isAfter(now)) {
        await _scheduleAt(
          id: _idFor(race.id, 'lock'),
          title: '${race.name} — son 1 saat!',
          body: 'Tahminlerin kilitlenmek üzere. Aç ve seçimlerini yap.',
          when: lockReminder,
        );
      }

      if (race.raceAt.isAfter(now)) {
        await _scheduleAt(
          id: _idFor(race.id, 'start'),
          title: '${race.name} başlıyor 🏁',
          body: 'Canlı yarış ekranını aç ve tahminlerinin nasıl gittiğini gör.',
          when: race.raceAt,
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
