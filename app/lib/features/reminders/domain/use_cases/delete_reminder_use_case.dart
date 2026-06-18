import '../repositories/reminder_repository.dart';
import '../../../../core/services/notification_service.dart';

class DeleteReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const DeleteReminderUseCase(this._repository, this._notifications);

  Future<void> call(int id) async {
    await _notifications.cancel(id);
    await _repository.deleteReminder(id);
  }
}
