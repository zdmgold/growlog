import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
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

    // A failure here must never stop the app from starting. If it fails,
    // _initialized stays false and the next reminder tries again.
    try {
      await _notifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.initialize failed: $e');
      return;
    }

    // Android 13+ needs an explicit runtime permission for notifications.
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('NotificationService permission request failed: $e');
    }
  }

  /// Schedules one care reminder. Never throws: returns false (and logs) if it could not be scheduled.
  static Future<bool> scheduleCareReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return false;

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'growlog_care',
            'Plant Care Reminders',
            channelDescription:
                'Reminders for watering, fertilizing, and other plant care tasks',
            importance: Importance.high,
            priority: Priority.high,
            channelShowBadge: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // Inexact needs no special Android permission. Exact alarms are not
        // granted by default on Android 14 and are restricted on Google Play
        // to alarm and calendar apps.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService.scheduleCareReminder failed: $e');
      return false;
    }
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
