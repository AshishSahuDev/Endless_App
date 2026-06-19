import '../repositories/reminder_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/app_logger.dart';

class SnoozeReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const SnoozeReminderUseCase(this._repository, this._notifications);

  Future<void> call(int id, {Duration duration = const Duration(minutes: 10)}) async {
    await _repository.snooze(id, duration);
    final reminder = await _repository.getReminderById(id);
    if (reminder == null) {
      AppLogger.I.warn('reminder', 'snooze: reminder missing after snooze write',
          data: {'id': id});
      return;
    }
    AppLogger.I.action('reminder', 'snooze',
        data: {'id': id, 'minutes': duration.inMinutes});
    try {
      await _notifications.scheduleReminder(
        id: id,
        title: reminder.title,
        body: reminder.note,
        scheduledAt: reminder.reminderAt,
      );
    } catch (e, s) {
      AppLogger.I.error('reminder', 'snooze scheduleReminder failed',
          error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }
}
