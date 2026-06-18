import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static const _channelId = 'endless_reminders';
  static const _channelName = 'Reminders';
  static const _channelDesc = 'Endless app reminders and alerts';

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 8.0+ requires a notification channel — must be registered on init
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String? body,
    required DateTime scheduledAt,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleRecurring({
    required int id,
    required String title,
    required String? body,
    required DateTime firstAt,
    required Duration interval,
  }) async {
    // Cancel any existing notification with this id before rescheduling
    await cancel(id);
    await scheduleReminder(id: id, title: title, body: body, scheduledAt: firstAt);
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled by the app shell when foregrounded
  }
}
