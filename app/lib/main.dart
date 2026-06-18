import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/isar_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/service_providers.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isarService = IsarService();
  await isarService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final alarmService = AlarmService();
  await alarmService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
        notificationServiceProvider.overrideWithValue(notificationService),
        alarmServiceProvider.overrideWithValue(alarmService),
      ],
      child: const EndlessApp(),
    ),
  );
}
