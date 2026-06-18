import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/notification_service.dart';

class CreateReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const CreateReminderUseCase(this._repository, this._notifications);

  Future<int> call(Reminder reminder) async {
    if (reminder.title.trim().isEmpty) {
      throw const ValidationException('Reminder title cannot be empty');
    }
    if (reminder.reminderAt.isBefore(DateTime.now())) {
      throw const ValidationException('Reminder time must be in the future');
    }
    final id = await _repository.createReminder(reminder);
    await _notifications.scheduleReminder(
      id: id,
      title: reminder.title,
      body: reminder.note,
      scheduledAt: reminder.reminderAt,
    );
    return id;
  }
}
