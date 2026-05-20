import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const bool enableTestExceptions = false;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🔔 INIT
  static Future<void> init() async {
    if (enableTestExceptions) {
      throw Exception("Test: NotificationService init failed!");
    }

    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  /// ⏰ SCHEDULE REMINDER
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminder',
          'Event Reminders',
          channelDescription: 'Event reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// 🧪 TEST – INSTANT NOTIFICATION
  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test Notification',
      'If you see this, notifications WORK 🎉',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
