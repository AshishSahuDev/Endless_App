import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'alarm_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Override notificationServiceProvider in main.dart');
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  throw UnimplementedError('Override alarmServiceProvider in main.dart');
});
