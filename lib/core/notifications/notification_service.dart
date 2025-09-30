import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _tzInitialized = false;

  static const int _idDaily = 100;
  static const List<int> _milestoneIds = [201, 202, 203, 204, 205, 206, 207];

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'reminders',
      'Quit Reminders',
      description: 'Reminders and milestones for quitting',
      importance: Importance.defaultImportance,
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> _ensureTimezoneInitialized() async {
    if (_tzInitialized) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
      _tzInitialized = true;
    } catch (_) {
      // Fallback to UTC if timezone lookup fails
      tz.setLocalLocation(tz.getLocation('UTC'));
      _tzInitialized = true;
    }
  }

  Future<bool> requestPermissions() async {
    await init();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    bool ok = true;
    if (iosPlugin != null) {
      ok = (await iosPlugin.requestPermissions(alert: true, badge: true, sound: true)) ?? false;
    }
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestPermission();
      ok = ok && (granted ?? true);
    }
    return ok;
  }

  Future<void> showSimple({required String title, required String body}) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails('reminders', 'Quit Reminders'),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(0, title, body, details);
  }

  Future<void> scheduleDailyAt(TimeOfDay time,
      {required String title, required String body}) async {
    await init();
    await _ensureTimezoneInitialized();
    await cancelReminder();
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _idDaily,
      title,
      body,
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Quit Reminders'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_idDaily);
  }

  Future<void> scheduleMilestones(
    DateTime quitDate, {
    required List<MilestoneNotification> milestones,
    required String title,
  }) async {
    await init();
    await _ensureTimezoneInitialized();
    await cancelMilestones();

    final base = tz.TZDateTime.from(quitDate, tz.local);
    var idx = 0;
    for (final milestone in milestones) {
      final when = base.add(milestone.offset);
      if (when.isAfter(tz.TZDateTime.now(tz.local))) {
        final id = _milestoneIds[idx % _milestoneIds.length];
        await _plugin.zonedSchedule(
          id,
          title,
          milestone.body,
          when,
          const NotificationDetails(
            android: AndroidNotificationDetails('reminders', 'Quit Reminders'),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      }
      idx++;
    }
  }

  Future<void> cancelMilestones() async {
    for (final id in _milestoneIds) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

class MilestoneNotification {
  final Duration offset;
  final String body;

  const MilestoneNotification({required this.offset, required this.body});
}
