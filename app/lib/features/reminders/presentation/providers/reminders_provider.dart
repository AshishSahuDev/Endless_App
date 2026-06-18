import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/reminder_local_datasource.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/use_cases/create_reminder_use_case.dart';
import '../../domain/use_cases/delete_reminder_use_case.dart';
import '../../domain/use_cases/snooze_reminder_use_case.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ReminderRepositoryImpl(ReminderLocalDatasource(isar));
});

final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  late ReminderRepository _repository;
  late NotificationService _notifications;

  @override
  Future<List<Reminder>> build() async {
    _repository = ref.watch(reminderRepositoryProvider);
    _notifications = ref.watch(notificationServiceProvider);
    return _repository.getAllReminders();
  }

  Future<void> create(Reminder reminder) async {
    await CreateReminderUseCase(_repository, _notifications)(reminder);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DeleteReminderUseCase(_repository, _notifications)(id);
    state = AsyncData(state.valueOrNull?.where((r) => r.id != id).toList() ?? []);
  }

  Future<void> snooze(int id) async {
    await SnoozeReminderUseCase(_repository, _notifications)(id);
    ref.invalidateSelf();
  }

  Future<void> edit(Reminder reminder) async {
    await _notifications.cancel(reminder.id);
    await _repository.updateReminder(reminder);
    await _notifications.scheduleReminder(
      id: reminder.id,
      title: reminder.title,
      body: reminder.note,
      scheduledAt: reminder.reminderAt,
    );
    ref.invalidateSelf();
  }
}
