import '../repositories/reminder_repository.dart';
import '../../../../core/services/notification_service.dart';

class SnoozeReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const SnoozeReminderUseCase(this._repository, this._notifications);

  Future<void> call(int id, {Duration duration = const Duration(minutes: 10)}) async {
    await _repository.snooze(id, duration);
    final reminder = await _repository.getReminderById(id);
    if (reminder == null) return;
    await _notifications.scheduleReminder(
      id: id,
      title: reminder.title,
      body: reminder.note,
      scheduledAt: reminder.reminderAt,
    );
  }
}
