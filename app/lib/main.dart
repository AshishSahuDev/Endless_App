import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/isar_service.dart';
import 'core/services/app_logger.dart';
import 'core/services/notification_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/service_providers.dart';
import 'app.dart';

Future<void> main() async {
  await runZonedGuarded(_bootstrap, (error, stack) {
    AppLogger.I.error('zone', 'uncaught zone error', error: error, stack: stack);
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.I.init();
  AppLogger.I.info('app', 'boot start');

  FlutterError.onError = (details) {
    AppLogger.I.error(
      'flutter',
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stack: details.stack,
      data: {'library': details.library, 'context': details.context?.toString()},
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.I.error('platform', 'PlatformDispatcher error',
        error: error, stack: stack);
    return true;
  };

  final isarService = IsarService();
  await _guard('isar.init', () => isarService.init());

  final notificationService = NotificationService();
  await _guard('notifications.init', () => notificationService.init());

  final alarmService = AlarmService();
  await _guard('alarm.init', () => alarmService.init());

  AppLogger.I.info('app', 'boot complete');

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

Future<void> _guard(String tag, Future<void> Function() fn) async {
  try {
    await fn();
    AppLogger.I.info(tag, 'ok');
  } catch (e, s) {
    AppLogger.I.error(tag, 'init failed', error: e, stack: s);
  }
}
