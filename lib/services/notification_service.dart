import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  static Future<void> scheduleCareReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await initialize();

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'growlog_care',
          'Plant Care Reminders',
          channelDescription: 'Reminders for watering, fertilizing, and other plant care tasks',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    if (!_initialized) return;
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    if (!_initialized) return;
    await _notifications.cancelAll();
  }

  static int generateCareNotificationId(String plantId, String careTypeName) {
    return '${plantId}_$careTypeName'.hashCode.abs();
  }
}
