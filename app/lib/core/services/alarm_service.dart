import 'package:alarm/alarm.dart';
import '../../features/alarms/domain/entities/alarm_entity.dart';

class AlarmService {
  Future<void> init() async {
    await Alarm.init(showDebugLogs: false);
  }

  Future<void> scheduleAlarm(AlarmEntity alarm) async {
    final now = DateTime.now();
    var ringAt = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);

    // If time already passed today, schedule for tomorrow
    if (ringAt.isBefore(now)) {
      ringAt = ringAt.add(const Duration(days: 1));
    }

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: alarm.id,
        dateTime: ringAt,
        assetAudioPath: alarm.soundAsset,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
          body: 'Tap to dismiss',
          stopButton: 'Stop',
          icon: 'mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> stopAlarm(int id) => Alarm.stop(id);

  Future<void> stopAll() => Alarm.stopAll();

  Future<bool> isRinging(int id) => Alarm.isRinging(id);
}
