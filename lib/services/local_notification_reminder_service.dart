import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/checklist_template.dart';
import 'reminder_service.dart';

class LocalNotificationReminderService implements ReminderService {
  static const _channelId = 'daily-template-reminders';
  static const _channelName = 'Daily template reminders';
  static const _channelDescription =
      'Daily reminders to complete scheduled checklist templates';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalNotificationReminderService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get _supportsScheduledNotifications {
    if (kIsWeb) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  Future<void> init() async {
    if (_initialized || !_supportsScheduledNotifications) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_supportsScheduledNotifications) return true;

    await init();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                ) ??
            false;
      case TargetPlatform.macOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                ) ??
            false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
    }
  }

  @override
  Future<void> syncAllTemplateReminders(
      List<ChecklistTemplate> templates) async {
    if (!_supportsScheduledNotifications) return;

    await init();

    final scheduledIds = <int>{};
    for (final template in templates) {
      if (template.dailySchedule == null) continue;
      scheduledIds.add(_notificationIdFor(template.id));
      await _scheduleTemplateReminder(template);
    }

    final pendingRequests = await _plugin.pendingNotificationRequests();
    for (final request in pendingRequests) {
      final payload = request.payload;
      if (payload == null || !payload.startsWith('template:')) continue;
      if (!scheduledIds.contains(request.id)) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> syncTemplateReminder(ChecklistTemplate template) async {
    if (!_supportsScheduledNotifications) return;

    await init();
    if (template.dailySchedule == null) {
      await cancelTemplateReminder(template.id);
      return;
    }

    await _scheduleTemplateReminder(template);
  }

  @override
  Future<void> cancelTemplateReminder(String templateId) async {
    if (!_supportsScheduledNotifications) return;

    await init();
    await _plugin.cancel(id: _notificationIdFor(templateId));
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _scheduleTemplateReminder(ChecklistTemplate template) async {
    final schedule = template.dailySchedule;
    if (schedule == null) return;

    await _plugin.zonedSchedule(
      id: _notificationIdFor(template.id),
      title: template.label,
      body: 'Complete today\'s checklist and open the app to start it.',
      scheduledDate: _nextScheduledDate(schedule),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'template:${template.id}',
    );
  }

  tz.TZDateTime _nextScheduledDate(DailyTemplateSchedule schedule) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
    );

    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  int _notificationIdFor(String templateId) => templateId.hashCode & 0x7fffffff;
}
